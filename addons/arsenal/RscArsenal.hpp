class EINV_FooterHint;

// The panel's hint line (fnc_footer): the inventory's footer hint at the panel's own text size, in ACE's
// grid (HINT_SIZE), which the "hint" hook measures its texts by.
class EINV_ArsenalHint: EINV_FooterHint {
    size = QUOTE(HINT_SIZE);
};

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
