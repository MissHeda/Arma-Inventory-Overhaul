#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The size, in pixels, of the control that shows an item's picture turned a quarter (fnc_uiPictureTurned): the
 * control as it is made, before ctrlSetAngle turns it, in the picture's own proportions.
 *
 * The turn does not keep a picture's shape the way the control does when it is upright (ST_KEEP_ASPECT_RATIO
 * fits the texture inside the control only at rest: a wide texture in a square control, turned, came out
 * squashed into the square - rifles and other four-cell rectangles). So there is nothing to fit once it
 * turns: the control has exactly the picture's shape, W:H wide, and the turn makes it H wide and W high.
 * The turned picture is fitted into the box with its height across and its width down: its longer edge is as
 * long as the box allows (times the item's zoom), its shorter one follows from the shape.
 *
 * Arguments:
 * 0: The texture, whose own shape is used when it can be read <STRING>
 * 1: Width to height of the picture when the texture does not say <NUMBER>
 * 2: The box it is fitted into, as it shows, in pixels [w, h] <ARRAY>
 * 3: Scale: the picture this many times its fitted size (icon=) <NUMBER> (default: 1)
 *
 * Return Value:
 * The control before the turn, in pixels, [w, h] - the picture shows h wide and w high <ARRAY>
 *
 * Example:
 * [_picture, 2, [37, 148]] call einv_gui_fnc_turnedSize;
 *
 * Public: No
 */

params ["_texture", ["_aspect", 1], "_box", ["_scale", 1]];
_box params ["_boxW", "_boxH"];

private _info = getTextureInfo _texture;

if (_info isEqualType [] && {(_info param [0, 0]) > 0} && {(_info param [1, 0]) > 0}) then {
    _aspect = (_info select 0) / (_info select 1);
};

if (_aspect <= 0) then {
    _aspect = 1;
};

// Turned, the picture's width runs down the box and its height across it.
private _ctrlW = 1;
private _ctrlH = 1;

if (_aspect >= 1) then {
    _ctrlW = (floor ((_boxH min (_boxW * _aspect)) * _scale)) max 1;
    _ctrlH = (round (_ctrlW / _aspect)) max 1;
} else {
    _ctrlH = (floor ((_boxW min (_boxH / _aspect)) * _scale)) max 1;
    _ctrlW = (round (_ctrlH * _aspect)) max 1;
};

[_ctrlW, _ctrlH]
