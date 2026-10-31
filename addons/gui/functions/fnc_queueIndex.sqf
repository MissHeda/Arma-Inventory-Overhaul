#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Keeps the index of what waits for the hands (GVAR(handWaiting)): the sources of the queue's entries by their
 * cell, "col_row" -> [[holder, key, block], ...]. An entry that joins the queue is added (fnc_queueMoves), one that
 * leaves it is taken out (fnc_runQueue, fnc_cancelQueued) - so whether a tile waits is one look at its cell
 * (fnc_queueWaits) instead of a pass over the whole queue, which a long queue made slower with every key repeat
 * of the quick move key.
 *
 * Arguments:
 * 0: Entries of the hands' queue <ARRAY>
 * 1: Add them (true) or take them out (false) <BOOL>
 *
 * Return Value:
 * None
 *
 * Example:
 * [[_entry], true] call einv_gui_fnc_queueIndex;
 *
 * Public: No
 */

params [["_entries", [], [[]]], ["_add", true, [true]]];

private _index = GVAR(handWaiting);

{
    {
        _x params ["_holder", "_key", "_block", "_col", "_row"];

        private _at = format ["%1_%2", _col, _row];
        private _list = _index getOrDefault [_at, []];

        if (_add) then {
            if (_list isEqualTo []) then {
                _index set [_at, _list];
            };

            _list pushBack [_holder, _key, _block];
        } else {
            private _found = _list findIf {(_x select 0) isEqualTo _holder && {(_x select 1) isEqualTo _key} && {(_x select 2) isEqualTo _block}};

            if (_found >= 0) then {
                _list deleteAt _found;

                if (_list isEqualTo []) then {
                    _index deleteAt _at;
                };
            };
        };
    } forEach (_x getOrDefault ["sources", []]);
} forEach _entries;
