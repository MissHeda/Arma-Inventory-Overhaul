#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Reads a palette as the profile, an import or the CBA setting gives it (fnc_paletteImport): every entry checked, anything
 * that is not of its shape no choice. What the first version of the palette saved - three entries, a colour as [hue,
 * vividness] - still reads (value 1), and so does any shorter palette from before later rows (those unset). An alpha
 * beyond the range is cut to it, and the value of the panels, the cells and the tiles is cut at PALETTE_PANEL_VALUE_MAX as
 * fnc_paletteSet cuts it.
 *
 * Arguments:
 * 0: Palette <ARRAY>
 *
 * Return Value:
 * The palette, [] when it is none <ARRAY>
 *
 * Example:
 * [[[0.6, 0.7, 1], [], -1]] call einv_gui_fnc_paletteRead;
 *
 * Public: No
 */

params [["_savedPalette", [], [[]]]];

if (count _savedPalette < 3 || {count _savedPalette > count PALETTE_UNSET}) exitWith {[]};

private _read = [];

_savedPalette params [
    "_savedAccent", "_savedSecondary", "_savedAlpha", ["_savedPanel", []],
    ["_savedCells", []], ["_savedTiles", []], ["_savedText", []], ["_savedLines", []], ["_savedTileAlpha", -1],
    ["_savedCellAlpha", -1], ["_savedGradient", []], ["_savedStyle", ""], ["_savedTitle", []], ["_savedPanelEnd", []],
    ["_savedSecondaryAlpha", -1], ["_savedLinesAlpha", -1], "", ["_savedReach", -1]
];

private _fnc_alpha = {
    params ["_saved"];

    if (_saved isEqualType 0 && {_saved >= 0} && {_saved <= 1}) then {_saved max PALETTE_ALPHA_MIN} else {-1}
};

private _fnc_colour = {
    params ["_pick", "_valueMax"];

    if (_pick isEqualType [] && {count _pick in [2, 3]} && {_pick isEqualTypeAll 0} && {_pick findIf {!(_x >= 0 && {_x <= 1})} < 0}) then {
        [_pick select 0, _pick select 1, ((_pick param [2, 1]) min _valueMax)]
    } else {
        []
    }
};

_read = [
    [_savedAccent, 1] call _fnc_colour,
    [_savedSecondary, 1] call _fnc_colour,
    if (_savedAlpha isEqualType 0 && {_savedAlpha >= 0} && {_savedAlpha <= 1}) then {_savedAlpha max PALETTE_ALPHA_MIN} else {-1},
    [_savedPanel, PALETTE_PANEL_VALUE_MAX] call _fnc_colour,
    [_savedCells, PALETTE_PANEL_VALUE_MAX] call _fnc_colour,
    [_savedTiles, PALETTE_PANEL_VALUE_MAX] call _fnc_colour,
    [_savedText, 1] call _fnc_colour,
    [_savedLines, 1] call _fnc_colour,
    if (_savedTileAlpha isEqualType 0 && {_savedTileAlpha >= 0} && {_savedTileAlpha <= 1}) then {_savedTileAlpha max PALETTE_ALPHA_MIN} else {-1},
    if (_savedCellAlpha isEqualType 0 && {_savedCellAlpha >= 0} && {_savedCellAlpha <= 1}) then {_savedCellAlpha max PALETTE_ALPHA_MIN} else {-1},
    [_savedGradient, 1] call _fnc_colour,
    ["", _savedStyle] select (_savedStyle isEqualType ""),
    [_savedTitle, 1] call _fnc_colour,
    [_savedPanelEnd, PALETTE_PANEL_VALUE_MAX] call _fnc_colour,
    [_savedSecondaryAlpha] call _fnc_alpha,
    [_savedLinesAlpha] call _fnc_alpha,
    -1,
    if (_savedReach isEqualType 0 && {_savedReach >= 0} && {_savedReach <= GRADIENT_PARTS_ALL} && {_savedReach == floor _savedReach}) then {_savedReach} else {-1}
];

_read
