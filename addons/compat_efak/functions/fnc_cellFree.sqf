#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether a tile may lie on a cell of a kit's grid as the kit lies now - for the kit ops, where they
 * write (fnc_putIntoKit, fnc_opKitPlace). Inside the compartment it names: a kit's own grid's
 * (fnc_kitBlocks) - its width and height, none of the tile's cells on one of the compartment's holes -,
 * or the one open compartment of a kit whose room is that mod's capacity, STORAGE_COLS wide and as long
 * as it needs. And free: no other tile of that compartment on one of its cells (a shaped item takes only
 * its own, aio_storage_fnc_overlaps).
 *
 * Arguments:
 * 0: Kit class <STRING>
 * 1: The kit's tiles, laid out (fnc_getEntries with "laid out") <ARRAY of HASHMAPs>
 * 2: Cell [col, row, compartment, w, h] - w and h as it would lie <ARRAY>
 * 3: The cells of its box the tile does not take, as it would lie (aio_items_fnc_footprintAs) <ARRAY>
 *    (default: [])
 * 4: Index of a tile among them that does not count - the one being moved <NUMBER> (default: -1)
 *
 * Return Value:
 * It may lie there <BOOL>
 *
 * Example:
 * ["efak_IFAK_7", _view, [2, 0, 0, 1, 1]] call aio_compat_efak_fnc_cellFree;
 *
 * Public: No
 */

params [
    ["_kit", "", [""]], ["_view", [], [[]]], ["_cell", [], [[]]], ["_holes", [], [[]]], ["_skip", -1, [0]]
];

_cell params [["_col", -1, [0]], ["_row", -1, [0]], ["_block", 0, [0]], ["_w", 1, [0]], ["_h", 1, [0]]];

if (_col < 0 || {_row < 0} || {_w < 1} || {_h < 1} || {_block < 0}) exitWith {false};

private _blocks = [_kit] call FUNC(kitBlocks);
private _open = _blocks isEqualTo [];

if (_open && {_block != 0}) exitWith {false};

// The open grid is one compartment, as wide as every grid and as long as it needs.
private _compartment = ([[[STORAGE_COLS, 1e6, []]], _blocks] select !_open) param [_block, []];

_compartment params [["_cols", 0], ["_rows", 0], ["_compartmentHoles", []]];

// A single slot takes the tile whole, whatever its size (aio_storage_fnc_slotOf): the slot is what has to be free, as the
// kit's layout will lay the tile there.
if (_compartment param [5, false]) then {
    ([_compartment] call EFUNC(storage,slotOf)) params ["_slotCol", "_slotRow", "_slotW", "_slotH", "_slotHoles"];

    _col = _slotCol;
    _row = _slotRow;
    _w = _slotW;
    _h = _slotH;
    _holes = _slotHoles;
};

if (_col + _w > _cols || {_row + _h > _rows}) exitWith {false};

// None of its own cells on a hole of a shaped compartment.
private _onHole = false;

if (_compartmentHoles isNotEqualTo []) then {
    for "_r" from 0 to (_h - 1) do {
        for "_c" from 0 to (_w - 1) do {
            if (!((_r * _w + _c) in _holes) && {((_row + _r) * _cols + _col + _c) in _compartmentHoles}) exitWith {
                _onHole = true;
            };
        };

        if (_onHole) exitWith {};
    };
};

if (_onHole) exitWith {false};

private _mask = [_col, _row, _w, _h, _holes];
private _free = true;

{
    if (
        _forEachIndex != _skip
        && {!(_x getOrDefault ["overflow", false])}
        && {(_x getOrDefault ["block", -1]) == _block}
        && {[_mask, [_x get "col", _x get "row", _x get "w", _x get "h", _x getOrDefault ["holes", []]]] call EFUNC(storage,overlaps)}
    ) exitWith {
        _free = false;
    };
} forEach _view;

_free
