#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * HALs' HALs_store_fnc_canAddItem (Antistasi's trader: how many of a purchase go into the chosen container, asked by
 * the server before it adds them): that mod's answer from the container's load, made no larger than what the grid has
 * room for (fnc_gridRoom) - so the trader no longer sells into a vest the grid cannot hold, where it would have fallen
 * to the ground. Antistasi's own file answers first (fnc_patched).
 *
 * Arguments:
 * As HALs_store_fnc_canAddItem: [container, class, count, find the most]
 *
 * Return Value:
 * As HALs_store_fnc_canAddItem: whether they all fit <BOOL>, or how many do <NUMBER>
 *
 * Public: No
 */

params [["_container", objNull, [objNull]], ["_class", "", [""]], ["_count", 1, [1]], ["_findMax", false, [false]]];

private _answer = _this call (["canAddItem", A3A_FILE_CANADDITEM, []] call FUNC(patched));

if (isNil "_answer") exitWith {[false, 0] select _findMax};

private _room = [_container, _class, _count] call FUNC(gridRoom);

if (_room < 0) exitWith {_answer};

if (_findMax) exitWith {
    if (_answer isEqualType 0) then {_answer min _room} else {0}
};

_answer isEqualTo true && {_count <= _room}
