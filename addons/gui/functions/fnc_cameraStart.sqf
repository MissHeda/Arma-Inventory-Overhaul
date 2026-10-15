#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Shows the player's soldier behind the window: a local camera in front of it, facing it at chest
 * height, turned so the soldier stands in the middle of the look's free space rather than of the
 * screen. At night a weak light comes along, so the soldier is not a black shape.
 *
 * Only on foot - in a vehicle there is no room in front of the soldier, and the window keeps the
 * player's own view. fnc_cameraStop gives the view back; fnc_onUnload makes sure it always does.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Where the soldier should stand, [x, y, w, h] on the screen <ARRAY>
 *
 * Return Value:
 * Camera started <BOOL>
 *
 * Example:
 * [player, [0.3, 0.1, 0.4, 0.8]] call einv_gui_fnc_cameraStart;
 *
 * Public: No
 */

params ["_unit", "_rect"];

call FUNC(cameraStop);

if (isNull _unit || {!isNull objectParent _unit} || {count _rect != 4}) exitWith {false};

_rect params ["_rectX", "_rectY", "_rectW", "_rectH"];

// The chest from the soldier's skeleton, so the camera finds it crouched or prone as well.
private _chest = _unit selectionPosition "spine3";

if (_chest isEqualTo [0, 0, 0]) then {
    _chest = [0, 0, CAMERA_CHEST_Z];
};

_chest params ["_chestX", "_chestY", "_chestZ"];

// In front of the soldier, which looks along its model's y axis. A wall in between pulls the camera in
// to just before the wall, rather than showing the wall.
private _chestASL = _unit modelToWorldVisualWorld _chest;
private _distance = CAMERA_DISTANCE;
private _hits = lineIntersectsSurfaces [_chestASL, _unit modelToWorldVisualWorld [_chestX, _chestY + _distance, _chestZ], _unit, objNull, true, 1];

if (_hits isNotEqualTo []) then {
    _distance = ((_chestASL vectorDistance ((_hits select 0) select 0)) - CAMERA_WALL_GAP) max CAMERA_MIN_DISTANCE;
};

// The soldier lands in the middle of the rectangle when the camera aims beside the chest by as much as
// the rectangle's centre lies off the screen's. At the soldier's distance one pixel spans this many
// metres - across as down, pixels being square. Aiming to the soldier's right puts the soldier right of
// the middle, aiming higher puts it lower.
private _metresPerPixel = 2 * _distance * CAMERA_FOV * CAMERA_FOV_SCALE / (safezoneH / pixelH);
private _side = ((_rectX + _rectW / 2) - (safezoneX + safezoneW / 2)) / pixelW * _metresPerPixel;
private _rise = ((_rectY + _rectH / 2) - (safezoneY + safezoneH / 2)) / pixelH * _metresPerPixel;

private _camera = "camera" camCreate (_unit modelToWorldVisual [_chestX, _chestY + _distance, _chestZ]);
_camera cameraEffect ["internal", "back"];
showCinemaBorder false;
_camera camSetTarget (_unit modelToWorldVisual [_chestX + _side, _chestY, _chestZ + _rise]);
_camera camSetFov CAMERA_FOV;
_camera camCommit 0;

GVAR(camera) = _camera;

// Whom it frames and where: a build keeps a camera that still frames the same (fnc_build).
GVAR(cameraFor) = [_unit, _rect];

// A light point shines all around, so "aimed at the soldier" means: between the camera and the
// soldier, a little above the chest. Local - nobody else sees it.
if (sunOrMoon < CAMERA_LIGHT_SUN) then {
    private _light = "#lightpoint" createVehicleLocal [0, 0, 0];
    _light setPosASL (_unit modelToWorldVisualWorld [_chestX, _chestY + _distance * 0.6, _chestZ + 0.4]);
    _light setLightBrightness CAMERA_LIGHT_BRIGHTNESS;
    _light setLightColor [1, 0.95, 0.88];
    _light setLightAmbient [1, 0.95, 0.88];

    GVAR(cameraLight) = _light;
};

true
