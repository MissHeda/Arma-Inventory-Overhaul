#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * An entry as a plain array, to be sent over the network in a transaction's ops (fnc_request): a
 * tile's entry also holds its controls, which cannot travel. With the compartment it lies in and the
 * key of its record (fnc_entryKey), the machine that runs the op finds the very tile (fnc_findEntry).
 *
 * Arguments:
 * 0: Entry <HASHMAP>
 *
 * Return Value:
 * [class, count, ammo, capacity, attachments, container, col, row, w, h, block, key] <ARRAY>
 *
 * Example:
 * [_entry] call aio_storage_fnc_entryToArray;
 *
 * Public: No
 */

params [["_entry", createHashMap, [createHashMap]]];

[
    _entry getOrDefault ["class", ""],
    _entry getOrDefault ["count", 1],
    _entry getOrDefault ["ammo", 0],
    _entry getOrDefault ["capacity", 0],
    _entry getOrDefault ["attachments", []],
    _entry getOrDefault ["container", objNull],
    _entry getOrDefault ["col", -1],
    _entry getOrDefault ["row", -1],
    _entry getOrDefault ["w", 1],
    _entry getOrDefault ["h", 1],
    _entry getOrDefault ["block", -1],
    _entry getOrDefault ["key", ""]
]
