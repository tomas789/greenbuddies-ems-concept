(* Create a FUNCTION_BLOCK POU. Declarations above, implementation below the divider.
   Requires the CODESYS Standard library (TON). Example settings are not safety limits.
   One instance per condition. Call every scan from ONE acquisition/alarm task.
   Acknowledgement belongs to Alarm Manager, never to this block. *)
FUNCTION_BLOCK FB_EmsHighAlarm
VAR_INPUT
    lrValue       : LREAL;
    xValid        : BOOL;        (* Good, fresh sample AND valid mapping *)
    lrHigh        : LREAL;
    lrReset       : LREAL;       (* Must be below lrHigh: hysteresis *)
    tRaiseDelay   : TIME := T#2s;
    tClearDelay   : TIME := T#5s;
END_VAR
VAR_OUTPUT
    xActive       : BOOL;        (* Digital alarm expression; never writable by HMI *)
    xInputFault   : BOOL;        (* Separate communication/measurement alarm *)
    xConfigFault  : BOOL;
END_VAR
VAR
    fbRaise       : TON;
    fbClear       : TON;
END_VAR
(* ---- Implementation ---- *)
xConfigFault := (lrReset >= lrHigh);
xInputFault := NOT xValid;
IF xInputFault OR xConfigFault THEN
    fbRaise(IN := FALSE, PT := tRaiseDelay);
    fbClear(IN := FALSE, PT := tClearDelay);
    (* Hold last known condition; unavailable data must not clear a fault. *)
ELSE
    fbRaise(IN := (NOT xActive) AND (lrValue >= lrHigh), PT := tRaiseDelay);
    fbClear(IN := xActive AND (lrValue <= lrReset), PT := tClearDelay);
    IF fbRaise.Q THEN
        xActive := TRUE;
    ELSIF fbClear.Q THEN
        xActive := FALSE;
    END_IF;
END_IF;
END_FUNCTION_BLOCK
