# Model & conventions

Keep configuration and observations separate. A live frame contains point IDs and samples, not repeated site names, register addresses or unit definitions.

| Object | Defined once | Example |
| --- | --- | --- |
| Asset | Identity, kind, parent, location, ratings | BESS-01 belongs to SITE-A |
| Field | Meaning, type, unit, range, access | ac.activePower, W, number, r |
| Point | Asset + field + freshness timeout | bess.power |
| Source | Modbus connection | battery-modbus |
| Mapping | Source + address + conversion | int32 at address 100, scale −1000 |
| Sample | Value + quality + observedAt + sequence | −1250000, good, UTC ms, 12 |

## Units and signs

Power **W**, reactive power **var**, energy **Wh**, pressure **Pa**. The UI chooses prefixes such as MW. Positive active power leaves an asset; at the PCC it means export, at a battery discharge. Load demand is a separate positive consumption field. Reactive power uses the same reference arrow, with positive reactive export; do not infer its sign from a vendor's inductive/capacitive label.

Exact lifetime UInt64 counters use decimal strings in JSON. Do not convert them to JavaScript Number. Reset and rollover events belong in the event history; they are not negative energy.

## Quality travels with the value

| Code | Quality | Meaning |
| --- | --- | --- |
| 0 | good | Valid observation with trustworthy UTC |
| 1 | uncertain | A value exists, but its accuracy or time is uncertain |
| 2 | bad | Failed read, invalid sentinel, range error or unmapped status |
| 3 | stale | No fresh observation before the point timeout |
| 4 | unsupported | Device does not implement the point |
| 5 | disabled | Acquisition deliberately disabled |
| 6 | initializing | No observation yet |

Zero and false are valid. Unsupported/initializing export null value and time. On failure, retain the last observation time; a successful OPC read of old PLC memory must not make it fresh.

## IDs, time and hierarchy

Use stable globally unique asset IDs. Repeated strings, cells, racks and connectors are child assets. A configured point declares support; absent points do not create zero-valued widgets. UTC is Unix milliseconds; local time is presentation only. Daily energy uses the site's IANA timezone.

A frame identifies its producer, session, sequence and configuration revision. Start each connection epoch with a full snapshot. Deltas contain changed points, including quality-only changes. JSON `extensions` can define `x.company.field` with explicit type, unit and meaning; they never redefine a core field.

[Model schema](asset:model.schema.json) · [Frame schema](asset:frame.schema.json)

## Evolve without breaking installations

Add optional points or namespaced extensions without changing existing field meanings. Never reuse an ID for another device, or change an existing field’s unit, sign or type. Breaking changes require a new major contract and explicit migration. The supplied validators accept version 1.0 exactly and reject unknown versions.
