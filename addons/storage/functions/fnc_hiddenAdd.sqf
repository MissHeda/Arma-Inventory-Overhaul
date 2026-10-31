#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Adds to one list of a hidden holder (fnc_hiddenLists), in place: the entry of that class with those rounds
 * grows by the count, or a new one is appended. The rounds are -1 for an item that is no magazine
 * (fnc_hiddenAmmo).
 *
 * Arguments:
 * 0: List, [[class, count, rounds], ...] - changed in place <ARRAY>
 * 1: Class <STRING>
 * 2: Count <NUMBER> (default: 1)
 * 3: Rounds, -1 for an item <NUMBER> (default: -1)
 *
 * Return Value:
 * None
 *
 * Example:
 * [_list, "HandGrenade", 2, 1] call einv_storage_fnc_hiddenAdd;
 *
 * Public: No
 */

params [["_list", [], [[]]], ["_class", "", [""]], ["_count", 1, [0]], ["_ammo", -1, [0]]];

if (_class isEqualTo "" || {_count < 1}) exitWith {};

private _key = toLowerANSI _class;
private _at = _list findIf {toLowerANSI (_x select 0) isEqualTo _key && {(_x select 2) == _ammo}};

if (_at < 0) exitWith {
    _list pushBack [_class, _count, _ammo];
};

private _entry = _list select _at;

_entry set [1, (_entry select 1) + _count];
