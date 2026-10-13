#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Where the columns and rows of a canvas (grid=abbbbbc/abbbbbc/-bbbbb-, compartments with a pos of their
 * own) lie once its seams are opened up. Painted next to each other, two compartments would otherwise be
 * drawn as one shape with a notch, where the Blocks view shows two blocks with room between them. So
 * wherever two compartments meet - a boundary between two columns (or rows) with, in some row (column),
 * a cell of one on the one side and a cell of another on the other - the flow's gap between two blocks
 * (COMPARTMENT_GAP) goes in. A whole column boundary opens, not just where they meet: every compartment
 * keeps its place and its alignment with the others, and one that reaches over a seam (the ring of
 * grid=aaa/aba/aaa, around the cell inside it) is drawn as runs of cells with the gap between them - the
 * cell inside keeps a little room on every side. Two compartments touching only at a corner open nothing.
 *
 * Arguments:
 * 0: The canvas's compartments, [cols, rows, holes, pos] each (einv_storage_fnc_blocksFor) <ARRAY>
 * 1: Cell size [w, h] <ARRAY> (default: fnc_getCell's)
 *
 * Return Value:
 * [colX, rowY, width, height] <ARRAY>
 *   colX   - per column from the canvas's leftmost one, its left edge from the canvas's left edge
 *   rowY   - per row from the topmost one, its top edge from the canvas's top edge
 *   width, height - the canvas with its gaps
 *
 * Example:
 * ([_group, [_cellW, _cellH]] call einv_gui_fnc_canvasSeams) params ["_colX", "_rowY", "_width", "_height"];
 *
 * Public: No
 */

params ["_blocks", ["_cell", [], [[]]]];

if (_cell isEqualTo []) then {
    _cell = call FUNC(getCell);
};

_cell params ["_cellW", "_cellH"];

// The same gap as between two blocks of the flow (fnc_flowCompartments), so both read alike.
private _gapX = round (_cellW * COMPARTMENT_GAP / pixelW) * pixelW;
private _gapY = round (_cellH * COMPARTMENT_GAP / pixelH) * pixelH;

private _minX = selectMin (_blocks apply {(_x select 3) select 0});
private _minY = selectMin (_blocks apply {(_x select 3) select 1});
private _width = selectMax (_blocks apply {((_x select 3) select 0) + (_x select 0)}) - _minX;
private _height = selectMax (_blocks apply {((_x select 3) select 1) + (_x select 1)}) - _minY;

// Which compartment has each cell of the canvas, row by row: -1 for none.
private _owners = [];
_owners resize (_width * _height);
_owners = _owners apply {-1};

{
    _x params ["_cols", "_rows", ["_holes", []], "_pos"];

    private _left = (_pos select 0) - _minX;
    private _top = (_pos select 1) - _minY;
    private _block = _forEachIndex;

    for "_row" from 0 to (_rows - 1) do {
        for "_col" from 0 to (_cols - 1) do {
            if !((_row * _cols + _col) in _holes) then {
                _owners set [(_top + _row) * _width + _left + _col, _block];
            };
        };
    };
} forEach _blocks;

// A cell of one compartment next to a cell of another: an empty cell on either side is no seam.
private _fnc_meet = {
    params ["_one", "_other"];

    _one >= 0 && {_other >= 0} && {_one != _other}
};

private _colX = [0];

for "_col" from 1 to (_width - 1) do {
    private _seam = false;

    for "_row" from 0 to (_height - 1) do {
        if ([_owners select (_row * _width + _col - 1), _owners select (_row * _width + _col)] call _fnc_meet) exitWith {
            _seam = true;
        };
    };

    _colX pushBack ((_colX select (_col - 1)) + _cellW + ([0, _gapX] select _seam));
};

private _rowY = [0];

for "_row" from 1 to (_height - 1) do {
    private _seam = false;

    for "_col" from 0 to (_width - 1) do {
        if ([_owners select ((_row - 1) * _width + _col), _owners select (_row * _width + _col)] call _fnc_meet) exitWith {
            _seam = true;
        };
    };

    _rowY pushBack ((_rowY select (_row - 1)) + _cellH + ([0, _gapY] select _seam));
};

[_colX, _rowY, (_colX select (_width - 1)) + _cellW, (_rowY select (_height - 1)) + _cellH]
