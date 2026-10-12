#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * How many of a class a container holds at its top level: items, magazines, weapons and backpacks,
 * compared without regard to case. What lies in a uniform, vest or backpack inside the container does not
 * count, and a weapon counts under its base class whatever is on it.
 *
 * The cargo commands add whatever they are given, so whoever adds something counts before and after to
 * know how much of it really arrived (fnc_addNew).
 *
 * Arguments:
 * 0: Container <OBJECT>
 * 1: Class <STRING>
 *
 * Return Value:
 * How many <NUMBER>
 *
 * Example:
 * [vestContainer player, "ACE_fieldDressing"] call einv_storage_fnc_countClass;
 *
 * Public: No
 */

params [["_container", objNull, [objNull]], ["_class", "", [""]]];

if (isNull _container || {_class isEqualTo ""}) exitWith {0};

private _key = toLowerANSI _class;
private _held = 0;

{
    _x params [["_classes", [], [[]]], ["_counts", [], [[]]]];

    {
        if (toLowerANSI _x isEqualTo _key) then {
            _held = _held + (_counts param [_forEachIndex, 0]);
        };
    } forEach _classes;
} forEach [getItemCargo _container, getWeaponCargo _container, getBackpackCargo _container];

_held + ({toLowerANSI (_x select 0) isEqualTo _key} count (magazinesAmmoCargo _container))
