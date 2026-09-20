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
