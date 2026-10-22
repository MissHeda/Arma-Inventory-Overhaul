#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * What the palette popover shows (fnc_openPaletteMenu, fnc_updatePaletteMenu, fnc_paletteSet): for the accent, the secondary
 * colour, the panels' colour and the panels' alpha, the values the pickers stand at and the colour to preview - the player's choice
 * where there is one, else what the window wears without it. Without a choice the accent is the Arma profile's colour
 * (fnc_accentColour, brightened for the dark panes), the secondary colour follows the accent, the panels' colour is PANEL_COLOR and
 * the alpha is PANEL_ALPHA. A colour is shown as hue, saturation and value (fnc_hsv): for a colour without a choice they are worked
 * out from the colour the window wears, so the first move of a picker starts from it.
 *
 * Reads the player's own choices (einv_gui_palette), not what fnc_palette hands the themes: the popover only exists where
 * the server allows the palette.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Keys <HASHMAP>:
 *   hsv      [hue, saturation, value] of the accent, the secondary colour and the panels' colour, in that order (the panels'
 *            value cut at PALETTE_PANEL_VALUE_MAX): where the cursors stand
 *   rgb      the same three as [r, g, b] 0 to 1: what the fields show
 *   swatch   [r, g, b] of what the swatches show: the accent as the window wears it (brightened where it would sink), the secondary
 *            colour and the panels' colour as picked
 *   alpha    the panels' alpha shown
 *   set      [accent, secondary, panels, alpha], each true where the player chose it (what "Use my Arma colour" and the like take away)
 *   any      any of the four is chosen
 *
 * Example:
 * private _info = [] call einv_gui_fnc_paletteInfo;
 *
 * Public: No
 */

GVAR(palette) params [["_accentPick", [], [[]]], ["_secondaryPick", [], [[]]], ["_alphaPick", -1, [0]], ["_panelPick", [], [[]]]];

private _accentWorn = (["", []] call FUNC(accentColour)) select [0, 3];

private _accentHsv = if (_accentPick isEqualTo []) then {
    ["hsv", _accentWorn] call FUNC(hsv)
} else {
    +_accentPick
};

private _secondaryHsv = if (_secondaryPick isEqualTo []) then {+_accentHsv} else {+_secondaryPick};

private _panelHsv = if (_panelPick isEqualTo []) then {
    ["hsv", PANEL_COLOR] call FUNC(hsv)
} else {
    +_panelPick
};

_panelHsv set [2, (_panelHsv select 2) min PALETTE_PANEL_VALUE_MAX];

private _hsv = [_accentHsv, _secondaryHsv, _panelHsv];
private _rgb = _hsv apply {["rgb", _x] call FUNC(hsv)};

private _set = [_accentPick isNotEqualTo [], _secondaryPick isNotEqualTo [], _panelPick isNotEqualTo [], _alphaPick >= 0];

createHashMapFromArray [
    ["hsv", _hsv],
    ["rgb", _rgb],
    ["swatch", [_accentWorn, _rgb select 1, _rgb select 2]],
    ["alpha", [PANEL_ALPHA, _alphaPick] select (_set select 3)],
    ["set", _set],
    ["any", true in _set]
]
