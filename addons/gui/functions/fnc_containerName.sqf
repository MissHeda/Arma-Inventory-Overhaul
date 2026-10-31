#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What a container is called in a menu: the uniform, vest or backpack it belongs to by that item's
 * name, the ground, or the crate or vehicle by its own.
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
