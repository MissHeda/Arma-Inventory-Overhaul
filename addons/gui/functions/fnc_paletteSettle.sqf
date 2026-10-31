#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The palette popover (fnc_openPaletteMenu) closed, or the window closed with it open: what the player chose is written to
 * the profile as aio_gui_palette = [accent, secondary, alpha, panel, cells, tiles, text, lines] (fnc_palette) - once, here,
 * not with every move of a picker - and the header's button is drawn for the state it is in. Asked by fnc_closeMenu whenever the
 * menu it closes was the popover (not when the popover is only made again over a build or on top of a redraw -
 * aio_gui_menuRemake) and by fnc_onUnload.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call aio_gui_fnc_paletteSettle;
 *
 * Public: No
 */

// A picker still held is let go, and what was being typed in a field goes with the popover.
["end"] call FUNC(paletteSlide);

uiNamespace setVariable [QGVAR(paletteTyping), []];

// The Import or Export line closes with the popover, and its hint line forgets the last tip.
uiNamespace setVariable [QGVAR(paletteIO), ""];
uiNamespace setVariable [QGVAR(menuHintText), ""];

if (GVAR(paletteDirty)) then {
    GVAR(paletteDirty) = false;

    profileNamespace setVariable [QGVAR(palette), +GVAR(palette)];
    saveProfileNamespace;

    // The CBA setting shows the same colours as text (Configure Addons, client), so they can be copied from there or set
    // there - unless a server or mission forces it.
    if (!isNil "CBA_settings_fnc_set" && {!([] call FUNC(paletteForced))}) then {
        [QGVAR(paletteText), str GVAR(palette), 0, "client"] call CBA_settings_fnc_set;
    };
};

uiNamespace setVariable [QGVAR(paletteRows), createHashMap];

[] call FUNC(updatePaletteButton);
