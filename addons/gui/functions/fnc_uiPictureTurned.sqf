#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * An item's picture turned a quarter round, fitted into a box - the picture of a tile that lies turned,
 * and the dragged ghost of one held turned (fnc_makeGhost, also for a row dragged from ACE Arsenal's list).
 *
 * ctrlSetAngle turns what a control draws round a point of it, and on a control that is not square in
 * pixels the picture comes out squashed or skewed: the turn works in the control's own proportions. Up to
 * 0.4.6 the control was laid out in a shape meant to come out right after the turn; in the game the
 * picture of a turned tile showed squashed and out of its box. So the control is a square in pixels, centred
 * on the box, and only the turn changes what it shows: the picture keeps its own shape in the square
 * (EINV_Picture, ST_KEEP_ASPECT_RATIO) and turns with it a quarter clockwise round its middle - the
 * rotation convention of the storage (section 3 of docs/ARCHITECTURE.md), the way the footprint turns.
 *
 * The square's side is the most the turned picture may have to fit the box: kept in its shape in the
 * square, a picture W:H takes the square's whole side along its longer edge; turned, its width runs down
 * the box and its height across. A wide picture (a rifle, 2:1) on a box three cells high and one wide gets a square two cells
 * on a side - its picture, turned, one cell wide and two high - not three, which would run out of the box
 * at both sides. The square may stand out of the box where the picture leaves it empty.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group to create it in, or controlNull for the display <CONTROL>
 * 2: The box it lies in, [x, y, w, h] as it shows <ARRAY>
 * 3: Texture <STRING>
 * 4: Colour <ARRAY> (default: [1, 1, 1, 1])
 * 5: Width to height of the picture, when the texture does not say <NUMBER> (default: 1)
 * 6: Scale: the square, and so the picture, this many times its fitted size (an item's icon=,
 *    fnc_uiItemPicture) <NUMBER> (default: 1)
 * 7: Shift [x, y] of the square's middle off the box's, in screen units <ARRAY> (default: [0, 0])
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

private _info = getTextureInfo _texture;

if (_info isEqualType [] && {(_info param [0, 0]) > 0} && {(_info param [1, 0]) > 0}) then {
    _aspect = (_info select 0) / (_info select 1);
};

if (_aspect <= 0) then {
    _aspect = 1;
};

// The box in pixels. In the square of side S the picture is S by S / W:H when wide, S * W:H by S when tall;
// turned, its width runs down the box and its height across.
private _boxW = _width / pixelW;
private _boxH = _height / pixelH;
private _side = (floor (((_boxW / ((1 / _aspect) min 1)) min (_boxH / (_aspect min 1))) * _scale)) max 1;

private _ctrl = [_display, "EINV_Picture", _parent, [
    _left + (_width - _side * pixelW) / 2 + _shiftX,
    _top + (_height - _side * pixelH) / 2 + _shiftY,
    _side * pixelW,
    _side * pixelH
]] call FUNC(uiCreate);

_ctrl ctrlSetText ([_texture] call FUNC(safePicture));
_ctrl ctrlSetTextColor _color;
_ctrl ctrlSetAngle [90, 0.5, 0.5];

_ctrl
