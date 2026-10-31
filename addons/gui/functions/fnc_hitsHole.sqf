#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether a span of cells on a grid covers one of its holes - the cells a shaped compartment does not
 * have (aio_items_fnc_parseGrid, "xxx/x-x"; fnc_createGrid keeps them as "holes"). The mouse finds no
 * cell on a hole (fnc_screenToCell), and a footprint that reaches over one is red (fnc_updateDrag,
 * fnc_groupMode), as the storage side never puts anything there (aio_storage_fnc_seedTaken). A shaped
 * item's own holes (size=xx/x-) may lie over the grid's: only a grid hole under one of its cells counts.
 *
 * Arguments:
 * 0: Grid, see fnc_createGrid <HASHMAP>
 * 1: Column <NUMBER>
 * 2: Row <NUMBER>
 * 3: Width in cells <NUMBER> (default: 1)
 * 4: Height in cells <NUMBER> (default: 1)
 * 5: The item's own holes as it lies, indices row * width + col <ARRAY> (default: [])
 *
 * Return Value:
 * A hole lies in the span <BOOL>
 *
 * Example:
 * [_grid, 2, 0, 1, 2] call aio_gui_fnc_hitsHole;
 *
 * Public: No
 */

params ["_grid", "_col", "_row", ["_w", 1], ["_h", 1], ["_own", []]];

private _holes = _grid getOrDefault ["holes", []];

if (_holes isEqualTo []) exitWith {false};

private _cols = _grid get "cols";

_holes findIf {
    private _holeRow = floor (_x / _cols);
    private _holeCol = _x mod _cols;

    _holeCol >= _col && {_holeCol < _col + _w} && {_holeRow >= _row} && {_holeRow < _row + _h}
    && {!(((_holeRow - _row) * _w + _holeCol - _col) in _own)}
} >= 0
