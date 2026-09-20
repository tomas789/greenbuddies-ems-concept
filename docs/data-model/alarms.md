# Alarms: PLC to operator

**Modbus → validated condition → CODESYS Alarm Manager → OPC UA Alarms & Conditions → gateway database → EMS.** One catalog supplies wording; the PLC supplies state. Acknowledgement never resets a device or its trigger.

## 1. Define the condition in CODESYS

Use one evaluator per condition, after Modbus normalization. Apply hysteresis and raise/clear delays in the PLC. Bad or stale input holds the last condition and raises a separate input-quality alarm. Do not substitute zero for failed measurements. Critical protection remains in the device/PLC safety logic.

```iecst
(* Create a FUNCTION_BLOCK POU. Declarations above, implementation below the divider.
   Requires the CODESYS Standard library (TON). Example settings are not safety limits.
   One instance per condition. Call every scan from ONE acquisition/alarm task.
   Acknowledgement belongs to Alarm Manager, never to this block. *)
FUNCTION_BLOCK FB_EmsHighAlarm
VAR_INPUT
    lrValue       : LREAL;
    xValid        : BOOL;        (* Good, fresh sample AND valid mapping *)
    lrHigh        : LREAL;
    lrReset       : LREAL;       (* Must be below lrHigh: hysteresis *)
    tRaiseDelay   : TIME := T#2s;
    tClearDelay   : TIME := T#5s;
END_VAR
VAR_OUTPUT
    xActive       : BOOL;        (* Digital alarm expression; never writable by HMI *)
    xInputFault   : BOOL;        (* Separate communication/measurement alarm *)
    xConfigFault  : BOOL;
END_VAR
VAR
    fbRaise       : TON;
    fbClear       : TON;
END_VAR
(* ---- Implementation ---- *)
xConfigFault := (lrReset >= lrHigh);
xInputFault := NOT xValid;
IF xInputFault OR xConfigFault THEN
    fbRaise(IN := FALSE, PT := tRaiseDelay);
    fbClear(IN := FALSE, PT := tClearDelay);
    (* Hold last known condition; unavailable data must not clear a fault. *)
ELSE
    fbRaise(IN := (NOT xActive) AND (lrValue >= lrHigh), PT := tRaiseDelay);
    fbClear(IN := xActive AND (lrValue <= lrReset), PT := tClearDelay);
    IF fbRaise.Q THEN
        xActive := TRUE;
    ELSIF fbClear.Q THEN
        xActive := FALSE;
    END_IF;
END_IF;
END_FUNCTION_BLOCK

```

```iecst
(* Reference only: wire these inputs to the completed Modbus acquisition result.
   xTemperatureValid must include freshness, device health, range and finite-value checks.
   Schedule this program cyclically. Choose limits/delays during commissioning. *)
PROGRAM PRG_EmsAlarms
VAR
    lrTemperatureC    : LREAL;
    xTemperatureValid: BOOL := FALSE;
    fbTemperature    : FB_EmsHighAlarm;
END_VAR
(* ---- Implementation ---- *)
fbTemperature(
    lrValue := lrTemperatureC,
    xValid := xTemperatureValid,
    lrHigh := 45.0,
    lrReset := 42.0,
    tRaiseDelay := T#2s,
    tClearDelay := T#5s
);
(* Alarm Manager / digital expressions:
   bess.temperature.high    := PRG_EmsAlarms.fbTemperature.xActive
   bess.temperature.invalid := PRG_EmsAlarms.fbTemperature.xInputFault
   bess.alarm.config        := PRG_EmsAlarms.fbTemperature.xConfigFault
   Define all three in an ACK_REP alarm class. Do not reset digital alarms on ACK.
   Alarm Manager owns occurrence state, timestamps, archive and acknowledgment.
   These expressions do NOT need individual OPC UA boolean tag subscriptions. *)
END_PROGRAM

```

Create these as separate POUs; paste declarations and implementation into their respective editors. These reference files have not been compiled in a CODESYS IDE here. Configure and test them on your target. At startup, state is unknown until the first valid input; the input-quality alarm covers that interval. Do not use RETAIN on individual evaluator variables as a substitute for Alarm Manager persistence.

## 2. Configure Alarm Manager and publishing

1. Add Alarm Configuration, a class named `EMS_Warning`, and a group for the battery. Choose `ACK_REP` and **Acknowledge instead of confirm**. Leave **Reset digital alarms automatically** off. This prevents acknowledgement from changing the measured condition.
2. Add the three Digital alarms listed in `PRG_EmsAlarms`. Use stable codes and meaningful messages. Set class priorities and verify the exported OPC UA severity during commissioning. Disable periodic re-alarm unless your operating procedure requires it.
3. Enable archiving for the class/group and configure Alarm Storage. Set storage limits and backups for the actual PLC. Storage is separate from the outstanding register; a factory/origin reset deletes the CODESYS archive.
4. In Communication Manager → OPC UA Server → IEC Symbol Publishing → Alarm Group Editor, publish the group. This editor requires Communication **4.6+** and Development System **3.5.21+**, and exports only `ACK_REP` groups. Verify target runtime support, libraries and licensing separately.
5. Export the alarm information as JSON/CSV, browse the running server, and copy its actual notifier and ConditionIds into configuration. Example NodeIds below are placeholders. Use the namespace URI to survive namespace-index changes.

[CODESYS publishing](https://content.helpme-codesys.com/en/CODESYS%20Communication/_comm_obj_iec_symbol_publishing.html) · [Alarm classes](https://content.helpme-codesys.com/en/CODESYS%20Visualization/_cds_obj_alarm_class.html) · [Alarm Storage](https://content.helpme-codesys.com/en/CODESYS%20Visualization/_cds_obj_alarm_storage.html)

## 3. Configure the EMS once

Add an `alerts` feature for the site. Add entries to three normalized registries in `ems.config.json`; do not duplicate an asset or add a Boolean tag per alarm.

```json
{
  "features": { "battery-alarms": { "type": "alerts", "site": "SITE-A" } },
  "alarmTypes": {
    "bess.temperature.high": {
      "title": { "en": "Battery temperature high", "cs": "Vysoká teplota baterie" },
      "description": { "en": "Inspect cooling and the battery temperature readings.", "cs": "Zkontrolujte chlazení a naměřené teploty baterie." },
      "severity": "warning"
    }
  },
  "alarmSources": {
    "plc-a": { "site": "SITE-A", "notifier": "ns=2;s=ExportedAlarmNotifier", "namespaceUri": "urn:your-plc:application" }
  },
  "alarmBindings": {
    "battery-temperature": { "source": "plc-a", "asset": "BESS-01", "type": "bess.temperature.high", "condition": "ns=2;s=ExportedConditionId" }
  }
}
```

This is a configuration fragment: merge it into your existing registries and bind the input-quality/configuration alarms too. `asset` references equipment in the source's site. All sources currently use the gateway's single configured OPC UA endpoint. Use non-overlapping notifiers: subscribing to a parent and its child duplicates conditions. Startup validation checks references, duplicate bindings and feature ownership. Unknown ConditionIds remain visible with their raw code and source message. Live severity comes from the PLC; catalog severity seeds the demo only.

## 4. Event and method contract

| Field / operation | Access | Meaning |
| --- | --- | --- |
| EventNotifier subscription | r | One event stream per configured source; independent of scalar telemetry |
| ConditionId + BranchId | r | Source-owned condition/retained branch identity |
| EventId | r | Opaque latest notification token used by Acknowledge; not a permanent occurrence ID |
| ActiveState.Id | r | Underlying condition is active |
| AckedState.Id | r | Operator awareness, independent of whether timestamps or actor are known |
| Retain | r | Source says the condition belongs in the outstanding register |
| Severity | r | OPC UA 1–299 notice, 300–699 warning, 700–1000 critical |
| Quality | r | Condition quality; invalid quality disables acknowledgement |
| Time, ActiveState.TransitionTime, AckedState.TransitionTime | r | UTC source times when available; unknown time remains null |
| Message, ClientUserId | r | Source diagnostic and source-reported account; never executed or interpreted as configuration |
| ConditionRefresh | method | Restores retained conditions after connection/recovery; does not replay history |
| Acknowledge(EventId, Comment) | method | Request awareness for the exact current source event; never write a trigger tag |

Only two-state, acknowledgeable alarms are supported. Confirm/shelve/suppress/disable operations are not exposed. Malformed notifications make coverage incomplete. OPC UA Time alone cannot prove UTC synchronization: commission the PLC clock and quality behavior. The UI labels receipt time separately from source time.

## 5. State and history

The gateway gives each observed occurrence a UUID, scoped by source generation, condition and branch. A new activation or server generation starts a new occurrence. Native retained branches remain separate records; branch transfer may be represented as a recovered record when the source exposes no stable occurrence ID. Never infer identity from text or a recycled slot.

Active/unacknowledged, active/acknowledged and cleared/unacknowledged states remain distinct. Closed conditions leave the register but stay in history. Reconnecting retains last known rows with acknowledgement disabled until a complete refresh. Missing conditions after a completed refresh are recorded as no longer retained, with unknown intervening transitions; no clear time is invented.

SQLite stores current records, received transitions and acknowledgement requests/results in `EMS_DATA_DIR/alarms.sqlite` (default `data/`). It survives gateway restart. Back up the directory with SQLite-aware tooling. History is currently unbounded; plan storage/backup retention for the installation. API history is paged, 200 rows maximum per request; CSV exports the loaded rows.

**Outage history replay is not implemented.** The UI explicitly warns that events may be missing. CODESYS Alarm Storage remains the source archive; a future target-specific reader must replay it with durable source IDs and a cursor. Refresh alone cannot recover a fault that raised and cleared while disconnected. If the runtime has no native A&C support, do not enable this adapter or fall back silently to sampled Booleans; add and qualify a coherent snapshot plus append-only journal adapter behind the same gateway service.

## 6. Authorize acknowledgement

The production gateway is read-only by default. To enable acknowledgement, configure an authenticated reverse proxy, `EMS_AUTH_PROXY_SECRET` (at least 32 characters), and `EMS_ALARM_OPERATORS_FILE`, pointing to a private JSON file:

```json
{ "operator@example.com": { "sites": ["SITE-A"] } }
```

The proxy must remove incoming `X-EMS-User` and `X-EMS-Proxy-Secret` headers and set them itself from verified identity and its secret. Keep the gateway private behind that proxy. Do not put secrets or account policy in the public EMS JSON. Tailscale transport access alone does not supply this operator identity.

The browser posts `{id, occurrence, revision, comment}` to `/api/alarms/acknowledge`. The server checks site permission, connection, quality and exact revision, persists the request, then calls the native method. Reusing a request ID never repeats the call. An uncertain outcome blocks a new attempt for that occurrence until source confirmation or a complete refresh. Use **Synchronize alarms** in the register to request a fresh PLC snapshot. The UI changes acknowledgement only when source state arrives. Server audit records the authenticated operator; `ClientUserId` may identify a shared OPC UA account instead.

The local OPC UA demo explicitly grants `demo-operator` for simulated equipment. Its first alarm clears after 90 seconds and recurs after 180 seconds. GitHub Pages uses an in-browser demonstration; those records reset on reload. Neither demo is an authentication example for a real plant.

## Commissioning acceptance

Verify raise/clear/ack in either order, recurrence before acknowledgement, retained branches, HMI acknowledgement, bad quality, unknown codes, gateway restart, PLC restart, connection loss, subscription overflow and archive limits. Test two concurrent operators and rejected/stale requests. Verify active acknowledged faults remain retained and ConditionRefresh includes every retained branch. The automated demo verifies the protocol path; it does not qualify a CODESYS target.

[Download evaluator](asset:codesys/FB_EmsHighAlarm.st) · [Download example](asset:codesys/PRG_EmsAlarms.st) · [OPC UA refresh](https://reference.opcfoundation.org/specs/OPC-10000-9/4) · [Acknowledgement](https://reference.opcfoundation.org/specs/OPC-10000-9/5.7.3)
