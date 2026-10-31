// The setup wizard. Like the inventory, only the dim layer is here: everything on the window is created
// at run time (fnc_onLoad, fnc_showStep), and all of it inside the wizard's own controls groups - so none
// of it lands in the inventory's list of controls, which its next build deletes.
//
// fnc_open makes it over whatever display asked for it - CBA's Addon Options, Eden, the game's own
// screen. The pause menu's entry (CBA_fnc_addPauseMenuOption) has the engine make it with no word on how,
// so onLoad copes without any: direct mode, at the first step.

class AIO_Edit;
class AIO_Label;
class AIO_PanelRect;

// The rules text: as many lines as a setup takes, in a font whose characters are all as wide as each
// other, so the statements line up. Longer than TEXT_MAX (script_component.hpp), so a text that is too
// long still arrives whole and can be shortened, rather than being cut where nobody sees it. Several lines
// and no frame of its own (ST_MULTI + ST_NO_RECT): it lies on a surface drawn under it (fnc_uiEdit).
class AIO_EditArea: AIO_Edit {
    style = 528;
    font = "EtelkaMonospacePro";
    sizeEx = QUOTE(UNIT * 0.56);
    lineSpacing = 1;
    maxChars = 20000;
};

// The same text to read and copy from, not to type into - the shared forms of it (fnc_exportText).
class AIO_EditAreaReadOnly: AIO_EditArea {
    canModify = 0;
};

// One line to read and copy from, not to type into - a texture path (fnc_uiEdit with selectable set). Room
// for a long path: the text is cut at maxChars.
class AIO_EditReadOnly: AIO_Edit {
    canModify = 0;
    maxChars = 1024;
};

class GVAR(RscWizard) {
    idd = IDD_WIZARD;
    movingEnable = 0;
    enableSimulation = 1;
    onLoad = QUOTE(_this call (uiNamespace getVariable [ARR_2(QQFUNC(onLoad),{})]));
    onUnload = QUOTE(_this call (uiNamespace getVariable [ARR_2(QQFUNC(onUnload),{})]));

    class ControlsBackground {
        // Whatever is behind - the game, Eden, CBA's menu - dimmed, so the wizard has the attention.
        class Dim: AIO_PanelRect {
            idc = IDC_WIZARD_DIM;
            x = QUOTE(safezoneX);
            y = QUOTE(safezoneY);
            w = QUOTE(safezoneW);
            h = QUOTE(safezoneH);
            colorBackground[] = {0, 0, 0, 0.55};
        };
    };

    class Controls {
        // In Enhanced First Aid Kits the first control here drew no background (2026-09). This empty one
        // takes the place, so no real control lands on it.
        class First: AIO_Label {
            idc = IDC_WIZARD_FIRST;
            x = 0;
            y = 0;
            w = 0;
            h = 0;
        };
    };
};
