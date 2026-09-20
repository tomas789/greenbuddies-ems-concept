# CODESYS implementation

Baseline: CODESYS 3.5 Structured Text with IEEE REAL and a target supporting true 64-bit LREAL/ULINT. No manufacturer library is required by the normalization code. The actual Modbus driver and OPC UA capability depend on your PLC/runtime.

## Add the objects

1. Create one DUT for each TYPE block in [Types.st](asset:codesys/Types.st). Add the optional [profile types](asset:codesys/ProfileTypes.st) when needed.
2. Create POUs named `F_EmsDecode32`, `FB_EmsSample` and `PRG_EmsExample`. Paste declarations and implementations into their respective editors; the files mark the split. CODESYS editors supply the enclosing POU/end markers.
3. Create `GVL_Ems` from the supplied GVL. Schedule the example program in the acquisition task.
4. Bind its input words and success/error pulses to your installed Modbus driver. Feed UTC milliseconds and clock-synchronization health. Do not assert clock health merely because the RTC call succeeded.

All generated fields use one of four wrappers: number, boolean, text or exact counter. Every wrapper contains the same `Meta`. Fill only configured capabilities; do not export the complete superset for every small sensor.

## Battery mapping example

```iecst
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

```

## Shared freshness and quality block

Use one `FB_EmsSample` instance per independently sampled point. It preserves time on failure and uses a monotonic clock for freshness. For BOOL, text and counters, copy the typed value when `xAccept` is true, then copy `Meta` exactly as in the number example.

```iecst
(* POU: FUNCTION_BLOCK FB_EmsSample. Declaration above the divider; implementation below it. *)
FUNCTION_BLOCK FB_EmsSample
VAR_INPUT
    xSupported : BOOL := TRUE;
    xEnabled : BOOL := TRUE;
    xNewSample : BOOL; (* One pulse per completed acquisition, NOT each PLC cycle. *)
    xReadError : BOOL; (* Failed transaction pulse; retained words are not new data. *)
    xValueValid : BOOL := TRUE;
    xClockValid : BOOL;
    uliUtcMs : ULINT;
    uliMonotonicMs : ULINT; (* LTIME_TO_ULINT(LTIME()) / ULINT#1000000 *)
    udiStaleAfterMs : UDINT := 5000;
END_VAR
VAR_OUTPUT
    Meta : ST_EmsMeta;
    xAccept : BOOL; (* Copy the decoded value only when TRUE. *)
END_VAR
VAR
    xSeen : BOOL;
    uliLastMs : ULINT;
END_VAR
(* IMPLEMENTATION *)
xAccept := FALSE;
IF NOT xSupported THEN
    Meta.Quality := 4; (* unsupported *)
    Meta.ObservedAtMs := 0;
    Meta.Sequence := 0;
    xSeen := FALSE;
ELSIF NOT xEnabled THEN
    Meta.Quality := 5; (* disabled; retain the last observation *)
ELSIF xReadError THEN
    Meta.Quality := 2; (* bad; preserve last observation time and value *)
ELSIF xNewSample THEN
    IF xValueValid THEN
        xAccept := TRUE;
        xSeen := TRUE;
        uliLastMs := uliMonotonicMs;
        IF xClockValid AND (uliUtcMs > 0) THEN
            Meta.Quality := 0;
            Meta.ObservedAtMs := uliUtcMs;
        ELSE
            Meta.Quality := 1; (* uncertain: no trustworthy UTC *)
            Meta.ObservedAtMs := 0;
        END_IF;
        IF Meta.Sequence = UDINT#4294967295 THEN
            Meta.Sequence := 1;
        ELSE
            Meta.Sequence := Meta.Sequence + 1;
        END_IF;
    ELSE
        Meta.Quality := 2; (* sentinel, range error or unmapped enum *)
    END_IF;
ELSIF xSeen THEN
    IF uliMonotonicMs < uliLastMs THEN
        Meta.Quality := 2; (* monotonic clock reset; wait for a new sample *)
    ELSIF (uliMonotonicMs - uliLastMs) > UDINT_TO_ULINT(udiStaleAfterMs) THEN
        Meta.Quality := 3; (* stale; UTC observation time stays unchanged *)
    END_IF;
END_IF;
END_FUNCTION_BLOCK

```

## Register decoder

The decoder handles signed/unsigned 16/32-bit integers and IEEE float32. Word/byte swaps are explicit. The scale and sign conversion are independent of the asset type. The exact UInt64 decoder below avoids floating-point rounding. For bits, test the configured mask; for statuses, use an explicit CASE and mark unknown codes invalid. Publish counters through `ST_EmsCounter`.

```iecst
(* POU: FUNCTION F_EmsDecode32. Raw words from ONE successful Modbus transaction. *)
FUNCTION F_EmsDecode32 : ST_EmsDecoded
VAR_INPUT
    wFirst : WORD;
    wSecond : WORD;
    xLowWordFirst : BOOL;
    xLowByteFirst : BOOL;
    usiEncoding : USINT; (* 0=uint16, 1=int16, 2=uint32, 3=int32, 4=float32 *)
    lrScale : LREAL := 1;
    lrOffset : LREAL;
    xHasSentinel : BOOL;
    dwSentinel : DWORD; (* Canonical bit order BEFORE scaling *)
END_VAR
VAR
    wA, wB, wTemporary : WORD;
    dwBits : DWORD;
    uBits : U_EmsReal32;
    lrRaw : LREAL;
END_VAR
(* IMPLEMENTATION *)
F_EmsDecode32.Valid := FALSE;
F_EmsDecode32.Value := 0;
wA := wFirst;
wB := wSecond;
IF xLowByteFirst THEN
    wA := SHL(wA AND WORD#16#00FF, 8) OR SHR(wA, 8);
    wB := SHL(wB AND WORD#16#00FF, 8) OR SHR(wB, 8);
END_IF;
IF xLowWordFirst AND (usiEncoding >= 2) THEN
    wTemporary := wA; wA := wB; wB := wTemporary;
END_IF;
IF usiEncoding < 2 THEN
    dwBits := WORD_TO_DWORD(wA);
ELSE
    dwBits := SHL(WORD_TO_DWORD(wA), 16) OR WORD_TO_DWORD(wB);
END_IF;
IF xHasSentinel AND (dwBits = dwSentinel) THEN RETURN; END_IF;
CASE usiEncoding OF
    0: lrRaw := WORD_TO_LREAL(wA);
    1:
        lrRaw := WORD_TO_LREAL(wA);
        IF wA >= WORD#16#8000 THEN lrRaw := lrRaw - LREAL#65536; END_IF;
    2: lrRaw := UDINT_TO_LREAL(DWORD_TO_UDINT(dwBits));
    3:
        lrRaw := UDINT_TO_LREAL(DWORD_TO_UDINT(dwBits));
        IF dwBits >= DWORD#16#80000000 THEN lrRaw := lrRaw - LREAL#4294967296; END_IF;
    4:
        IF (dwBits AND DWORD#16#7F800000) = DWORD#16#7F800000 THEN RETURN; END_IF; (* NaN/Inf *)
        uBits.Bits := dwBits;
        lrRaw := REAL_TO_LREAL(uBits.Value);
ELSE
    RETURN;
END_CASE;
F_EmsDecode32.Value := lrRaw * lrScale + lrOffset;
(* Practical engineering bound rejects NaN/overflow without target-specific math libraries. *)
F_EmsDecode32.Valid := (F_EmsDecode32.Value = F_EmsDecode32.Value)
    AND (ABS(F_EmsDecode32.Value) <= LREAL#1.0E30) AND (lrScale <> 0);
END_FUNCTION

```

## Exact counters

```iecst
(* POU: FUNCTION F_EmsDecode64. Exact UInt64 reconstruction; never pass via LREAL. *)
FUNCTION F_EmsDecode64 : ULINT
VAR_INPUT
    Words : ARRAY[0..3] OF WORD;
    xLowWordFirst : BOOL;
    xLowByteFirst : BOOL;
END_VAR
VAR
    i, j : INT;
    w : WORD;
END_VAR
(* IMPLEMENTATION *)
F_EmsDecode64 := 0;
FOR i := 0 TO 3 DO
    IF xLowWordFirst THEN j := 3 - i; ELSE j := i; END_IF;
    w := Words[j];
    IF xLowByteFirst THEN
        w := SHL(w AND WORD#16#00FF, 8) OR SHR(w, 8);
    END_IF;
    F_EmsDecode64 := SHL(F_EmsDecode64, 16) OR WORD_TO_ULINT(w);
END_FOR;
(* Validate the vendor's invalid sentinel before passing xValueValid to FB_EmsSample. *)
END_FUNCTION

```

## Publish via OPC UA

For supported 3.5 SP18+ systems, use **Communication Manager → OPC UA Server → IEC Symbol Publishing**. Publish the required Value and Meta members read-only. Exported symbol names can be stable even if internal IEC names change. Configure the PLC's symbol rights and verify its certificate/access settings.

Browse the actual server to discover namespace URIs, NodeIds and data types; example NodeIds are not portable. Reading Value and Meta as separate uncoordinated notifications is not an atomic sample. Use a coherent structured read or a producer-controlled snapshot/read handshake. The current gateway does not yet assemble these structured samples automatically; the [export adapter](#docs/export) makes that boundary explicit.

The reference code has **not been compiled in a CODESYS IDE here**. Before deployment, compile it on your target and test word order, loss/recovery, stale values, RTC loss and negative battery power. The supplied example is telemetry-only and sends no commands.

[CODESYS structures](https://content.helpme-codesys.com/en/CODESYS%20Development%20System/_cds_obj_dut.html) · [64-bit type support](https://content.helpme-codesys.com/en/CODESYS%20Development%20System/_cds_datatype_real.html) · [Symbol publishing](https://content.helpme-codesys.com/en/CODESYS%20Communication/_comm_symbol_configuration.html) · [UTC clock](https://content.helpme-codesys.com/en/LibDevSummary/date_time.html)
