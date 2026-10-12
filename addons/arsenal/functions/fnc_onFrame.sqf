#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What the window does every frame (the "frame" hook, not while another window lies over this one): the
 * camera, the catalog's scrolling and warming, the loadouts' checking. The engine asks it also while
 * something is dragged, so the soldier turns and the catalog scrolls under a held card.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Mouse position [x, y] <ARRAY>
 * 2: Time of the frame, diag_tickTime <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, getMousePosition, diag_tickTime] call einv_arsenal_fnc_onFrame;
 *
 * Public: No
 */

params ["_display", "_mouse", "_now"];

[_mouse, _now] call FUNC(cameraFrame);

[_display, _mouse, _now] call FUNC(catalogFrame);

if (GVAR(view) isEqualTo "loadouts") then {
    [_now] call FUNC(loadoutsFrame);
};
