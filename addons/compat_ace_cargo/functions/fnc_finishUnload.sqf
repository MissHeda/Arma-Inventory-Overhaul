#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The time is up: ACE unloads the thing - with the call its own menu ends in, so the search for a place,
 * Zeus's lists, a UAV's crew, the event ace_cargoUnloaded and the carry after the unloading are ACE's
 * as always. The card is gone in the window, ACE's text tells it in the hint, and the crate sounds as it
 * lands.
 *
 * When ACE has the player carry or drag the thing now (ace_cargo_carryAfterUnload, ACE dragging loaded,
 * the thing not blocking it) the window closes, as ACE's menu closed before the carry started.
 *
 * Arguments:
 * 0: Vehicle or crate it was loaded in <OBJECT>
 * 1: The loaded thing - an object, or a class name <OBJECT or STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_vehicle, _crate] call einv_compat_ace_cargo_fnc_finishUnload;
 *
 * Public: No
 */

params [["_holder", objNull, [objNull]], ["_item", objNull, [objNull, ""]]];

["", false] call FUNC(stopUnload);

private _name = [_item, true] call ACEFUNC(cargo,getNameItem);
private _class = _item;

if (_item isEqualType objNull) then {
    _class = typeOf _item;
};

// ACE's own unload: place, Zeus, UAV crew, the event, carry after unloading.
if !([_item, _holder, ACE_player] call ACEFUNC(cargo,unloadItem)) exitWith {
    [[localize "STR_ACE_Cargo_UnloadingFailed", _name] call FUNC(aceText)] call EFUNC(gui,flashHint);
    [] call EFUNC(gui,requestRebuild);
};

if (_item isEqualType objNull) then {
    _item setVariable [QGVAR(openedFrom), nil];
};

["drop", _class] call EFUNC(gui,playSound);

private _display = uiNamespace getVariable [QEGVAR(gui,display), displayNull];

if (isNull _display) exitWith {};

// ACE now has the player carry or drag it: the window steps aside, as ACE's cargo menu closed before.
if (
    (missionNamespace getVariable [QACEGVAR(cargo,carryAfterUnload), true])
    && {isClass (configFile >> "CfgPatches" >> "ace_dragging")}
    && {getNumber (configFile >> "CfgVehicles" >> _class >> QACEGVAR(cargo,blockUnloadCarry)) == 0}
) exitWith {
    _display closeDisplay 2;
};

[_display] call EFUNC(gui,build);

// Written after the build: it makes the footer anew.
[[localize "STR_ACE_Cargo_UnloadedItem", _name, getText (configOf _holder >> "displayName")] call FUNC(aceText), "gain"] call EFUNC(gui,showHint);
