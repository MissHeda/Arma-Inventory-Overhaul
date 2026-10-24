#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * What the palette popover shows (fnc_openPaletteMenu, fnc_updatePaletteMenu, fnc_paletteSet): for each of its colours - 0 accent,
 * 1 secondary, 2 panels, 3 cells, 4 tiles, 5 text, 6 lines - and for the panels' alpha and the tiles' alpha, the values the pickers
 * stand at and the colour to preview: the player's choice where there is one, else what the window wears without it. Without a choice the accent is
 * the Arma profile's colour (fnc_accentColour, brightened for the dark panes), the secondary colour follows the accent, the panels'
 * colour is PANEL_COLOR, the cells and the tiles are the colour they are seen in (a cell's film over the card over the panel, the
 * misc tile's over the card), the text is its white and the lines are the white their films are tinted with; the panels' alpha is
 * PANEL_ALPHA and the tiles' alpha 1 (the tiles are solid once anything in the palette is chosen; the colour a tile is worn in is
 * read without its alpha while the tiles' alpha is chosen, so the Tiles swatch does not change with the slider). A colour is shown as hue, saturation and value (fnc_hsv): for a colour without a choice they are worked out from the
 * colour the window wears, so the first move of a picker starts from it and changes only what it moves.
 *
 * Reads the player's own choices (einv_gui_palette), not what fnc_palette hands the themes: the popover only exists where
 * the server allows the palette. What the window wears is read from its theme (einv_gui_theme), the one of its last build: a choice
 * just taken away shows its plain colour once the build that follows has made the popover again.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Keys <HASHMAP>:
 *   hsv      [hue, saturation, value] of each colour, by its number (the value of the panels, the cells and the tiles cut at
 *            PALETTE_PANEL_VALUE_MAX): where the cursors stand
 *   rgb      the same as [r, g, b] 0 to 1: what the fields show
 *   swatch   [r, g, b] of what each swatch shows: the accent and the text as the window wears them (brightened where they would
 *            sink), the others as picked
 *   alpha    the panels' alpha shown
 *   tileAlpha  the item tiles' alpha shown
 *   set      each colour by its number, then the panels' alpha and then the tiles' alpha, true where the player chose it (what
 *            "Use my Arma colour", "Default" and the like take away)
 *   any      any of them is chosen
 *
 * Example:
 * private _info = [] call einv_gui_fnc_paletteInfo;
 *
 * Public: No
 */

GVAR(palette) params [
    ["_accentPick", [], [[]]], ["_secondaryPick", [], [[]]], ["_alphaPick", -1, [0]], ["_panelPick", [], [[]]],
    ["_cellsPick", [], [[]]], ["_tilesPick", [], [[]]], ["_textPick", [], [[]]], ["_linesPick", [], [[]]],
    ["_tileAlphaPick", -1, [0]]
];

private _theme = missionNamespace getVariable [QGVAR(theme), createHashMap];

// A colour as it is seen where it lies, as [r, g, b]: a film mixed with what is under it by its alpha, a solid one as it is.
private _fnc_seen = {
    params ["_color", "_under"];

    if (count _color < 3) exitWith {+_under};

    private _alpha = _color param [3, 1];

    [0, 1, 2] apply {(_color select _x) * _alpha + (_under select _x) * (1 - _alpha)}
};

private _accentWorn = (["", []] call FUNC(accentColour)) select [0, 3];
private _textWorn = (_theme getOrDefault ["text", [1, 1, 1, 1]]) select [0, 3];

// What the cells and the tiles lie on: the card's film over the panel.
private _panelSeen = (_theme getOrDefault ["panel", []]) select [0, 3];

if (count _panelSeen < 3) then {
    _panelSeen = +PANEL_COLOR;
};

private _cardSeen = [_theme getOrDefault ["card", []], _panelSeen] call _fnc_seen;

// The misc tile as the window wears it. While the tiles' alpha is chosen the theme's tile carries it, and the colour of the Tiles row
// is the tile itself, so it is read as a solid one.
private _tileWorn = +((_theme getOrDefault ["tileBg", []]) param [CATEGORY_MISC, []]);

if (_tileAlphaPick >= 0 && {count _tileWorn >= 3}) then {
    _tileWorn = (_tileWorn select [0, 3]) + [1];
};

// What each colour is without a choice, by its number (the secondary colour follows the accent, below).
private _plain = [
    _accentWorn,
    _accentWorn,
    +PANEL_COLOR,
    [_theme getOrDefault ["cell", []], _cardSeen] call _fnc_seen,
    [_tileWorn, _cardSeen] call _fnc_seen,
    _textWorn,
    (_theme getOrDefault ["line", [1, 1, 1, 1]]) select [0, 3]
];

private _picks = [_accentPick, _secondaryPick, _panelPick, _cellsPick, _tilesPick, _textPick, _linesPick];
private _hsv = [];

{
    private _which = _forEachIndex;
    private _at = switch (true) do {
        case (_x isNotEqualTo []): {+_x};
        case (_which == 1): {+(_hsv select 0)};
        default {["hsv", _plain select _which] call FUNC(hsv)};
    };

    _at set [2, (_at select 2) min (PALETTE_VALUE_MAX select _which)];
    _hsv pushBack _at;
} forEach _picks;

private _rgb = _hsv apply {["rgb", _x] call FUNC(hsv)};
private _swatch = +_rgb;

_swatch set [0, _accentWorn];
_swatch set [5, _textWorn];

private _set = (_picks apply {_x isNotEqualTo []}) + [_alphaPick >= 0, _tileAlphaPick >= 0];

createHashMapFromArray [
    ["hsv", _hsv],
    ["rgb", _rgb],
    ["swatch", _swatch],
    ["alpha", [PANEL_ALPHA, _alphaPick] select (_alphaPick >= 0)],
    ["tileAlpha", [1, _tileAlphaPick] select (_tileAlphaPick >= 0)],
    ["set", _set],
    ["any", true in _set]
]
