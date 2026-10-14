// The red glass screen for a vanilla Virtual Arsenal that is not allowed (fnc_showBlocked). Its card is
// built at run time, inside a controls group of its own.
class EINV_ArsenalBlocked {
    idd = IDD_ARSENAL_BLOCKED;
    movingEnable = 0;
    enableSimulation = 1;
    onLoad = QUOTE(_this call (missionNamespace getVariable [ARR_2(QQFUNC(onBlockedLoad),{})]));
    onKeyDown = QUOTE(_this call (missionNamespace getVariable [ARR_2(QQFUNC(onBlockedKey),{false})]));

    class ControlsBackground {};
    class Controls {};
};
