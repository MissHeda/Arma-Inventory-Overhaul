#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Makes a text area (fnc_uiEdit with several lines) as high as its text, two lines to spare, and never
 * lower than its scrolling group: the group scrolls through a long text, as CBA's export window does.
 * Only touches the control when its height really changes - this runs every frame (fnc_onMouse).
 *
 * Arguments:
 * 0: The text area <CONTROL>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_edit] call aio_setup_fnc_fitEditArea;
 *
 * Public: No
 */

disableSerialization;

params ["_edit"];

private _group = ctrlParentControlsGroup _edit;

if (isNull _group) exitWith {};

(ctrlPosition _group) params ["", "", "", "_groupH"];

private _position = ctrlPosition _edit;
private _height = (ctrlTextHeight _edit + (_edit getVariable [QGVAR(lineH), 0]) * 2) max _groupH;

if (abs ((_position select 3) - _height) < pixelH) exitWith {};

_position set [3, _height];
_edit ctrlSetPosition _position;
_edit ctrlCommit 0;
