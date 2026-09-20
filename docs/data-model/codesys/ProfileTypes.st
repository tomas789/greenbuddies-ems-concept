(* Additional DUTs. Fixed reference bounds: 64 intervals, 32 targets per interval. Reject larger input before copying. *)
TYPE ST_EmsTarget :
STRUCT
    AssetId : STRING(128);
    ActivePowerW : LREAL;
END_STRUCT
END_TYPE

TYPE ST_EmsInterval :
STRUCT
    StartMs : ULINT;
    EndMs : ULINT;
    TargetCount : UINT;
    Targets : ARRAY[1..32] OF ST_EmsTarget;
END_STRUCT
END_TYPE

TYPE ST_EmsProfile :
STRUCT
    Revision : STRING(128);
    ValidFromMs : ULINT;
    ValidUntilMs : ULINT;
    IntervalCount : UINT;
    Intervals : ARRAY[1..64] OF ST_EmsInterval;
END_STRUCT
END_TYPE

TYPE ST_EmsCommandResult :
STRUCT
    CommandId : STRING(128);
    Revision : STRING(128);
    State : STRING(32); (* received, validated, accepted, applied, rejected, expired *)
    Reason : STRING(255);
    AtMs : ULINT;
END_STRUCT
END_TYPE
