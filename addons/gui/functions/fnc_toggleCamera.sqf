#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Turns the live camera on the player's soldier on or off, keeps the choice in the profile and builds
 * the open window again - a look may lay out its middle differently with the soldier in it.
 *
 * Not from inside a control's own event: the rebuild deletes the button that was clicked.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call einv_gui_fnc_toggleCamera;
 *
 * Public: No
 */

GVAR(cameraOn) = !GVAR(cameraOn);

profileNamespace setVariable [QGVAR(cameraOn), GVAR(cameraOn)];
saveProfileNamespace;

private _display = uiNamespace getVariable [QGVAR(display), displayNull];

if (!isNull _display) then {
    [_display] call FUNC(build);
};
