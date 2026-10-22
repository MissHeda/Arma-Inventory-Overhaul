#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The palette popover (fnc_openPaletteMenu) closed, or the window closed with it open: what the player chose is written to
 * the profile as einv_gui_palette = [accent, secondary, alpha] (fnc_palette) - once, here, not with every move of a slider
 * - and the header's button is drawn for the state it is in. Asked by fnc_closeMenu whenever the menu it closes was the
 * popover (not when the popover is only made again over a build or on top of a redraw - einv_gui_menuRemake) and by
 * fnc_onUnload.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call einv_gui_fnc_paletteSettle;
 *
 * Public: No
 */

// A slider still held is let go.
["end"] call FUNC(paletteSlide);

if (GVAR(paletteDirty)) then {
    GVAR(paletteDirty) = false;

    profileNamespace setVariable [QGVAR(palette), +GVAR(palette)];
    saveProfileNamespace;
};

uiNamespace setVariable [QGVAR(paletteRows), createHashMap];

[] call FUNC(updatePaletteButton);
