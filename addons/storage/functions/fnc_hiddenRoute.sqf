#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether a class put into a container belongs in the unit's hidden holder rather than in the cargo (Strict
 * mode, fnc_addPayload, fnc_opStrict): the container is one of a unit's uniform, vest or backpack
 * (fnc_getOwner), its setting is Strict (fnc_useMode), the holder is in force for the unit
 * (fnc_hiddenActive), the class is of a kind the settings limit and not whitelisted for that container
 * (fnc_useState is "blocked") - and the holder's list of that kind, when it has anything, was taken out of
 * this very container: one that still holds the things of a container swapped meanwhile is first settled by
 * fnc_opStrict, so nothing is filed under the wrong container.
 *
 * Costs one variable read while no setting is on Strict.
 *
 * Arguments:
 * 0: Container <OBJECT>
 * 1: Class <STRING>
 *
 * Return Value:
 * Into the holder <BOOL>
 *
 * Example:
 * [backpackContainer player, "HandGrenade"] call aio_storage_fnc_hiddenRoute;
 *
 * Public: No
 */

params [["_container", objNull, [objNull]], ["_class", "", [""]]];

if (!(missionNamespace getVariable [QGVAR(strictActive), false]) || {isNull _container} || {_class isEqualTo ""}) exitWith {false};

([_container] call FUNC(getOwner)) params ["_unit", "_kindName"];

if (_kindName isEqualTo "" || {([_kindName] call FUNC(useMode)) isNotEqualTo USE_STRICT}) exitWith {false};
if !([_unit] call FUNC(hiddenActive)) exitWith {false};
if (([_class, _kindName] call FUNC(useState)) isNotEqualTo "blocked") exitWith {false};

([_unit] call FUNC(hiddenLists)) params ["_lists", "_containers"];

private _index = USE_KINDS find _kindName;

(_lists select _index) isEqualTo [] || {(_containers select _index) isEqualTo _container}
