#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Gives the player's own view back and removes the camera and its light (fnc_cameraStart). Safe to
 * call when there is none.
 *
 * Ending the camera ("terminate") leaves the player in first person, so the view he had when the
 * camera began - third person, say - is switched to again (GVAR(cameraView)), as long as his soldier
 * is still what he sees through.
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

    GVAR(cameraView) params [["_unit", objNull], ["_view", ""]];

    if (
        _view in ["INTERNAL", "EXTERNAL", "GUNNER", "GROUP"] && {!isNull _unit} && {alive _unit}
        && {cameraOn isEqualTo vehicle _unit} && {cameraView isNotEqualTo _view}
    ) then {
        _unit switchCamera _view;
    };
};

if (!isNull GVAR(cameraLight)) then {
    deleteVehicle GVAR(cameraLight);
};

GVAR(camera) = objNull;
GVAR(cameraLight) = objNull;
GVAR(cameraFor) = [];
GVAR(cameraView) = [];
