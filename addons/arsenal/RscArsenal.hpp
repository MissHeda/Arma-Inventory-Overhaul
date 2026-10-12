class EINV_PanelRect;
class EINV_Label;

// The Enhanced Arsenal: like the inventory window, only the dim layer and the first control are in config -
// everything else is built at run time by gui's engine (einv_gui_fnc_attach). gui's rebuild keeps exactly
// these two ids and the one for what a window keeps (IDC_KEEP), so they are the inventory's own.
class EINV_ArsenalDisplay {
    idd = IDD_ARSENAL;
    movingEnable = 0;
    enableSimulation = 1;
    onLoad = QUOTE(_this call (missionNamespace getVariable [ARR_2(QQFUNC(onLoad),{})]));
    onUnload = QUOTE(_this call (missionNamespace getVariable [ARR_2(QQFUNC(onUnload),{})]));
    onKeyDown = QUOTE(_this call (missionNamespace getVariable [ARR_2(QQEFUNC(gui,onKeyDown),{false})]));
    onKeyUp = QUOTE(ACEGVAR(arsenal,shiftState) = _this select 2; false);

    class ControlsBackground {
        class Dim: EINV_PanelRect {
            idc = IDC_DIM;
            x = QUOTE(safezoneX);
            y = QUOTE(safezoneY);
            w = QUOTE(safezoneW);
            h = QUOTE(safezoneH);
            colorBackground[] = {0, 0, 0, 0};
        };
    };

    class Controls {
        // As in the inventory: an empty control takes the first place, so no real control lands on it.
        class First: EINV_Label {
            idc = IDC_FIRST;
            x = 0;
            y = 0;
            w = 0;
            h = 0;
        };
    };
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
