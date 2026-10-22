#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The accent colour of every window of the mod (issue 14): the player's own active element colour from Arma's
 * Options > Game > Colors, which the game keeps in the profile as GUI_BCG_RGB_R, _G and _B (the alpha, GUI_BCG_RGB_A,
 * is the menus' see-through and is not read - every shade here sets its own). The themes ask for it when they are
 * built (fnc_theme, fnc_themeBase), so the window, the setup wizard, the Arsenal panel and every chip, button, ring
 * and highlight in them follow the colour the player chose; the profile is looked at once per theme and costs
 * three lookups. A colour the player picked in the palette (the header's palette button, fnc_palette) takes the
 * profile's place - and is made readable like it - unless the server switched the palette off.
 *
 * The colour is made readable first: on the near-black panes a very dark red or blue would sink, so one whose
 * luminance is below ACCENT_MIN_LUMA is brightened - scaled up with its hue while a channel has room, then mixed
 * towards white - until it reaches it. A profile with no colour, or a value that is no number between 0 and 1, gives
 * ACCENT_FALLBACK, the orange the mod always had.
 *
 * The other shades are worked out from the accent, not read again: pass it as the second argument.
 *   ""      the accent, alpha 1
 *   "soft"  the accent as a film, alpha ACCENT_SOFT_ALPHA (tinted tiles, the banner, a picked row)
 *   "hover" the accent lighter by ACCENT_HOVER_MIX towards white, alpha 1 (a button of the accent under the mouse)
 *   "on"    the ink for text and icons on a fill of the accent: ACCENT_INK_DARK or ACCENT_INK_LIGHT, whichever
 *           contrasts more with it
 *
 * Arguments:
 * 0: Shade <STRING> (default: "")
 * 1: Accent to work from <ARRAY> (default: [] - the profile's)
 *
 * Return Value:
 * Colour [r, g, b, a] <ARRAY>
 *
 * Example:
 * private _accent = call einv_gui_fnc_accentColour;
 * private _soft = ["soft", _accent] call einv_gui_fnc_accentColour;
 *
 * Public: No
 */

params [["_shade", "", [""]], ["_base", [], [[]]]];

private _rgb = _base select [0, 3];

// Luminance by the weights of sRGB, in a gamma of 2.2
private _fnc_luma = {
    params ["_color"];

    0.2126 * ((_color select 0) ^ 2.2) + 0.7152 * ((_color select 1) ^ 2.2) + 0.0722 * ((_color select 2) ^ 2.2)
};

if (count _rgb < 3) then {
    // The player's own pick in the palette (fnc_palette: [hue, vividness], or [] for none) comes before the profile's colour.
    private _pick = (([] call FUNC(palette)) select 0);

    if (_pick isNotEqualTo []) then {
        _rgb = ["rgb", [_pick select 0, _pick select 1, 1]] call FUNC(hsv);
    } else {
        // A channel the profile does not hold reads as -1, which no colour has
        _rgb = ["R", "G", "B"] apply {profileNamespace getVariable [format ["GUI_BCG_RGB_%1", _x], -1]};

        if (!(_rgb isEqualTypeAll 0) || {_rgb findIf {!(_x >= 0 && {_x <= 1})} >= 0}) then {
            _rgb = ACCENT_FALLBACK select [0, 3];
        };
    };

    // Brightened as the profile's colour is: a pure blue would sink into the near-black panes as well.
    for "_i" from 1 to 40 do {
        if (([_rgb] call _fnc_luma) >= ACCENT_MIN_LUMA) exitWith {};

        private _top = selectMax _rgb;

        _rgb = if (_top >= 0.1 && {_top < 1}) then {
            _rgb apply {(_x * 1.12) min 1}
        } else {
            _rgb apply {_x + (1 - _x) * 0.08}
        };
    };
};

switch (_shade) do {
    case "soft": {_rgb + [ACCENT_SOFT_ALPHA]};
    case "hover": {(_rgb apply {_x + (1 - _x) * ACCENT_HOVER_MIX}) + [1]};
    case "on": {
        // Contrast as (lighter + 0.05) / (darker + 0.05)
        private _fill = ([_rgb] call _fnc_luma) + 0.05;
        private _dark = ([ACCENT_INK_DARK] call _fnc_luma) + 0.05;

        [ACCENT_INK_LIGHT, ACCENT_INK_DARK] select (_fill / _dark >= 1.05 / _fill)
    };
    default {_rgb + [1]};
}
