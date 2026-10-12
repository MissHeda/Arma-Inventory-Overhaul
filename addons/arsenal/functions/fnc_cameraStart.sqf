#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Starts the orbit camera on the unit: a camera of its own, no helper object, looking at him from the
 * default distance and direction - or the ones of the last time this mission - with a short fade in from
 * black. The curator's camera position is kept when Zeus is open. At night a weak light comes along, in the
 * Eden editor ACE's stronger one (fnc_edenStart) is there instead.
 *
 * The pose is set every frame (fnc_cameraFrame) from GVAR(cameraPosition): [distance, direction, pitch,
 * target], the target a point of the unit's model space. No object is made for it - ACE's helper is a
 * network object in multiplayer, made on every open.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * The camera <OBJECT>
 *
 * Example:
 * [_unit] call einv_arsenal_fnc_cameraStart;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

// The curator's camera stays where it was: it is given back there (fnc_onUnload).
private _curator = curatorCamera;

GVAR(curatorCameraData) = if (isNull _curator) then {
    []
} else {
    [getPosASL _curator, [vectorDir _curator, vectorUp _curator]]
};

call FUNC(cameraStop);

private _camera = "camera" camCreate (getPosATL _unit);
_camera cameraEffect ["internal", "back"];
_camera camPrepareFocus [-1, -1];
_camera camPrepareFov ARSENAL_FOV;
_camera camCommitPrepared 0;

showCinemaBorder false;

GVAR(camera) = _camera;
GVAR(cameraDrag) = [];
GVAR(cameraClick) = [-1, [0, 0]];

// Not closer than the soldier fits the free middle (fnc_cameraRect sets it with the first build).
private _position = GVAR(cameraPosition);
_position set [0, (_position select 0) max GVAR(cameraMinDistance)];

// A light follows the camera at night, so the soldier is not a black shape; the editor brings its own.
if (!is3DEN && {sunOrMoon < 0.5}) then {
    private _light = "#lightpoint" createVehicleLocal [0, 0, 0];
    _light setLightBrightness 0.2;
    _light setLightColor [1, 0.95, 0.88];
    _light setLightAmbient [1, 0.95, 0.88];

    GVAR(cameraLight) = _light;
};

// In its place before the first frame draws, and out of black.
[getMousePosition, diag_tickTime] call FUNC(cameraFrame);

if (!is3DEN) then {
    cutText ["", "BLACK IN", 0.5];
};

_camera
