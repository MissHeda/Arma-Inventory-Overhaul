#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether a holder is a container or lies in it, at any depth. A uniform, vest or backpack cannot go into
 * itself or into anything lying in it (ops move and put, the window's footprint while dragging).
 *
 * Walked down from the container through the real cargo (everyContainer, three levels - as deep as the
 * engine nests), so neither tags nor marks need to have reached this machine. A holder that is no object
 * (a kit) never holds a uniform, vest or backpack: false.
 *
 * Arguments:
 * 0: Holder <OBJECT or STRING>
 * 1: Container <OBJECT>
 *
 * Return Value:
 * It is the container or lies in it <BOOL>
 *
 * Example:
 * [_vestInBackpack, backpackContainer player] call aio_storage_fnc_liesIn;
 *
 * Public: No
 */

params [["_holder", objNull, [objNull, ""]], ["_container", objNull, [objNull]]];

if (!(_holder isEqualType objNull) || {isNull _holder} || {isNull _container}) exitWith {false};
if (_holder isEqualTo _container) exitWith {true};

private _level = [_container];
private _found = false;

for "_depth" from 1 to 3 do {
    private _next = [];

    {
        private _parent = _x;

        _next append ((everyContainer _parent) apply {_x select 1});
    } forEach _level;

    if (_holder in _next) exitWith {_found = true};
    if (_next isEqualTo []) exitWith {};

    _level = _next;
};

_found
