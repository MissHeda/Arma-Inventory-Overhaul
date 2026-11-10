#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Makes the hidden box a piece of furniture holds its loot in (fnc_search): an empty crate where the furniture is,
 * hidden, still and unbreakable, named after the furniture in the window (aio_name). Never in the loot column's
 * list of what lies around (hidden, and aio_nearby false). Handed to Ravage's cleanup as its piles are
 * (loot_to_clean, on the server).
 *
 * Arguments:
 * 0: The furniture <OBJECT>
 *
 * Return Value:
 * The box <OBJECT>
 *
 * Example:
 * [cursorObject] call aio_compat_ravage_fnc_createBox;
 *
 * Public: No
 */

params [["_object", objNull, [objNull]]];

private _box = createVehicle [BOX_CLASS, [0, 0, 0], [], 0, "CAN_COLLIDE"];

_box hideObject true;
_box enableSimulation false;
_box allowDamage false;
_box setPosASL getPosASL _object;

clearItemCargoGlobal _box;
clearWeaponCargoGlobal _box;
clearMagazineCargoGlobal _box;
clearBackpackCargoGlobal _box;

private _name = getText (configOf _object >> "displayName");

if (_name isEqualTo "") then {
    _name = LLSTRING(Furniture);
};

_box setVariable [QGVARMAIN(name), _name, true];
_box setVariable [QGVAR(box), true, true];
_box setVariable ["aio_nearby", false, true];

[_box, true] remoteExec ["hideObjectGlobal", 2];
[_box, false] remoteExec ["enableSimulationGlobal", 2];
[_box, {if (!isNil "loot_to_clean") then {loot_to_clean pushBack _this}}] remoteExec ["BIS_fnc_call", 2];

_box
