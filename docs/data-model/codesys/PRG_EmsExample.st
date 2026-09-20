(* POU: PROGRAM PRG_EmsExample. Map the Inputs through your completed Modbus request. *)
PROGRAM PRG_EmsExample
VAR
    (* Replace these driver-bound inputs; none are invented automatic CODESYS diagnostics. *)
    aBatteryWords : ARRAY[0..2] OF WORD;
    xBatteryDone : BOOL; (* one pulse for a successful complete response *)
    xBatteryError : BOOL;
    xUtcSynchronized : BOOL;
    uliUtcMs : ULINT; (* Fill from SysTimeRtcHighResGet + clock synchronization health. *)
    uliMonotonicMs : ULINT;
    powerSample : FB_EmsSample;
    socSample : FB_EmsSample;
    decoded : ST_EmsDecoded;
    lrSoc : LREAL;
END_VAR
(* IMPLEMENTATION *)
uliMonotonicMs := LTIME_TO_ULINT(LTIME()) / ULINT#1000000;
(* Example vendor: signed kW, positive charge. Convert ONCE to W, positive discharge. *)
decoded := F_EmsDecode32(wFirst := aBatteryWords[0], wSecond := aBatteryWords[1],
    xLowWordFirst := FALSE, xLowByteFirst := FALSE, usiEncoding := 3,
    lrScale := -1000, lrOffset := 0, xHasSentinel := TRUE, dwSentinel := DWORD#16#80000000);
powerSample(xNewSample := xBatteryDone, xReadError := xBatteryError,
    xValueValid := decoded.Valid AND (ABS(decoded.Value) <= LREAL#2000000),
    xClockValid := xUtcSynchronized, uliUtcMs := uliUtcMs,
    uliMonotonicMs := uliMonotonicMs, udiStaleAfterMs := 5000);
IF powerSample.xAccept THEN GVL_Ems.Battery.ac.activePower.Value := decoded.Value; END_IF;
GVL_Ems.Battery.ac.activePower.Meta := powerSample.Meta;

lrSoc := WORD_TO_LREAL(aBatteryWords[2]) * LREAL#0.1;
socSample(xNewSample := xBatteryDone, xReadError := xBatteryError,
    xValueValid := (aBatteryWords[2] <> WORD#16#FFFF) AND (lrSoc >= 0) AND (lrSoc <= 100),
    xClockValid := xUtcSynchronized, uliUtcMs := uliUtcMs,
    uliMonotonicMs := uliMonotonicMs, udiStaleAfterMs := 5000);
IF socSample.xAccept THEN GVL_Ems.Battery.battery.soc.Value := lrSoc; END_IF;
GVL_Ems.Battery.battery.soc.Meta := socSample.Meta;
(* Call in one acquisition task. Do not expose a partially updated struct as an atomic snapshot. *)
END_PROGRAM
