#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The cells an item takes as it lies: its footprint upright, or turned a quarter clockwise
 * (fnc_turnMask). Where something lies says only which way round ([key, col, row, w, h, block, rot],
 * aio_storage_fnc_readPlaces; rot 1 is turned) - so the holes of a shaped item (size=xx/x-) always come
 * from its class at use time, the same on every machine, and only that one number is stored and synced.
 * Two ways round only: upright and turned, never upside down.
 *
 * Arguments:
 * 0: Class name, or what fnc_getInfo gives for it <STRING or HASHMAP>
 * 1: It lies turned: true or rot 1 <BOOL or NUMBER> (default: false)
 *
 * Return Value:
 * [w, h, holes] as it lies, holes the indices row * w + col, [] for a full rectangle - shared, do not
 * change it <ARRAY>
 *
 * Example:
 * ["My_Pistol_L", 1] call aio_items_fnc_footprintAs;
 *
 * Public: Yes
 */

params [["_item", "", ["", createHashMap]], ["_turned", false, [false, 0]]];

private _info = if (_item isEqualType "") then {[_item] call FUNC(getInfo)} else {_item};
private _footprint = _info getOrDefault ["footprint", [1, 1, []]];

if (_turned isEqualTo true || {_turned isEqualTo 1}) exitWith {_info getOrDefault ["footprintTurned", _footprint]};

_footprint
