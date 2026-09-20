# Canonical EMS model · design contract

Version 1.0. The core is manufacturer-neutral; Modbus register maps are replaceable adapters. This is an application contract, not a claim of IEC 61850, SunSpec or OPC UA companion-specification conformance.

## One direction for telemetry

Modbus transaction → vendor adapter → canonical typed point → OPC UA → exporter → UI / JSON / CSV / historian.

The adapter owns register address, data type, word/byte order, invalid sentinels, scaling and vendor status translation. Everything after it uses the same field dictionary. Metadata is configured once; samples reference point IDs. A missing capability is not a zero measurement.

## Records and ownership

| Record | Owner | Contents |
| --- | --- | --- |
| Asset | Installation configuration | Stable ID, kind, parent, label, location, ratings and optional manufacturer information |
| Field | Shared catalog | Meaning, engineering unit, type, read/write contract, valid range and enumeration |
| Point | Installation configuration | Asset reference + field reference; presence declares support |
| Mapping | Device adapter | Source reference, zero-based address, encoding, ordering, scale/offset and freshness |
| Sample | PLC acquisition task | Value, quality, UTC observation time and per-point sequence; never refreshed just because the PLC scanned |
| Frame | Exporter | Source/session/sequence, configuration revision, export time and changed samples; snapshot replaces this source's point set |
| Command | Authorized command service | Revision, expiry, authority, complete profile/settings transaction and acceptance readback |
| Event / alarm | Controller or application service | Stable event ID, asset, raised/cleared times, severity, acknowledgement and source code |

## Coverage

Common identity, communications and operating state; three-phase AC, DC, lifetime/daily energy; grid/PCC and DSO; PV arrays/inverters; BESS systems/PCS/racks/cells; wind; hydro; meters, transformers and breakers; weather and environmental sensors; loads and EV charging; local controller, remote authority, limits, schedules and profiles; camera state; alarms and audit events. Per-cell/per-string data uses child assets, not hard-coded maximum device counts. Media, users/permissions, tariff curves and forecasts are structured application records, not pretend Modbus registers.

## Conventions

- Power is W, reactive power var, apparent power VA, energy Wh; display prefixes belong to the UI. Active power is positive out of an asset; at the PCC it is positive export. Batteries are positive discharge. Load demand and positive charge/discharge limits have explicitly separate fields.
- UTC timestamps are Unix milliseconds (safe JSON integers); unsupported/never-observed points have null time/value. The PLC uses ULINT. A source without trustworthy UTC is uncertain, never silently current.
- Every point carries quality. Transport Good cannot override device Bad/Stale. Keep last observation time on failures. Zero and false are valid readings. Exact 64-bit counters use decimal strings in JSON.
- Samples and accepted state are readable. Command mailboxes are write-only; desired settings may be read/write but must be committed as one validated transaction. Access metadata grants no permission.
- One active writer owns each point. A new session ID after restart separates sequence epochs. Profiles/settings are not atomic merely because several scalar writes succeeded.

## Integration boundary

CODESYS publishes canonical structures through IEC Symbol Publishing. The exporter must read quality and observation time together with value; subscribing to Value alone loses the contract. A reference Modbus decoder, document/frame validators, JSON/CSV exporter, UI-frame adapter, generated field dictionary and CODESYS declarations are included. The existing live gateway remains read-only; production driver scheduling, authenticated commands and target-specific symbol bindings require the installation's CODESYS project.

## Documentation delivery

One Documentation entry in every sidebar presentation. Short chapters: Start, Model, Field reference, Modbus mapping, CODESYS, Export and integration, Commands and records. Field tables and PLC structures are generated from the same catalog. Downloadable JSON Schema, configuration, sample frame, ST files and source-linked references accompany the chapters.
