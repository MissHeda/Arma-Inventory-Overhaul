#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Marks the cells an item takes as taken: every cell of its box but its own holes (a shaped item,
 * size=xx/x-, einv_items_fnc_footprintAs), so the corner an L leaves open stays free for something
 * else. The way back of fnc_cellsFree, on the same rows of booleans; rows are added as needed, and
 * cells past the compartment's side are left alone.
 *
 * Arguments:
 * 0: One compartment's rows of booleans, true where taken - changed in place <ARRAY>
 * 1: The compartment's columns <NUMBER>
 * 2: Column <NUMBER>
 * 3: Row <NUMBER>
 * 4: Width as it lies <NUMBER>
 * 5: Height as it lies <NUMBER>
 * 6: Its holes as it lies, indices row * width + col <ARRAY> (default: [])
 *
 * Return Value:
 * None
 *
 * Example:
 * [_taken select 0, 8, 2, 1, 2, 2, [3]] call einv_storage_fnc_takeCells;
 *
 * Public: No
 */

params ["_grid", "_cols", "_col", "_row", "_w", "_h", ["_holes", []]];

while {count _grid < _row + _h} do {
    private _line = [];

    for "_i" from 1 to _cols do {
        _line pushBack false;
    };

    _grid pushBack _line;
};

for "_r" from (_row max 0) to (_row + _h - 1) do {
    private _line = _grid select _r;
    private _base = (_r - _row) * _w - _col;

    for "_c" from (_col max 0) to ((_col + _w - 1) min (_cols - 1)) do {
        if !((_base + _c) in _holes) then {
            _line set [_c, true];
        };
    };
};
