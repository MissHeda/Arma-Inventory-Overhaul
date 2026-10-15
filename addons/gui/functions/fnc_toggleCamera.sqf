#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Turns the live camera on the player's soldier on or off for the window open now and builds it again - a
 * look may lay out its middle differently with the soldier in it. The next window starts as the player's
 * setting says (einv_gui_cameraDefault, fnc_open): the button is a choice of the moment, not a default.
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

private _display = uiNamespace getVariable [QGVAR(display), displayNull];

if (!isNull _display) then {
    [_display] call FUNC(build);
};
