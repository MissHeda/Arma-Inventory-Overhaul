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

class EINV_FooterHint;

// The panel's hint line (fnc_footer) in the size of ACE's own message line (IDC 9) rather than the
// inventory's footer: it is the last band of a panel that looks like ACE's.
class EINV_ArsenalHint: EINV_FooterHint {
    size = QUOTE(ACE_TEXT_SIZE);
};
