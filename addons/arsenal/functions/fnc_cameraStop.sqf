#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Ends the camera: the editor's or the curator's is given back, otherwise the camera is terminated and
 * destroyed, and its light deleted. Safe to call when there is none.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call einv_arsenal_fnc_cameraStop;
 *
 * Public: No
 */

// The view goes back to normal: the camera was looked through night vision or thermal imaging.
if (GVAR(visionMode) != 0) then {
    [0] call FUNC(cycleVision);
};

if (!isNull GVAR(camera)) then {
    // The view goes back before the camera goes (ACE's order): the editor's camera, the curator's when
    // the unit is the player's own - a remote controlled one is released by the unload, which brings the
    // curator's view back itself -, else the player's.
    if (is3DEN) then {
        get3DENCamera cameraEffect ["Internal", "BACK"];
    } else {
        if (!isNull curatorCamera && {ACE_player isEqualTo player}) then {
            curatorCamera cameraEffect ["Internal", "BACK"];
        } else {
            GVAR(camera) cameraEffect ["Terminate", "BACK"];
        };
    };

    camDestroy GVAR(camera);
};

if (!isNull GVAR(cameraLight)) then {
    deleteVehicle GVAR(cameraLight);
};

GVAR(camera) = objNull;
GVAR(cameraLight) = objNull;
GVAR(cameraDrag) = [];
