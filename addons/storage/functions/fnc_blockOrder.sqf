#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The order a first fit looks through the compartments in for one item: the compartments whose category lock
 * (the categories a compartment accepts, grid=2x2:ammo) includes one of the item's categories come first - magazines
 * into magazine slots - and the unrestricted compartments after them, each group in the compartments' own order. A
 * compartment that refuses the item (fnc_blockMode) is left out. The layout, op put, move and split (fnc_findSpots)
 * and the plan all go through this, so the owner and every client agree on where an item without a cell lands.
 *
 * Arguments:
 * 0: The compartments, as fnc_getLayout lists them <ARRAY>
 * 1: The item's categories, "groups" of aio_items_fnc_getInfo <ARRAY of STRING>
 * 2: A compartment to try before all others (unless it refuses the item), -1 for none <NUMBER> (default: -1)
 *
 * Return Value:
 * Indices of the compartments, in the order to look <ARRAY of NUMBER>
 *
 * Example:
 * [[[6, 4], [2, 2, [], [], ["ammo"]]], ["ammo"]] call aio_storage_fnc_blockOrder; // [1, 0]
 *
 * Public: No
 */

params [["_blocks", [], [[]]], ["_groups", [], [[]]], ["_first", -1, [0]]];

private _preferred = [];
private _others = [];

{
    // Only a compartment with attributes (a fifth element) can refuse, prefer or be a slot.
    if (count _x > 4) then {
        private _mode = [_x, _groups] call FUNC(blockMode);

        if (_mode < 0) then {continue};

        if (_forEachIndex != _first && {(_x select 4) isNotEqualTo []}) then {
            _preferred pushBack _forEachIndex;
            continue;
        };
    };

    _others pushBack _forEachIndex;
} forEach _blocks;

private _order = _preferred + _others;

// The one asked for goes first, unless it refuses the item.
if (_first in _order) then {
    _order = [_first] + (_order - [_first]);
};

_order
