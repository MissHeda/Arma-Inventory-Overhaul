#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * A swatch of two colours side by side with round outer corners: the left half round on its left, the right half round on its
 * right, square where they meet. Each half is a round panel (fnc_uiPanel) whose inner corners are covered by a square strip of
 * its own colour, so a half is recoloured by painting all of its controls (fnc_paintSurface).
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group, or controlNull for the display <CONTROL>
 * 2: Position [x, y, w, h] <ARRAY>
 * 3: Corner radius, as a height <NUMBER>
 *
 * Return Value:
 * [the left half's controls, the right half's controls] <ARRAY>
 *
 * Example:
 * [_display, _layer, [0.1, 0.1, 0.04, 0.02], UNIT * 0.2] call einv_gui_fnc_uiSplitSwatch;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_parent", "_rect", ["_radius", 0, [0]]];

_rect params ["_left", "_top", "_width", "_height"];

private _half = _width / 2;

// A corner is never more than half the half, as fnc_uiPanel keeps it; its width on the screen, as wide as it is high.
private _cornerW = SQUARE(_radius min (_height / 2)) min (_half / 2);

private _leftCtrls = [_display, _parent, [_left, _top, _half, _height], [0, 0, 0, 1], _radius] call FUNC(uiPanel);
private _rightCtrls = [_display, _parent, [_left + _half, _top, _half, _height], [0, 0, 0, 1], _radius] call FUNC(uiPanel);

if (_cornerW > 0) then {
    _leftCtrls append ([_display, _parent, [_left + _half - _cornerW, _top, _cornerW, _height], [0, 0, 0, 1], 0] call FUNC(uiPanel));
    _rightCtrls append ([_display, _parent, [_left + _half, _top, _cornerW, _height], [0, 0, 0, 1], 0] call FUNC(uiPanel));
};

[_leftCtrls, _rightCtrls]
