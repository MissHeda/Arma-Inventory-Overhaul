#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What lies on top at a point of the screen - the one place that knows how the floating layers lie over
 * each other: the inspect card over the kit windows, the windows over each other as they were made (the
 * last on top), all of them over the columns. Hover, drops, clicks, the menu's free cells and the edge
 * scrolling of a drag only take what lies on that layer, so nothing under a window or the card gets the
 * mouse. The context menu lies over all of it and takes its clicks itself (fnc_openMenu).
 *
 * Arguments:
 * 0: Point on the screen [x, y] - getMousePosition <ARRAY>
 *
 * Return Value:
 * "inspect" on the inspect card, the key of the topmost kit window there, "" for the columns <STRING>
 *
 * Example:
 * [getMousePosition] call einv_gui_fnc_topAt;
 *
 * Public: No
 */

disableSerialization;

params [["_point", [], [[]]]];

if (count _point < 2) exitWith {""};

_point params ["_pointX", "_pointY"];

(uiNamespace getVariable [QGVAR(inspectRect), []]) params [["_cardX", 0], ["_cardY", 0], ["_cardW", 0], ["_cardH", 0]];

if (_pointX >= _cardX && {_pointX < _cardX + _cardW} && {_pointY >= _cardY} && {_pointY < _cardY + _cardH}) exitWith {"inspect"};

private _windows = uiNamespace getVariable [QGVAR(windows), []];
private _found = "";

for "_i" from (count _windows - 1) to 0 step -1 do {
    private _record = _windows select _i;

    (_record getOrDefault ["rect", [0, 0, 0, 0]]) params ["_left", "_top", "_width", "_height"];

    if (_pointX >= _left && {_pointX < _left + _width} && {_pointY >= _top} && {_pointY < _top + _height}) exitWith {
        _found = _record getOrDefault ["key", ""];
    };
};

_found
