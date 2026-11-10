#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What a container is called in a menu: the uniform, vest or backpack it belongs to by that item's
 * name, the ground, or the crate or vehicle by its own - or the name the object was given (aio_name).
 *
 * Arguments:
 * 0: Container <OBJECT>
 *
 * Return Value:
 * Name <STRING>
 *
 * Example:
 * [vestContainer player] call aio_gui_fnc_containerName;
 *
 * Public: No
 */

params ["_container"];

// A name the object was given (aio_name): a container a mod or mission put in for something that has none - Ravage's
// furniture (aio_compat_ravage_fnc_search).
private _named = _container getVariable [QGVARMAIN(name), ""];

if (_named isNotEqualTo "") exitWith {_named};

if ([_container] call EFUNC(storage,isGroundHolder)) exitWith {localize ELSTRING(storage,Ground)};

([_container] call EFUNC(storage,getOwner)) params ["_owner", "_slot"];

if (!isNull _owner) exitWith {
    private _class = switch (_slot) do {
        case "uniform": {uniform _owner};
        case "vest": {vest _owner};
        default {backpack _owner};
    };

    ([_class] call EFUNC(items,getInfo)) getOrDefault ["name", typeOf _container]
};

getText (configOf _container >> "displayName")
