#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * An item's picture turned a quarter round, fitted into a box - the picture of a tile that lies turned,
 * and the dragged ghost of one held turned (fnc_makeGhost, also for a row dragged from ACE Arsenal's list).
 *
 * ctrlSetAngle turns what a control draws round a point of it. Two things went wrong with it: on a control
 * laid out in a shape meant to come out right after the turn (up to 0.4.6) the picture showed squashed and
 * out of its box, and in a square control (0.4.7 to 0.5.16) a picture that is not square - a rifle, any
 * four-cell rectangle - came out squashed into the square, because the control keeps a picture's shape
 * (ST_KEEP_ASPECT_RATIO) only while it is not turned. So the control is made in the picture's own shape,
 * W:H wide, in whole pixels (fnc_turnedSize), centred on the box, and only the turn changes what it shows:
 * a quarter clockwise round its middle - the rotation convention of the storage (section 3 of
 * docs/ARCHITECTURE.md), the way the footprint turns. The picture shows H wide and W high, centred on the
 * same middle, never stretched into the swapped shape.
 *
 * The picture is fitted into the box as it shows turned: its longer edge as long as the box allows. A wide
 * picture (a rifle, 2:1) on a box four cells high and one wide is two cells high and one wide turned.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group to create it in, or controlNull for the display <CONTROL>
 * 2: The box it lies in, [x, y, w, h] as it shows <ARRAY>
 * 3: Texture <STRING>
 * 4: Colour <ARRAY> (default: [1, 1, 1, 1])
 * 5: Width to height of the picture, when the texture does not say <NUMBER> (default: 1)
 * 6: Scale: the picture this many times its fitted size (an item's icon=, fnc_uiItemPicture) <NUMBER> (default: 1)
 * 7: Shift [x, y] of the picture's middle off the box's, in screen units <ARRAY> (default: [0, 0])
 *
 * Return Value:
 * The picture <CONTROL>
 *
 * Example:
 * [_display, controlNull, [0.5, 0.2, 0.04, 0.16], _picture, [1, 1, 1, 1], 2] call einv_gui_fnc_uiPictureTurned;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_parent", "_rect", "_texture", ["_color", [1, 1, 1, 1]], ["_aspect", 1], ["_scale", 1], ["_shift", [0, 0]]];
_rect params ["_left", "_top", "_width", "_height"];
_shift params ["_shiftX", "_shiftY"];

// The control before the turn, in the picture's own shape.
([_texture, _aspect, [_width / pixelW, _height / pixelH], _scale] call FUNC(turnedSize)) params ["_ctrlW", "_ctrlH"];

private _ctrl = [_display, "EINV_Picture", _parent, [
    _left + (_width - _ctrlW * pixelW) / 2 + _shiftX,
    _top + (_height - _ctrlH * pixelH) / 2 + _shiftY,
    _ctrlW * pixelW,
    _ctrlH * pixelH
]] call FUNC(uiCreate);

_ctrl ctrlSetText ([_texture] call FUNC(safePicture));
_ctrl ctrlSetTextColor _color;
_ctrl ctrlSetAngle [90, 0.5, 0.5];

_ctrl
