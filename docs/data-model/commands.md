# Commands & non-scalar records

Measured power, requested power and applied power are different records. A writable contract is not permission to control equipment.

## Control path

**Local profile OR aggregator profile → local controller → DSO constraint → device limits → dispatch → accepted/applied readback.**

Only one source is selected. Disabling remote permission selects local; enabling permission alone does not select the aggregator. If the selected source becomes invalid, the controller follows its configured fallback policy. No valid fallback means dispatch inhibited, not an invented zero command. DSO input is never overwritten by a UI preview.

## Command envelope

Every command has `id`, `revision`, target `asset`, `issuedAt`, `expiresAt`, authority and a typed payload. The service validates it, checks permission/interlocks, commits it coherently and publishes a result referencing that exact command ID and revision.

| Type | Access | Payload / rule |
| --- | --- | --- |
| profile | w request, r result | Whole validity window and non-overlapping intervals; target values are signed W |
| settings | rw desired, r accepted | Complete settings set; SoC minimum < maximum; peak-shaving share 0–100% |
| authority | w request, r state | remoteAllowed and selected local/aggregator; permission off forbids aggregator |
| acknowledge | w request, r result | Occurrence ID, expected revision and comment; acknowledgement never clears the underlying fault |

Result states: received → validated → accepted → applied, or rejected/expired with a reason. Transport success is not acceptance. Repeated command IDs must be idempotent; after restart, reconcile accepted revision before resending. These lifecycle rules belong in the production command service/controller. The implemented alarm acknowledgement endpoint and its authorization are described in [Alarms](#docs/alarms). Other equipment commands remain read-only.

Profiles cover their entire window without gaps. Each interval lists explicit targets; omitted devices do not inherit previous targets. The reference PLC type bounds one profile to 64 intervals × 32 targets. Reject oversize input before copying, or explicitly increase limits after checking PLC memory. The JSON contract permits up to 10,000 intervals. Adapt the current UI's MW profile format at the boundary; the canonical format uses W and UTC milliseconds.

## Other records

| Record | Minimal canonical contents | Owner |
| --- | --- | --- |
| Alarm | occurrence ID, asset, code, severity, active/cleared, acknowledged, retained, quality and nullable lifecycle times | Controller/alarm service |
| Audit event | eventId, asset, at, actorId, action, result, commandId if relevant | Application service |
| Forecast | asset, field ID, issuedAt, ordered UTC intervals and values; optional quantile | Forecast provider |
| Tariff | site, currency, price unit, validity intervals, buy/sell prices | Market service |
| Camera | asset, media reference, capturedAt, quality | Media service; credentials stay server-side |
| User/access policy | userId, role IDs, site/asset scope, allowed actions | Identity service; never a Modbus tag |

The [record schema](asset:record.schema.json) defines these versioned envelopes; `validateRecord` also checks references and time ordering. Every record contains modelVersion, id, asset, at, type and typed data. Access-policy scope is its asset (a site grants site scope); role/user IDs refer to the identity service. Defining a policy record does not enforce it. Alarm acknowledgement is an explicit Boolean; missing timestamps or an unknown actor do not undo it. `at` is gateway receipt time, and alarm `sourceTime` is nullable. `toCanonicalAlarm` in `lib/alarms.ts` converts a live record after mapping its equipment to your canonical asset ID. Other record validators do not implement media, identity or market backends. Site metadata and equipment hierarchy remain in normalized configuration.

[Command schema](asset:command.schema.json) · [CODESYS profile/result types](asset:codesys/ProfileTypes.st)
