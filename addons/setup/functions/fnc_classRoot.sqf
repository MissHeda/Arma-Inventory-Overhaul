#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Which config root a class is in, looked for in the order the rules engine reads them (INDEX_ROOTS,
 * einv_items_fnc_getFacts): a class in two roots counts under the first.
 *
 * Arguments:
 * 0: Class <STRING>
 *
 * Return Value:
 * "CfgWeapons", "CfgMagazines", "CfgGlasses" or "CfgVehicles"; "" for a class no config knows <STRING>
 *
 * Example:
 * ["B_Carryall_blk"] call einv_setup_fnc_classRoot;
 *
 * Public: No
 */

params [["_class", "", [""]]];

private _found = "";

if (_class isEqualTo "") exitWith {_found};

{
    if (isClass (configFile >> _x >> _class)) exitWith {
        _found = _x;
    };
} forEach INDEX_ROOTS;

_found
