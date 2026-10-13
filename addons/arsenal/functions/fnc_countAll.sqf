#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * How many of each class a container holds, counted the way einv_storage_fnc_countClass counts one class:
 * items, weapons and backpacks by the cargo lists, magazines one by one.
 *
 * Arguments:
 * 0: Container <OBJECT>
 *
 * Return Value:
 * Lowercase class -> count <HASHMAP>
 *
 * Example:
 * [vestContainer player] call einv_arsenal_fnc_countAll;
 *
 * Public: No
 */

params [["_container", objNull, [objNull]]];

private _counts = createHashMap;

if (isNull _container) exitWith {_counts};

{
    _x params [["_classes", [], [[]]], ["_numbers", [], [[]]]];

    {
        private _key = toLowerANSI _x;
        _counts set [_key, (_counts getOrDefault [_key, 0]) + (_numbers param [_forEachIndex, 0])];
    } forEach _classes;
} forEach [getItemCargo _container, getWeaponCargo _container, getBackpackCargo _container];

{
    private _key = toLowerANSI (_x select 0);
    _counts set [_key, (_counts getOrDefault [_key, 0]) + 1];
} forEach (magazinesAmmoCargo _container);

_counts
