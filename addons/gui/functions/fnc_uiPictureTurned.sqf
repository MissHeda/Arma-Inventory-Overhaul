#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * An item's picture turned a quarter round, fitted into a box - the picture of a tile that lies turned.
 *
 * ctrlSetAngle turns a control in the screen's own units, which are not square in pixels: a picture
 * laid out upright and then turned came out squashed (phase 1 test). So the control is made in the
 * shape it needs before the turn to have the right one after it - its width, which ends up running
 * down the screen, measured in the screen's heights, its height in its widths - and the picture is
 * stretched to it (ST_PICTURE without keeping its shape), sized by the picture's own proportions.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group to create it in, or controlNull for the display <CONTROL>
 * 2: The box it lies in, [x, y, w, h] as it shows <ARRAY>
 * 3: Texture <STRING>
 * 4: Colour <ARRAY> (default: [1, 1, 1, 1])
 * 5: Width to height of the picture, when the texture does not say <NUMBER> (default: 1)
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

params ["_display", "_parent", "_rect", "_texture", ["_color", [1, 1, 1, 1]], ["_aspect", 1]];
_rect params ["_left", "_top", "_width", "_height"];

private _info = getTextureInfo _texture;

if (_info isEqualType [] && {(_info param [0, 0]) > 0} && {(_info param [1, 0]) > 0}) then {
    _aspect = (_info select 0) / (_info select 1);
};

// The box in pixels. Turned, the picture's width runs down it and its height across.
private _boxW = _width / pixelW;
private _boxH = _height / pixelH;
private _long = _boxH min (_boxW * _aspect);
private _short = _long / _aspect;

// Before the turn: as wide as it will be high, in heights, and as high as it will be wide, in widths.
private _ctrlW = _long * pixelH;
private _ctrlH = _short * pixelW;

private _ctrl = [_display, "EINV_PictureStretch", _parent, [
    _left + (_width - _ctrlW) / 2,
    _top + (_height - _ctrlH) / 2,
    _ctrlW,
    _ctrlH
]] call FUNC(uiCreate);

_ctrl ctrlSetText _texture;
_ctrl ctrlSetTextColor _color;
_ctrl ctrlSetAngle [90, 0.5, 0.5];

_ctrl
