#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Where a cell of a grid lies from the grid's corner: a cell's pitch per column and row, or - on a
 * canvas's compartment with seams in it (fnc_canvasSeams) - the offsets the grid keeps ("colX", "rowY",
 * fnc_createGrid). A cell outside the grid, as a footprint sticking out of it has, lies a pitch on from
 * the last one, so it is still found the same way on either side.
 *
 * Arguments:
 * 0: Grid, see fnc_createGrid <HASHMAP>
 * 1: Column <NUMBER>
 * 2: Row <NUMBER>
 *
 * Return Value:
 * [x, y] from the grid's top left corner <ARRAY>
 *
 * Example:
 * [_grid, 3, 1] call einv_gui_fnc_cellOffset;
 *
 * Public: No
 */

params ["_grid", "_col", "_row"];

[
    [_grid getOrDefault ["colX", []], _col, _grid get "cellW"],
    [_grid getOrDefault ["rowY", []], _row, _grid get "cellH"]
] apply {
    _x params ["_offsets", "_index", "_pitch"];

    private _last = count _offsets - 1;

    switch (true) do {
        case (_last < 0 || {_index < 0}): {_index * _pitch};
        case (_index > _last): {(_offsets select _last) + (_index - _last) * _pitch};
        default {_offsets select _index};
    }
}
