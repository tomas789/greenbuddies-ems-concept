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
