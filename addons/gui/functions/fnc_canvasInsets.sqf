#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Where the compartments of a canvas (grid=abbbbbc/abbbbbc/-bbbbb-, compartments with a pos of their own)
 * draw their edges in from their cells. Painted next to each other, two compartments would otherwise read
 * as one shape with a notch, where the Blocks view shows two blocks with room between them. So every cell
 * side that borders a cell of another compartment is drawn in by half the flow's gap between two blocks
 * (COMPARTMENT_GAP), and the two halves of a seam add up to exactly that gap. Only that side: a side on a
 * hole, on the canvas's edge or on a cell of the same compartment stays where it is, so one compartment is
 * one whole space however it is cut around - the middle of grid=abbbbbc/abbbbbc stays one block, though
 * its neighbours on the left and right have a seam between their own two halves. Every cell keeps its
 * place at the plain pitch: only what is drawn on it shrinks (fnc_createGrid, fnc_spanRect).
 *
 * Arguments:
 * 0: The canvas's compartments, [cols, rows, holes, pos] each (einv_storage_fnc_blocksFor) <ARRAY>
 * 1: Cell size [w, h] <ARRAY> (default: fnc_getCell's)
 *
 * Return Value:
 * Per compartment, per cell row * cols + col, [left, top, right, bottom] - the screen width or height each
 * side is drawn in by; [] for a compartment that borders no other <ARRAY>
 *
 * Example:
 * private _insets = [_group, [_cellW, _cellH]] call einv_gui_fnc_canvasInsets;
 *
 * Public: No
 */

params ["_blocks", ["_cell", [], [[]]]];

if (_cell isEqualTo []) then {
    _cell = call FUNC(getCell);
};

_cell params ["_cellW", "_cellH"];

// The same gap as between two blocks of the flow (fnc_flowCompartments), so both read alike: the cell on
// the left (above) of a seam gives up the smaller half, the one on the right (below) the rest.
private _gapX = round (_cellW * COMPARTMENT_GAP / pixelW);
private _gapY = round (_cellH * COMPARTMENT_GAP / pixelH);
private _rightIn = floor (_gapX / 2) * pixelW;
private _leftIn = _gapX * pixelW - _rightIn;
private _bottomIn = floor (_gapY / 2) * pixelH;
private _topIn = _gapY * pixelH - _bottomIn;

// Which compartment has the cell at [x, y] of the canvas.
private _owners = createHashMap;

{
    _x params ["_cols", "_rows", ["_holes", []], "_pos"];

    for "_row" from 0 to (_rows - 1) do {
        for "_col" from 0 to (_cols - 1) do {
            if !((_row * _cols + _col) in _holes) then {
                _owners set [[(_pos select 0) + _col, (_pos select 1) + _row], _forEachIndex];
            };
        };
    };
} forEach _blocks;

private _result = [];

{
    _x params ["_cols", "_rows", ["_holes", []], "_pos"];
    _pos params ["_posX", "_posY"];

    private _block = _forEachIndex;
    private _touches = false;

    // Another compartment's cell there: an empty one or the canvas's edge is no seam.
    private _fnc_other = {
        private _owner = _owners getOrDefault [_this, _block];

        _owner != _block
    };

    private _insets = [];

    for "_row" from 0 to (_rows - 1) do {
        for "_col" from 0 to (_cols - 1) do {
            if ((_row * _cols + _col) in _holes) then {
                _insets pushBack [0, 0, 0, 0];
                continue;
            };

            private _canvasX = _posX + _col;
            private _canvasY = _posY + _row;
            private _sides = [
                [0, _leftIn] select ([_canvasX - 1, _canvasY] call _fnc_other),
                [0, _topIn] select ([_canvasX, _canvasY - 1] call _fnc_other),
                [0, _rightIn] select ([_canvasX + 1, _canvasY] call _fnc_other),
                [0, _bottomIn] select ([_canvasX, _canvasY + 1] call _fnc_other)
            ];

            _touches = _touches || {_sides findIf {_x > 0} >= 0};
            _insets pushBack _sides;
        };
    };

    _result pushBack ([[], _insets] select _touches);
} forEach _blocks;

_result
