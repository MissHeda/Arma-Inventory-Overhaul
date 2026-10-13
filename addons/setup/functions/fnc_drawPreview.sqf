#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * "This is how it looks": what an editor's canvas (fnc_uiCanvas) gives, the way the inventory draws it -
 * on the inventory's panel, in its cells, a pixel apart.
 *   - A container's compartments laid out as the inventory lays them out (einv_gui_fnc_flowCompartments):
 *     side by side as far as STORAGE_COLS cells reach, a gap between two, then on the next line - so a
 *     compartment drawn beside another on the canvas that the inventory puts under it shows that here.
 *   - An item's tile on a piece of grid: its surface on its cells only (einv_gui_fnc_uiShape), its
 *     picture over its box, as a tile is drawn.
 * Drawn again on its own after a click on the canvas: it replaces the one drawn before
 * (uiNamespace QGVAR(preview)).
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group to create it in <CONTROL>
 * 2: Position [x, y, w, h], relative to the group <ARRAY>
 * 3: Theme <HASHMAP>
 * 4: Compartments [[cols, rows, holes], ...] - for an item its shape alone, [] for none <ARRAY>
 * 5: For an item [picture, category]; [] for a container <ARRAY> (default: [])
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, _box, [0.2, 0.1, 0.2, 0.2], _theme, [[2, 2, [3]]], [_picture, 2]] call einv_setup_fnc_drawPreview;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_parent", "_rect", ["_theme", createHashMap, [createHashMap]], ["_blocks", [], [[]]], ["_item", [], [[]]]];

ctrlDelete (uiNamespace getVariable [QGVAR(preview), controlNull]);

_rect params ["", "", "_width", "_height"];

private _group = [_display, "EINV_ScrollGroup", _parent, _rect] call EFUNC(gui,uiCreate);

uiNamespace setVariable [QGVAR(preview), _group];

private _cellColor = +(_theme getOrDefault ["cell", [1, 1, 1, 0.05]]);

// The inventory's cells are faint on its own panel; on the editor's card they would all but vanish.
_cellColor set [3, (_cellColor param [3, 0.05]) max 0.09];

private _padY = UNIT * 0.35;
private _padX = SQUARE(_padY);
private _areaW = _width - _padX * 2 - SCROLL_W;

if (_item isNotEqualTo []) exitWith {
    _item params [["_picture", ""], ["_category", CATEGORY_MISC]];

    (_blocks param [0, [0, 0, []]]) params ["_w", "_h", ["_holes", []]];

    // A piece of grid a cell wider than the tile all round, as wide as it fits.
    private _gridCols = STORAGE_COLS min ((_w max 1) + 2);
    private _gridRows = (_h max 1) + 2;
    private _cellH = ((UNIT * 0.8) min ((_height - _padY * 2) / _gridRows)) min (_areaW / _gridCols * pixelH / pixelW);
    private _cellW = SQUARE(_cellH);

    [
        _display, _group, [0, 0, _padX * 2 + _gridCols * _cellW, _padY * 2 + _gridRows * _cellH],
        _theme getOrDefault ["panel", [0.05, 0.05, 0.05, 0.92]], (_theme getOrDefault ["radius", 0]) min (UNIT * 0.3)
    ] call EFUNC(gui,uiPanel);

    for "_row" from 0 to (_gridRows - 1) do {
        for "_col" from 0 to (_gridCols - 1) do {
            [_display, _group, [_padX + _col * _cellW, _padY + _row * _cellH, _cellW - pixelW, _cellH - pixelH], _cellColor] call EFUNC(gui,uiPanel);
        };
    };

    if (_w < 1) exitWith {};

    private _origin = [_padX + ([_cellW, 0] select (_w + 2 > STORAGE_COLS)), _padY + _cellH];
    private _tileBg = (_theme getOrDefault ["tileBg", []]) param [_category, [0.15, 0.15, 0.15, 0.92]];

    if !(_tileBg isEqualType []) then {
        _tileBg = [0.15, 0.15, 0.15, 0.92];
    };

    [_display, _group, _origin, _cellW, _cellH, [_w, _h, _holes], _tileBg] call EFUNC(gui,uiShape);

    if (_picture isNotEqualTo "") then {
        [_display, _group, [_origin select 0, _origin select 1, _w * _cellW - pixelW, _h * _cellH - pixelH], _picture] call EFUNC(gui,uiPicture);
    };
};

// A container: the compartments where the inventory puts them.
private _cellH = (UNIT * 0.85) min (_areaW / (STORAGE_COLS + 0.5) * pixelH / pixelW);
private _cellW = SQUARE(_cellH);
private _gapX = round (_cellW * 0.22 / pixelW) * pixelW;
private _gapY = round (_cellH * 0.22 / pixelH) * pixelH;
private _gridW = STORAGE_COLS * _cellW;
private _lineX = 0;
private _lineY = 0;
private _lineH = 0;
private _places = [];

{
    _x params ["_w", "_h"];

    private _blockW = _w * _cellW;

    if (_lineX > 0 && {_lineX + _blockW > _gridW + 0.0001}) then {
        _lineX = 0;
        _lineY = _lineY + _lineH + _gapY;
        _lineH = 0;
    };

    _places pushBack [_lineX, _lineY];
    _lineX = _lineX + _blockW + _gapX;
    _lineH = _lineH max (_h * _cellH);
} forEach _blocks;

private _contentH = _lineY + _lineH;

[
    _display, _group, [0, 0, (_padX * 2 + _gridW) min (_width - SCROLL_W), (_padY * 2 + _contentH) max (UNIT * 1)],
    _theme getOrDefault ["panel", [0.05, 0.05, 0.05, 0.92]], (_theme getOrDefault ["radius", 0]) min (UNIT * 0.3)
] call EFUNC(gui,uiPanel);

{
    _x params ["_w", "_h", ["_holes", []]];
    (_places select _forEachIndex) params ["_left", "_top"];

    for "_row" from 0 to (_h - 1) do {
        for "_col" from 0 to (_w - 1) do {
            if !((_row * _w + _col) in _holes) then {
                [
                    _display, _group, [_padX + _left + _col * _cellW, _padY + _top + _row * _cellH, _cellW - pixelW, _cellH - pixelH], _cellColor
                ] call EFUNC(gui,uiPanel);
            };
        };
    };
} forEach _blocks;
