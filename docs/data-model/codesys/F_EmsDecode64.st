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
