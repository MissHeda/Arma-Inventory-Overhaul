#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * What the palette popover shows (fnc_openPaletteMenu, fnc_updatePaletteMenu, fnc_paletteSet): for the accent, the
 * secondary colour and the panels' alpha, the value the sliders stand at and the colour to preview - the player's choice where
 * there is one, else what the window has without it. Without a choice the accent is the Arma profile's colour (fnc_accentColour,
 * brightened for the dark panes), the secondary colour follows the accent, and the alpha is PANEL_ALPHA. A colour's sliders
 * show its hue and vividness: for the profile's colour they are worked out from it (fnc_hsv), so the first move of a slider
 * starts from the colour the window wears.
 *
 * Reads the player's own choices (einv_gui_palette), not what fnc_palette hands the themes: the popover only exists where
 * the server allows the palette.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Keys <HASHMAP>:
 *   accentHs, secondaryHs     [hue, vividness] for the sliders
 *   accentRgb, secondaryRgb   [r, g, b] for the swatches
 *   alpha                     the panels' alpha shown
 *   accentSet, secondarySet, alphaSet   the player chose it (what "Use my Arma colour" and the like would take away)
 *   any                       any of the three is chosen
 *
 * Example:
 * private _info = [] call einv_gui_fnc_paletteInfo;
 *
 * Public: No
 */

GVAR(palette) params ["_accentPick", "_secondaryPick", "_alphaPick"];

private _accentRgb = (["", []] call FUNC(accentColour)) select [0, 3];
private _accentHs = if (_accentPick isEqualTo []) then {
    (["hsv", _accentRgb] call FUNC(hsv)) select [0, 2]
} else {
    +_accentPick
};

private _secondaryHs = if (_secondaryPick isEqualTo []) then {+_accentHs} else {+_secondaryPick};
private _secondaryRgb = if (_secondaryPick isEqualTo []) then {
    +_accentRgb
} else {
    ["rgb", _secondaryHs + [1]] call FUNC(hsv)
};

private _accentSet = _accentPick isNotEqualTo [];
private _secondarySet = _secondaryPick isNotEqualTo [];
private _alphaSet = _alphaPick >= 0;

createHashMapFromArray [
    ["accentHs", _accentHs],
    ["accentRgb", _accentRgb],
    ["secondaryHs", _secondaryHs],
    ["secondaryRgb", _secondaryRgb],
    ["alpha", [PANEL_ALPHA, _alphaPick] select _alphaSet],
    ["accentSet", _accentSet],
    ["secondarySet", _secondarySet],
    ["alphaSet", _alphaSet],
    ["any", _accentSet || _secondarySet || _alphaSet]
]
