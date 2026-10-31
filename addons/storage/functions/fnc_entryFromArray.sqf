#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * An entry back from its array (fnc_entryToArray). An array of the older, shorter shape comes back
 * without a compartment (-1) and without a key - fnc_getLayout and fnc_setPlace work one out
 * (fnc_entryKey).
 *
 * Arguments:
 * 0: [class, count, ammo, capacity, attachments, container, col, row, w, h, block, key] <ARRAY>
 *
 * Return Value:
 * Entry <HASHMAP>
 *
 * Example:
 * [_array] call aio_storage_fnc_entryFromArray;
 *
 * Public: No
 */

params [["_array", [], [[]]]];

_array params [
    ["_class", ""], ["_count", 1], ["_ammo", 0], ["_capacity", 0], ["_attachments", []],
    ["_container", objNull], ["_col", -1], ["_row", -1], ["_w", 1], ["_h", 1], ["_block", -1], ["_key", ""]
];

private _entry = createHashMapFromArray [
    ["class", _class],
    ["count", _count],
    ["ammo", _ammo],
    ["capacity", _capacity],
    ["attachments", _attachments],
    ["container", _container],
    ["col", _col],
    ["row", _row],
    ["w", _w],
    ["h", _h],
    ["block", _block]
];

// No key, no "key": whoever needs one works it out (fnc_entryKey), never takes "" for one.
if (_key isEqualType "" && {_key isNotEqualTo ""}) then {
    _entry set ["key", _key];
};

_entry
