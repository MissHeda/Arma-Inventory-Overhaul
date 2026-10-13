#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Op "place": moves one tile to another cell of the same holder - the tile with that key at its place
 * (fnc_findEntry, exact), the cell inside the holder and free but for the tile itself, else "Taken" and
 * nothing changes. One tile of op "placeMany".
 *
 * Extra: [cell, false].
 *
 * Arguments:
 * 0: Args, [holder, entry array, cell [col, row, block, w, h]] <ARRAY>
 * 1: Context - "requester", "where", "txId", "root", "settlement" (einv_storage_fnc_execute) <HASHMAP>
 *
 * Return Value:
 * [status, produced, extra] <ARRAY>
 *   status - "" done, else why not ("Gone", "Taken", "NoRoom", "NotLocal", "Moved",
 *     "IntoItself", "OutOfReach", "Bounced", "Skipped", "Failed", a guard's reason or a reason already
 *     in words)
 *   produced - the payloads it handed on, each consumed by a later op or settled
 *     (einv_storage_fnc_settle)
 *   extra - what else it tells, [] for nothing
 *
 * Example:
 * [[cursorObject, _entryArray, [2, 0, 0, 1, 2]], _context] call einv_storage_fnc_opPlace;
 *
 * Public: No
 */

params [["_args", [], [[]]], ["_context", createHashMap, [createHashMap]]];

_args params [["_holder", objNull, [objNull, ""]], ["_entryArray", [], [[]]], ["_cell", [], [[]]]];

private _result = [[_holder, [[_entryArray, _cell]]], _context] call FUNC(opPlaceMany);

if ((_result select 0) isEqualTo "") then {
    _result set [2, [_cell, false]];
};

_result
