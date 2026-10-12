#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether a container has a free spot for an entry in one of its compartments - for moves that do not
 * say where (Ctrl+click, the context menu): laid out once more with the entry added, from the places
 * everyone shares (fnc_readPlaces) - nothing is kept. The ground, and a grid with no object of its own (a
 * kit, "kit:" + lowercase class), always have room: they grow.
 *
 * Arguments:
 * 0: Container, or the key of a grid with no object <OBJECT or STRING>
 * 1: Entry <HASHMAP>
 *
 * Return Value:
 * A spot is free <BOOL>
 *
 * Example:
 * [vestContainer player, _entry] call einv_storage_fnc_hasSpace;
 *
 * Public: No
 */

params [["_container", objNull, [objNull, ""]], ["_entry", createHashMap, [createHashMap]]];

// The type first: isNull fails on a key.
if (_container isEqualType "") exitWith {_container isNotEqualTo ""};
if (isNull _container) exitWith {false};
if (([_container] call FUNC(getBlocks)) isEqualTo []) exitWith {true};

private _probe = createHashMapFromArray [["class", _entry getOrDefault ["class", ""]], ["count", 1]];
private _entries = ([_container] call FUNC(getContents)) + [_probe];

[_container, _entries, false] call FUNC(getLayout);

!(_probe getOrDefault ["overflow", true])
