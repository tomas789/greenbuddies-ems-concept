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
