#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * What a double click does on what the mouse is on, in the footer right after the keys (fnc_updateHover writes it): a key hint as
 * the others - the double click's mouse in a key cap, its words beside it (fnc_uiKeyHint) - then the same thin upright line as
 * between the keys and it, and the hint line after that (Mia, after 0.6.80: "all the same"). Made anew only when the words change;
 * "" takes it away and the hint line starts right after the keys again. Where it goes the footer said (fnc_drawFooter,
 * uiNamespace aio_gui_footerDoubleLayout).
 *
 * Arguments:
 * 0: What a double click does, "" for nothing <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["Quick move"] call aio_gui_fnc_footerDouble;
 *
 * Public: No
 */

disableSerialization;

params [["_label", "", [""]]];

private _layout = uiNamespace getVariable [QGVAR(footerDoubleLayout), []];

if (_layout isEqualTo [] || {_label isEqualTo (uiNamespace getVariable [QGVAR(footerDoubleShown), ""])}) exitWith {};

_layout params ["_startX", "_keyTop", "_keyH", "_gap", "_hintY", "_hintH", "_right"];

private _display = uiNamespace getVariable [QGVAR(display), displayNull];
private _hint = uiNamespace getVariable [QGVAR(hint), controlNull];

if (isNull _display || {isNull _hint}) exitWith {};

{ctrlDelete _x} forEach (uiNamespace getVariable [QGVAR(footerDoubleCtrls), []]);

private _controls = [];
private _hintX = _startX;

if (_label isNotEqualTo "") then {
    private _group = [_display, "AIO_Group", controlNull, [_startX, FOOT_Y, (_right - _startX) max pixelW, FOOT_H]] call FUNC(uiCreate);
    private _taken = [_display, _group, [0, _keyTop - FOOT_Y], "@double", _label, GVAR(theme), _keyH] call FUNC(uiKeyHint);

    if (isNil "_taken") then {_taken = 0};

    _controls pushBack _group;

    // The line as the one before it (fnc_drawFooter): in the middle of the gap after the hint, as long as the others (FOOT_LINE_H).
    _controls append ([
        _display, controlNull, [_startX + _taken - _gap, FOOT_Y + FOOT_H * FOOT_LINE_TOP, (1 max round (UNIT * 0.04 / pixelW)) * pixelW, FOOT_H * FOOT_LINE_H],
        GVAR(theme) getOrDefault ["line", [1, 1, 1, 0.14]]
    ] call FUNC(uiPanel));

    _hintX = _startX + _taken;
};

uiNamespace setVariable [QGVAR(footerDoubleCtrls), _controls];
uiNamespace setVariable [QGVAR(footerDoubleShown), _label];

// Shown again as it was when the window is built anew (fnc_drawFooter).
if (_label isNotEqualTo "") then {
    uiNamespace setVariable [QGVAR(footerDoubleLast), _label];
};

private _rect = [_hintX, _hintY, (_right - _hintX) max pixelW, _hintH];

_hint setVariable [QGVAR(hintCentred), _rect];
_hint setVariable [QGVAR(hintWide), _rect];
_hint ctrlShow ((_right - _hintX) >= SQUARE(UNIT * 6));

[_hint] call FUNC(fitHint);
