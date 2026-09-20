# Field reference

Generated from the shared catalog. Units describe engineering values after Modbus normalization. Only configured points are required; optional fields are omitted. `r` is telemetry/readback. `rw` is a desired setting submitted in a complete command, not permission to write a live register. Whole command mailboxes use `w` and have separate acceptance records.

## Device & communication

Shared by any physical or logical asset. Communication and operating state remain separate.

| Field | Type | Unit | Access | Meaning / bounds |
| --- | --- | --- | --- | --- |
| `device.online` | boolean | — | r | Last device transaction succeeded; does not imply every point is healthy. |
| `device.state` | string | — | r | Normalized operating state; unknown codes map to unknown, never running. Values: unknown, stopped, starting, running, standby, maintenance, fault, offline. |
| `device.available` | boolean | — | r | Device reports available for operation. |
| `device.remoteMode` | boolean | — | r | Device accepts remote control at its own interface. |
| `device.faultActive` | boolean | — | r | At least one device fault is active. |
| `device.warningActive` | boolean | — | r | At least one device warning is active. |
| `device.vendorCode` | string | — | r | Unmodified diagnostic code for service; never drives portable UI behavior. |
| `device.latency` | number | ms | r | Most recent successful transaction duration. Min 0. |
| `device.uptime` | counter | s | r | Device uptime. A reset is not negative consumption. |
| `device.communicationErrors` | counter | count | r | Cumulative failed transactions since source restart. |

## AC electrical

Positive P means power leaving the asset; at the grid meter this means export. Positive Q is reactive export at the same reference arrow.

| Field | Type | Unit | Access | Meaning / bounds |
| --- | --- | --- | --- | --- |
| `ac.activePower` | number | W | r | Signed active power at the declared measurement boundary. |
| `ac.reactivePower` | number | var | r | Signed reactive power at the same boundary as activePower. |
| `ac.apparentPower` | number | VA | r | Non-negative apparent power. Min 0. |
| `ac.frequency` | number | Hz | r | Measured AC frequency. Min 0. |
| `ac.powerFactor` | number | 1 | r | P / apparent power, signed by active power; null if undefined. Min -1. Max 1. |
| `ac.voltageL1N` | number | V | r | L1 to neutral RMS voltage. Min 0. |
| `ac.voltageL2N` | number | V | r | L2 to neutral RMS voltage. Min 0. |
| `ac.voltageL3N` | number | V | r | L3 to neutral RMS voltage. Min 0. |
| `ac.voltageL1L2` | number | V | r | L1 to L2 RMS voltage. Min 0. |
| `ac.voltageL2L3` | number | V | r | L2 to L3 RMS voltage. Min 0. |
| `ac.voltageL3L1` | number | V | r | L3 to L1 RMS voltage. Min 0. |
| `ac.currentL1` | number | A | r | L1 RMS current magnitude. Min 0. |
| `ac.currentL2` | number | A | r | L2 RMS current magnitude. Min 0. |
| `ac.currentL3` | number | A | r | L3 RMS current magnitude. Min 0. |
| `ac.activePowerL1` | number | W | r | Signed active power, L1. |
| `ac.activePowerL2` | number | W | r | Signed active power, L2. |
| `ac.activePowerL3` | number | W | r | Signed active power, L3. |
| `ac.voltageThd` | number | % | r | Reported aggregate voltage total harmonic distortion. Min 0. |

## DC electrical

Apply to a DC bus, PV string, battery rack or cell; represent repeated channels as child assets.

| Field | Type | Unit | Access | Meaning / bounds |
| --- | --- | --- | --- | --- |
| `dc.voltage` | number | V | r | DC terminal voltage. Min 0. |
| `dc.current` | number | A | r | DC current; positive out of the asset. |
| `dc.power` | number | W | r | DC power; positive out of the asset. |
| `dc.insulationResistance` | number | ohm | r | Insulation resistance to ground. Min 0. |

## Energy & counters

Separate monotonic direction counters. Exact UInt64 Wh totals travel as decimal strings.

| Field | Type | Unit | Access | Meaning / bounds |
| --- | --- | --- | --- | --- |
| `energy.exported` | counter | Wh | r | Cumulative active energy leaving the boundary. |
| `energy.imported` | counter | Wh | r | Cumulative active energy entering the boundary. |
| `energy.generatedToday` | number | Wh | r | Generation since site-local midnight; date/timezone are metadata. Min 0. |
| `energy.exportedToday` | number | Wh | r | Export since site-local midnight. Min 0. |
| `energy.importedToday` | number | Wh | r | Import since site-local midnight. Min 0. |
| `energy.runtime` | counter | s | r | Cumulative operating time. |

## Solar PV

Use ac/dc/energy for the shared electrical values. An inverter and each array/string are independent assets.

| Field | Type | Unit | Access | Meaning / bounds |
| --- | --- | --- | --- | --- |
| `pv.moduleTemperature` | number | degC | r | PV module temperature. |
| `pv.inverterTemperature` | number | degC | r | Inverter internal temperature. |
| `pv.irradiance` | number | W/m2 | r | Plane-of-array irradiance. Min 0. |
| `pv.availablePower` | number | W | r | Device-estimated available active power; not inferred from nameplate. Min 0. |
| `pv.curtailedPower` | number | W | r | Reported curtailed active power. Min 0. |

## Battery & PCS

The same fields apply at system, container, rack or cell level when actually measured. Parent SoC is supplied by the controller, not averaged in the UI.

| Field | Type | Unit | Access | Meaning / bounds |
| --- | --- | --- | --- | --- |
| `battery.soc` | number | % | r | State of charge. Min 0. Max 100. |
| `battery.soh` | number | % | r | State of health. Min 0. Max 100. |
| `battery.storedEnergy` | number | Wh | r | Estimated stored usable energy. Min 0. |
| `battery.chargeAvailable` | number | W | r | Maximum currently available charge magnitude. Min 0. |
| `battery.dischargeAvailable` | number | W | r | Maximum currently available discharge magnitude. Min 0. |
| `battery.temperature` | number | degC | r | Reported representative battery temperature. |
| `battery.minTemperature` | number | degC | r | Lowest measured temperature. |
| `battery.maxTemperature` | number | degC | r | Highest measured temperature. |
| `battery.minCellVoltage` | number | V | r | Lowest measured cell voltage. Min 0. |
| `battery.maxCellVoltage` | number | V | r | Highest measured cell voltage. Min 0. |
| `battery.cycles` | counter | count | r | Completed equivalent cycles; fractional cycles require a separate extension field. |
| `battery.contactorClosed` | boolean | — | r | Battery contactor closed readback. |
| `battery.balancing` | boolean | — | r | Cell balancing active. |

## Wind

Turbine operating values; electrical production uses ac and energy.

| Field | Type | Unit | Access | Meaning / bounds |
| --- | --- | --- | --- | --- |
| `wind.speed` | number | m/s | r | Wind speed at the instrument. Min 0. |
| `wind.direction` | number | deg | r | Wind direction, clockwise from true north. Min 0. Max 360. |
| `wind.rotorSpeed` | number | rpm | r | Rotor speed. Min 0. |
| `wind.nacelleDirection` | number | deg | r | Nacelle bearing from true north. Min 0. Max 360. |
| `wind.pitch` | number | deg | r | Reported representative blade pitch. |
| `wind.gearboxTemperature` | number | degC | r | Gearbox temperature. |
| `wind.availablePower` | number | W | r | Reported available generation. Min 0. |

## Hydro

Hydraulic operating values. Units do not depend on turbine manufacturer.

| Field | Type | Unit | Access | Meaning / bounds |
| --- | --- | --- | --- | --- |
| `hydro.flow` | number | m3/s | r | Volumetric flow through the unit. Min 0. |
| `hydro.head` | number | m | r | Net hydraulic head. Min 0. |
| `hydro.upstreamLevel` | number | m | r | Upstream level relative to the configured datum. |
| `hydro.downstreamLevel` | number | m | r | Downstream level relative to the same datum. |
| `hydro.gatePosition` | number | % | r | Gate opening. Min 0. Max 100. |
| `hydro.turbineSpeed` | number | rpm | r | Hydro turbine speed. Min 0. |
| `hydro.waterTemperature` | number | degC | r | Water temperature. |

## Grid, DSO & switchgear

The PCC export allowance is a constraint, not a controller setpoint. Physical switch states use confirmed feedback.

| Field | Type | Unit | Access | Meaning / bounds |
| --- | --- | --- | --- | --- |
| `grid.dsoAllowance` | number | % | r | Discrete DSO export allowance. Values: 0, 30, 60, 100. Min 0. Max 100. |
| `grid.exportLimit` | number | W | r | Effective non-negative export ceiling. Min 0. |
| `grid.importLimit` | number | W | r | Effective non-negative import ceiling. Min 0. |
| `grid.connected` | boolean | — | r | PCC connected to the external grid. |
| `grid.islanded` | boolean | — | r | Site operating as an island. |
| `grid.breakerClosed` | boolean | — | r | Breaker closed auxiliary-contact readback. |
| `grid.tripActive` | boolean | — | r | Protection trip active. |
| `grid.transformerTemperature` | number | degC | r | Transformer winding or oil sensor, identified in point metadata. |
| `grid.tapPosition` | number | step | r | Transformer tap position; signed integral step. |

## Weather & environment

Use separate instrument assets where readings differ in position or sampling quality.

| Field | Type | Unit | Access | Meaning / bounds |
| --- | --- | --- | --- | --- |
| `meteo.airTemperature` | number | degC | r | Ambient air temperature. |
| `meteo.humidity` | number | % | r | Relative humidity. Min 0. Max 100. |
| `meteo.pressure` | number | Pa | r | Atmospheric pressure. Min 0. |
| `meteo.irradiance` | number | W/m2 | r | Global horizontal irradiance. Min 0. |
| `meteo.windSpeed` | number | m/s | r | Wind speed. Min 0. |
| `meteo.windDirection` | number | deg | r | Direction clockwise from true north. Min 0. Max 360. |
| `meteo.rainfall` | number | mm | r | Precipitation in the configured measurement window. Min 0. |

## Loads & EV charging

Demand is positive consumption; use ac.activePower for the signed electrical boundary measurement.

| Field | Type | Unit | Access | Meaning / bounds |
| --- | --- | --- | --- | --- |
| `load.demand` | number | W | r | Non-negative active power consumed. Min 0. |
| `load.flexiblePower` | number | W | r | Reported shed-able load magnitude. Min 0. |
| `load.enabled` | boolean | — | r | Load enabled readback. |
| `load.vehicleConnected` | boolean | — | r | Vehicle present at this connector. |
| `load.charging` | boolean | — | r | Charging active readback. |
| `load.currentLimit` | number | A | r | Accepted EV connector current limit. Min 0. |
| `load.sessionEnergy` | number | Wh | r | Energy delivered in this charging session. Min 0. |

## Controller & authority

Authoritative received state, shared by dashboard, canvas and control pages.

| Field | Type | Unit | Access | Meaning / bounds |
| --- | --- | --- | --- | --- |
| `controller.mode` | string | — | r | Current controller mode. Values: unknown, stopped, standby, optimizing, limited, fault. |
| `controller.source` | string | — | r | Exactly one selected command authority. Values: local, aggregator. |
| `controller.remoteConnected` | boolean | — | r | Aggregator transport connected. |
| `controller.remoteAllowed` | boolean | — | rw | Remote permission readback; disabling selects local authority. |
| `controller.requestedPower` | number | W | r | Requested aggregate active power before controller constraints. |
| `controller.afterController` | number | W | r | Power after local optimization and device feasibility limits. |
| `controller.afterDso` | number | W | r | Power after DSO/export constraints. |
| `controller.deliveredPower` | number | W | r | Final dispatched power; distinct from measured power. |
| `controller.limitingReason` | string | — | r | Dominant normalized active constraint. Values: none, dso, soc, thermal, power, ramp, communication, interlock, other. |

## Controller settings

Read/write desired settings. Submit the entire settings record and inspect accepted revision before treating it as applied.

| Field | Type | Unit | Access | Meaning / bounds |
| --- | --- | --- | --- | --- |
| `settings.peakImportTarget` | number | W | rw | Peak-shaving import target. Min 0. |
| `settings.peakShavingShare` | number | % | rw | Usable battery allocation to peak shaving; remainder for load shifting. Min 0. Max 100. |
| `settings.socMin` | number | % | rw | Minimum operating SoC; strictly below socMax. Min 0. Max 100. |
| `settings.socMax` | number | % | rw | Maximum operating SoC; strictly above socMin. Min 0. Max 100. |
| `settings.chargeLimit` | number | W | rw | Requested maximum charge magnitude. Min 0. |
| `settings.dischargeLimit` | number | W | rw | Requested maximum discharge magnitude. Min 0. |
| `settings.rampLimit` | number | W/s | rw | Maximum change of active power magnitude per second. Min 0. |

## Camera

Media URLs and credentials belong to configuration/media services. Video is not an OPC scalar.

| Field | Type | Unit | Access | Meaning / bounds |
| --- | --- | --- | --- | --- |
| `camera.online` | boolean | — | r | Camera reachable. |
| `camera.recording` | boolean | — | r | Recording active. |
| `camera.frameAge` | number | ms | r | Age of most recently received image. Min 0. |

