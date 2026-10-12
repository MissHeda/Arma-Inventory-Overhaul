#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The Eden editor's part of the session end: the original is shown again; with exit code 1 (Apply) the
 * copy's loadout is put on every selected unit and saved, with 2 nothing changes. Light and copy are
 * deleted, the editor's camera, interface and vision mode come back.
 *
 * Arguments:
 * 0: Exit code - 1 applies, 2 discards <NUMBER> (default: 2)
 *
 * Return Value:
 * None
 *
 * Example:
 * [1] call einv_arsenal_fnc_edenEnd;
 *
 * Public: No
 */

params [["_exitCode", 2, [0]]];

private _origin = GVAR(edenOrigin);
private _copy = GVAR(center);

if (isNull _origin) exitWith {};

private _vehicle = objectParent _origin;

if (!isNull _vehicle) then {
    _vehicle hideObject false;
};

_origin hideObject false;

// Apply: the copy's loadout - with whatever extended information mods keep in it - goes on every selected
// unit, and the editor is told to keep the inventory.
if (_exitCode == 1 && {!isNull _copy}) then {
    private _loadout = _copy call CBA_fnc_getLoadout;
    private _objects = get3DENSelected "object";

    {
        [_x, _loadout] call CBA_fnc_setLoadout;
    } forEach _objects;

    save3DENInventory _objects;
};

deleteVehicle GVAR(edenLight);
deleteVehicle _copy;

get3DENCamera cameraEffect ["Internal", "BACK"];
["ShowInterface", true] call BIS_fnc_3DENInterface;
GVAR(edenVision) call BIS_fnc_3DENVisionMode;

GVAR(edenOrigin) = objNull;
GVAR(edenLight) = objNull;
GVAR(edenVision) = -1;
