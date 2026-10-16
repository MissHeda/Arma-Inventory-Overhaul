#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Changes how many a stackable tile holds in its holder's places: the count of its record
 * ([key, col, row, w, h, block, rot, count]) - the cargo is not touched. A take of part of a stack, a
 * join onto a stack, a split and the Arsenal's removals use it, so the stack the player chose gives or
 * gains the items and no other (fnc_getContents reconciles the records with the cargo, last tiles first).
 * A count of 0 or less takes the record out. A tile with no record (it lies in the overflow row, or the
 * holder's places do not know it yet) is left to the reconciliation, which does the same sum in the
 * order of the tiles. On the holder's authority only, like fnc_setPlace; inside a phase through its
 * buffer.
 *
 * Arguments:
 * 0: Holder <OBJECT>
 * 1: Entry, with its "key" (or "class"), "block", "col", "row" - the tile as the layout put it <HASHMAP>
 * 2: How many it holds now <NUMBER>
 *
 * Return Value:
 * The record was found and changed <BOOL>
 *
 * Example:
 * [_crate, _entry, 4] call einv_storage_fnc_setCount;
 *
 * Public: No
 */

params [["_holder", objNull, [objNull]], ["_entry", createHashMap, [createHashMap]], ["_count", 1, [0]]];

if (isNull _holder) exitWith {false};

private _key = _entry getOrDefault ["key", ""];

if (_key isEqualTo "") then {
    _key = [_entry] call FUNC(entryKey);
};

if (_key isEqualTo "") exitWith {false};

private _records = ([_holder] call FUNC(readPlaces)) select 1;

private _index = _records findIf {
    _x isEqualType [] && {count _x >= 7}
    && {(_x select 0) isEqualTo _key}
    && {(_x select 1) isEqualTo (_entry getOrDefault ["col", -1])}
    && {(_x select 2) isEqualTo (_entry getOrDefault ["row", -1])}
    && {(_x select 5) isEqualTo (_entry getOrDefault ["block", -1])}
};

if (_index < 0) exitWith {false};

if (_count < 1) then {
    _records deleteAt _index;
} else {
    _records set [_index, ((_records select _index) select [0, 7]) + [floor _count]];
};

[_holder, _records] call FUNC(setRecords);

true
