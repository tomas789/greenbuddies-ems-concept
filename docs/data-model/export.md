# Export & connect the EMS

The same validated frame can feed JSON, CSV or the existing UI stream. Exported readings stay in canonical engineering units. Exporting never sends a device command.

## Try the included example

From the source project's `prototype` directory:

```sh
npm run model:export -- public/docs/data-model/example.model.json public/docs/data-model/example.frame.json json
npm run model:export -- public/docs/data-model/example.model.json public/docs/data-model/example.frame.json csv
npm run model:export -- public/docs/data-model/example.model.json public/docs/data-model/example.frame.json ui public/docs/data-model/example.ui-bindings.json
```

Configuration validation checks IDs, hierarchy cycles, field types, mappings, enum translations and freshness. Frame validation rejects unknown points, missing snapshot points, invalid values, wrong revisions and stale readings labelled good. The CLI exits with an error and a logical path instead of silently dropping invalid data. JSON Schema covers structure; the accompanying validator also checks relationships.

## From a PLC sample

The Node adapter accepts Value plus its Meta from one coherent acquisition. Preserve UInt64 values as BigInt/decimal strings; never decode them through Number.

```js
import { sampleFromPlc, toUiFrame } from './lib/canonical/model.mjs';
const sample = sampleFromPlc(-1250000, {
  Quality: 0, ObservedAtMs: 1790000000000, Sequence: 12
}, { transportGood: true, receivedAt: 1790000001000, staleAfterMs: 5000 });
// Insert sample into a validated canonical frame, then map logical UI tag IDs:
const message = toUiFrame(model, frame, { 'battery.power': 'bess.power' });
```

The shipped gateway currently subscribes to scalar values. Add the coherent Value/Meta assembly at its data-source boundary before using canonical PLC structures live. Do not bind only `.Value` and assume the OPC transport status describes the field device. The reference exporter and CLI work now; automatic structured-node subscription is a separate installation integration.

## Existing UI conventions

| Canonical field | Existing UI tag | Scale |
| --- | --- | --- |
| ac.activePower, W | Equipment power, MW | 0.000001 |
| battery.soc, % | Battery SoC, % | 1 |
| meteo.pressure, Pa | Pressure, hPa | 0.01 |
| Battery ac.activePower, W | Legacy site-metering.battery, charging-positive MW | −0.000001 |

Set the existing tag `scale` once. Counter tags must be strings unless an explicit downstream conversion can preserve the required precision. Canonical quality remains available in JSON/CSV; the current UI adapter maps good/uncertain directly and all other unavailable states to bad, retaining observation time for staleness.

[Download sample CSV](asset:example.csv) · [Sample JSON](asset:example.frame.json) · [UI bindings](asset:example.ui-bindings.json)
