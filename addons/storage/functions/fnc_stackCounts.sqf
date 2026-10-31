#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * How many each tile of a stackable class holds, once the cargo's total for its key is known and the
 * places say how the tiles stood last (fnc_getContents). The n-th record of a key is the n-th tile of that
 * key, so the answer is in the order of the records; a tile with no room left of it is simply not in it.
 *
 * Records with a count are the player's arrangement (a stack of five beside a stack of ten, fnc_opSplit);
 * the total comes from the cargo, which the engine, a script or another mod may have changed without the
 * places. So the two are reconciled, nothing is ever lost or doubled:
 *   - the total is below what the records say (items left without the window): the last tiles give up
 *     the difference first, a tile that reaches zero is gone;
 *   - the total is above (items came without the window): a record without a count takes up to a full
 *     stack of it, in order; what is still left tops up the last tile that has room, then opens new tiles
 *     of a full stack and a remainder.
 * Records without a count (a save from before stacks could be apart, a loadout) stand for "as many as the
 * cargo gives": with no count at all that is today's cut - full stacks first, then the remainder.
 *
 * The stack is the holder's (fnc_stackFor), so a record can carry more than a tile there may hold - the
 * stack multiplier of crates and vehicles went down, or a loadout's places came from a crate. Such a count is
 * cut to the stack like any other; the items it loses are part of the total that is still unplaced, and
 * they top up the last tile with room or open new tiles of full stacks and a remainder. Each step puts a
 * positive number of items somewhere, so it always ends.
 *
 * Arguments:
 * 0: Total in the cargo for this key <NUMBER>
 * 1: Largest stack in this holder (fnc_stackFor) <NUMBER>
 * 2: The count of each record of the key in order, -1 for a record without one <ARRAY of NUMBERs>
 *
 * Return Value:
 * The count of each tile, in order, none of them 0 - they add up to the total <ARRAY of NUMBERs>
 *
 * Example:
 * [6, 10, [5, 1]] call aio_storage_fnc_stackCounts;
 *
 * Public: No
 */

params [["_total", 0, [0]], ["_stack", 1, [0]], ["_given", [], [[]]]];

_stack = floor (_stack max 1);

if (_total <= 0) exitWith {[]};

private _counts = _given apply {
    if (_x isEqualType 0 && {_x >= 1}) then {floor (_x min _stack)} else {-1}
};

private _counted = 0;

{
    if (_x >= 0) then {_counted = _counted + _x};
} forEach _counts;

// Items left without us: the last counted tiles give them up first. Records without a count get nothing.
if (_counted > _total) then {
    private _cut = _counted - _total;

    for "_i" from (count _counts - 1) to 0 step -1 do {
        if (_cut <= 0) exitWith {};

        private _have = _counts select _i;

        if (_have > 0) then {
            private _gives = _cut min _have;

            _counts set [_i, _have - _gives];
            _cut = _cut - _gives;
        };
    };

    _counted = _total;
};

private _left = _total - _counted;

// The tiles whose record has no count take what is left, a full stack at most each.
{
    if (_x < 0) then {
        private _fill = _left min _stack;

        _counts set [_forEachIndex, _fill];
        _left = _left - _fill;
    };
} forEach _counts;

// What is still left tops up the last tile with room, then opens new tiles.
if (_left > 0) then {
    for "_i" from (count _counts - 1) to 0 step -1 do {
        private _have = _counts select _i;

        if (_have > 0 && {_have < _stack}) exitWith {
            private _adds = _left min (_stack - _have);

            _counts set [_i, _have + _adds];
            _left = _left - _adds;
        };
    };
};

while {_left > 0} do {
    _counts pushBack (_left min _stack);
    _left = _left - _stack;
};

_counts select {_x > 0}
