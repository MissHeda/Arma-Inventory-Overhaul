#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Creates one control of the window, on the display or in a controls group, with its edges on the
 * screen's pixels. Every other piece of the UI kit is made through here.
 *
 * The edges are snapped, not the lengths: two pieces that share an edge get the same pixel for it and
 * meet without a gap or an overlap - on see-through surfaces either would show as a line. Inside a
 * group the pixels count from the group's corner, which sits on a pixel itself.
 *
 * Controls made on the display itself are kept in (uiNamespace getVariable [QGVAR(created), []]), so a rebuild can delete them. Those
 * in a group go with their group.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Class <STRING>
 * 2: Controls group to create it in, or controlNull for the display <CONTROL>
 * 3: Position [x, y, w, h] - relative to the group inside one - or [] to leave it where the class puts it <ARRAY>
 *
 * Return Value:
 * The control <CONTROL>
 *
 * Example:
 * [_display, "EINV_Label", controlNull, [0.1, 0.1, 0.2, 0.03]] call einv_gui_fnc_uiCreate;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_class", ["_parent", controlNull], ["_rect", []]];

private _ctrl = if (isNull _parent) then {
    _display ctrlCreate [_class, -1]
} else {
    _display ctrlCreate [_class, -1, _parent]
};

if (_rect isNotEqualTo []) then {
    _rect params ["_left", "_top", "_width", "_height"];

    private _originX = [safezoneX, 0] select !isNull _parent;
    private _originY = [safezoneY, 0] select !isNull _parent;
    private _x0 = _originX + round ((_left - _originX) / pixelW) * pixelW;
    private _y0 = _originY + round ((_top - _originY) / pixelH) * pixelH;
    private _x1 = _originX + round ((_left + _width - _originX) / pixelW) * pixelW;
    private _y1 = _originY + round ((_top + _height - _originY) / pixelH) * pixelH;

    _ctrl ctrlSetPosition [_x0, _y0, _x1 - _x0, _y1 - _y0];
    _ctrl ctrlCommit 0;
};

if (isNull _parent) then {
    (uiNamespace getVariable [QGVAR(created), []]) pushBack _ctrl;
};

_ctrl
