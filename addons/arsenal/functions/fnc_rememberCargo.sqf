#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Notes what the uniform, vest or backpack open in the arsenal holds right now (fnc_getCargo), so the
 * next add can tell how many really arrived (fnc_onCargoChanged): the engine adds nothing that is too
 * heavy, and ACE raises its event all the same. Taken whenever the right panel is filled, after every
 * add or removal, after "Remove all" and after a whole loadout came in; nothing while another panel
 * is open.
 *
 * The container object is noted too: the arsenal makes a new one whenever it puts on another uniform,
 * vest or backpack, so a new one in the same panel means one was swapped.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call einv_arsenal_fnc_rememberCargo;
 *
 * Public: No
 */

private _center = missionNamespace getVariable [QACEGVAR(arsenal,center), objNull];

([_center] call FUNC(getCargo)) params [["_index", -1], ["_container", objNull], ["_items", []]];

GVAR(snapshot) = [[], [_index, _container, _items]] select (_index >= 0);
