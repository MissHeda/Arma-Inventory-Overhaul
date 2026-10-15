#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Gives the player's own view back and removes the camera and its light (fnc_cameraStart). Safe to
 * call when there is none.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call einv_gui_fnc_cameraStop;
 *
 * Public: No
 */

if (!isNull GVAR(camera)) then {
    GVAR(camera) cameraEffect ["terminate", "back"];
    camDestroy GVAR(camera);
};

if (!isNull GVAR(cameraLight)) then {
    deleteVehicle GVAR(cameraLight);
};

GVAR(camera) = objNull;
GVAR(cameraLight) = objNull;
GVAR(cameraFor) = [];
