#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The box around all cells of a canvas (fnc_uiCanvas), whether they touch or not: what the Items step's
 * across and down say, where it lays a new rectangle, and where the item's picture lies on the canvas.
 *
 * Arguments:
 * 0: Canvas, see fnc_canvasFromBlocks <HASHMAP>
 *
 * Return Value:
 * [col, row, cols, rows] - its top left place and its size; [0, 0, 0, 0] for a canvas without a cell <ARRAY>
 *
 * Example:
 * ([_canvas] call einv_setup_fnc_canvasBox) params ["_col", "_row", "_w", "_h"];
 *
 * Public: No
 */

params [["_canvas", createHashMap, [createHashMap]]];

private _cols = _canvas getOrDefault ["cols", 1];
private _minCol = 1e6;
private _maxCol = -1;
private _minRow = 1e6;
private _maxRow = -1;

{
    if (_x) then {
        private _col = _forEachIndex mod _cols;
        private _row = floor (_forEachIndex / _cols);

        _minCol = _minCol min _col;
        _maxCol = _maxCol max _col;
        _minRow = _minRow min _row;
        _maxRow = _maxRow max _row;
    };
} forEach (_canvas getOrDefault ["cells", []]);

if (_maxCol < 0) exitWith {[0, 0, 0, 0]};

[_minCol, _minRow, _maxCol - _minCol + 1, _maxRow - _minRow + 1]
