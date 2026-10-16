#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * An item's picture the way its rules draw it (fnc_uiItemPicture), cut at the rectangle of a box with round
 * corners. A picture larger than the box (icon= over 1) lies in a controls group of the box's rectangle that
 * cuts it - and a group is square: over the box's round corners it would draw the picture's square ones,
 * though the backdrop under it is round. So such a picture is cut in three, as fnc_uiPanel builds a round
 * panel - the middle that runs the box's whole height between the corners, and the two sides between the
 * corners - and every piece is a group of its own, each holding the whole picture at the same place (the offsets count in the whole box's size, not the piece's). The corner squares have
 * none of it: the backdrop shows there, a flat colour at a picture's edge anyway. A picture that stays inside
 * the box is the one control it always was, and so is one in a box with square corners.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group to create it in, or controlNull for the display <CONTROL>
 * 2: The box the picture is fitted into, [x, y, w, h] <ARRAY>
 * 3: Texture <STRING>
 * 4: How the rules draw it, [scale, across, down] (icon=) <ARRAY> (default: [1, 0, 0])
 * 5: The rectangle it is cut at - the box with round corners - [x, y, w, h] <ARRAY>
 * 6: Its corner radius, as a height <NUMBER> (default: 0)
 * 7: Report the mouse as the inventory window does - not in the setup wizard <BOOL> (default: true)
 *
 * Return Value:
 * The pictures, or the groups that cut them <ARRAY>
 *
 * Example:
 * [_display, _group, _pictureBox, _picture, [1.4, 0, 0], _boxRect, UNIT * 0.4] call einv_gui_fnc_uiPictureCut;
 *
 * Public: No
 */

disableSerialization;

params [
    "_display", "_parent", "_box", "_texture", ["_icon", ICON_PLAIN, [[]]], "_clip", ["_radius", 0], ["_events", true, [true]]
];

private _first = [_display, _parent, _box, _texture, _icon, [1, 1, 1, 1], false, 1, _clip, _events, [_clip select 2, _clip select 3]] call FUNC(uiItemPicture);

// Nothing to cut: one control that stays inside the box.
if !(_first getVariable [QGVAR(clip), false]) exitWith {[_first]};

// The box's pieces as fnc_uiPanel lays them out - the same pixels, the same corner.
_clip params ["_left", "_top", "_width", "_height"];

private _originX = [safezoneX, 0] select !isNull _parent;
private _originY = [safezoneY, 0] select !isNull _parent;
private _x0 = _originX + round ((_left - _originX) / pixelW) * pixelW;
private _y0 = _originY + round ((_top - _originY) / pixelH) * pixelH;
private _x1 = _originX + round ((_left + _width - _originX) / pixelW) * pixelW;
private _y1 = _originY + round ((_top + _height - _originY) / pixelH) * pixelH;

private _corner = floor (_radius / pixelH) min floor (round ((_x1 - _x0) / pixelW) / 2) min floor (round ((_y1 - _y0) / pixelH) / 2);

// Square corners: the group of the whole box is right.
if (_corner < 1) exitWith {[_first]};

ctrlDelete _first;

private _cap = _corner * pixelW;
private _rise = _corner * pixelH;
private _controls = [];

{
    _x params ["_pieceX", "_pieceY", "_pieceW", "_pieceH"];

    // The sides of a pill have no height left between their corners.
    if (_pieceW <= 0 || {_pieceH <= 0}) then {continue};

    _controls pushBack ([_display, _parent, _box, _texture, _icon, [1, 1, 1, 1], false, 1, _x, _events, [_clip select 2, _clip select 3]] call FUNC(uiItemPicture));
} forEach [
    [_x0 + _cap, _y0, _x1 - _x0 - 2 * _cap, _y1 - _y0],
    [_x0, _y0 + _rise, _cap, _y1 - _y0 - 2 * _rise],
    [_x1 - _cap, _y0 + _rise, _cap, _y1 - _y0 - 2 * _rise]
];

_controls
