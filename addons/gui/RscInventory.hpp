// The inventory window. Only the dim layer is here: everything on it is created at run time
// (fnc_build), because the style decides the layout - and switching the style rebuilds the window.

class EINV_InventoryDialog {
    idd = IDD_INVENTORY;
    movingEnable = 0;
    enableSimulation = 1;
    onLoad = QUOTE(uiNamespace setVariable [ARR_2(QQGVAR(display),_this select 0)]);
    onUnload = QUOTE(_this call FUNC(onUnload));
    onKeyDown = QUOTE(_this call FUNC(onKeyDown));

    class ControlsBackground {
        // The world behind, dimmed, so the window has the attention. The style recolours it - lighter
        // while the camera shows the soldier.
        class Dim: EINV_PanelRect {
            idc = IDC_DIM;
            x = QUOTE(safezoneX);
            y = QUOTE(safezoneY);
            w = QUOTE(safezoneW);
            h = QUOTE(safezoneH);
            colorBackground[] = {0, 0, 0, 0.45};
        };
    };

    class Controls {
        // In Enhanced First Aid Kits the first control here drew no background (2026-09). This empty one
        // takes the place, so no real control lands on it.
        class First: EINV_Label {
            idc = IDC_FIRST;
            x = 0;
            y = 0;
            w = 0;
            h = 0;
        };
    };
};
