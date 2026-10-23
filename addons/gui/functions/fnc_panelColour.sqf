#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The colour of the window's panels - the near-black of the columns, the header and the footer (the theme's "panel", with the palette's
 * transparency as its alpha; fnc_theme) - as RGB: the player's pick in the palette (fnc_palette, the third colour of the popover), or
 * PANEL_COLOR, the near-black grey the window has always had.
 *
 * The pick is kept dark so that the white text, the greys and the accent on the panels stay readable whatever the player picks: its
 * value (the V of hue, saturation and value) is cut at PALETTE_PANEL_VALUE_MAX, so the panel's luminance (gamma 2.2) is 0.07 at the
 * very most - white text keeps 8.7 : 1 against it, the light grey of the second line 5.2 : 1. The popover cuts a pick the same way
 * when it is made (fnc_paletteSet) and so does the profile's loading (XEH_preInit); this is the last of three, for a value that came
 * from anywhere else. What stays readable beyond that is worked out from this colour: the text and its dimmer shades are lifted
 * where a lighter panel (or lighter cells or tiles) would take them below their contrast (fnc_theme), and the accent is brightened
 * to keep its own against the panel (fnc_accentColour). Only the panels follow this colour: the cells, slot boxes and tiles on them
 * keep their own (fnc_theme).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Colour [r, g, b] <ARRAY>
 *
 * Example:
 * private _rgb = [] call einv_gui_fnc_panelColour;
 *
 * Public: No
 */

private _pick = ([] call FUNC(palette)) param [3, []];

if (!(_pick isEqualType []) || {count _pick < 3}) exitWith {
    +PANEL_COLOR
};

_pick params [["_hue", 0, [0]], ["_saturation", 0, [0]], ["_value", 0, [0]]];

["rgb", [_hue, (_saturation max 0) min 1, ((_value max 0) min 1) min PALETTE_PANEL_VALUE_MAX]] call FUNC(hsv)
