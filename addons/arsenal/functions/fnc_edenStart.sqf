#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The Eden editor's part of the session start, ACE's block written again with ACE's functions: the entity
 * is hidden, a copy of it - the same type, place, direction and loadout - stands in its place with no
 * simulation, a light under it, the editor's interface and map out of the way. The copy becomes the unit
 * the window dresses.
 *
 * The entity is the session's unit when this runs (fnc_onLoad); the copy replaces it in the session after.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * The unit the window dresses <OBJECT>
 *
 * Example:
 * call einv_arsenal_fnc_edenStart;
 *
 * Public: No
 */

private _origin = GVAR(center);

GVAR(edenOrigin) = _origin;

// The original and the vehicle it sits in go out of sight, to come back at the end.
_origin hideObject true;

private _vehicle = objectParent _origin;

if (!isNull _vehicle) then {
    _vehicle hideObject true;
};

// A copy of it stands in its place: a man of the same type with the same loadout (extended, so the
// arrangement and whatever else mods keep with it comes along), not simulated.
private _position = position _origin;
private _copy = createAgent [typeOf _origin, _position, [], 0, "none"];

_copy setPosATL (getPosATL _origin);
_copy setDir (getDir _origin);
_copy switchMove (animationState _origin);
_copy switchAction "playerStand";
_copy enableSimulation false;

[_copy, _origin call CBA_fnc_getLoadout] call CBA_fnc_setLoadout;

// For night editing (the code of BIS_fnc_3DENFlashlight, as ACE writes it).
private _light = "#lightpoint" createVehicle _position;
_light setLightBrightness 1;
_light setLightAmbient [1, 1, 1];
_light setLightColor [0, 0, 0];
_light lightAttachObject [_origin, [0, 0, -7]];

GVAR(edenLight) = _light;

// The editor's own look: the vision mode it had is given back at the end, the interface and the map get out
// of the way.
GVAR(edenVision) = -2 call BIS_fnc_3DENVisionMode;
["ShowInterface", false] spawn BIS_fnc_3DENInterface;

if (get3DENActionState "toggleMap" > 0) then {
    do3DENAction "toggleMap";
};

_copy
