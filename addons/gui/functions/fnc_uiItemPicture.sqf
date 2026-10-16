#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * An item's picture the way its rules ask for it (icon= / einv_icon, "icon" of einv_items_fnc_getInfo, see
 * einv_items_fnc_parseIcon): fitted into its box as fnc_uiPicture fits it - fnc_uiPictureTurned for a tile that
 * lies turned -, then drawn [scale] times as large about the box's middle and moved by the offsets, which are
 * a share of the tile's width and height. Every tile, slot, card and the dragged ghost draw an item's picture
 * through here.
 *
 * The plain picture (scale 1, nothing moved) is the one control it always was. A picture that is larger or
 * moved never goes out of the rectangle it belongs to: where its image stays inside that rectangle it is
 * still one control; where it would reach out, it is made inside a controls group of exactly that rectangle,
 * which clips it. The image is measured by the texture's own shape (getTextureInfo), not by the control it is
 * fitted into, so a wide picture in a tall box that stays inside gets no group. The group is the control that
 * comes back, with the picture in it as (_group getVariable QGVAR(inner)) - a turned ghost is turned again on
 * it every frame (fnc_updateDrag).
 *
 * Turned, a quarter clockwise like the tile, the offsets turn with the picture: what the upright picture
 * moves across the tile (right) the turned one moves down it, and what it moves down it moves left.
 *
 * A group over a tile takes the mouse from the column that holds the tile, so it reports the buttons and the
 * wheel as the display does, like every group of the window (fnc_build, fnc_drawPart), and hands the wheel
 * on to its column (fnc_onMouseZ, fnc_passWheel). It scrolls by nothing of its own: a picture larger than it
 * would make it scrollable.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group to create it in, or controlNull for the display <CONTROL>
 * 2: The box the picture is fitted into, [x, y, w, h], in that group or on the screen <ARRAY>
 * 3: Texture - the item's picture <STRING>
 * 4: The icon, [scale, across, down] (the item's "icon") <ARRAY> (default: [1, 0, 0])
 * 5: Colour it is multiplied with <ARRAY> (default: [1, 1, 1, 1])
 * 6: The tile lies turned a quarter <BOOL> (default: false)
 * 7: Width to height of the picture, turned, when the texture does not say <NUMBER> (default: 1)
 * 8: The rectangle it must stay in, [x, y, w, h], in the same space as the box - the tile's, the slot's;
 *    the box itself when left out <ARRAY> (default: [])
 * 9: Report the mouse as the display does - not in the setup wizard, which has no inventory window; a group
 *    made without it only keeps the picture in it from being scrolled by the wheel <BOOL> (default: true)
 *
 * Return Value:
 * The picture, or the group that clips it <CONTROL>
 *
 * Example:
 * [_display, _group, [0, 0, 0.1, 0.05], _picture, [1.4, 0.1, -0.05], [1, 1, 1, 1], false, 1, [0, 0, 0.1, 0.05]] call einv_gui_fnc_uiItemPicture;
 *
 * Public: No
 */

disableSerialization;

params [
    "_display", "_parent", "_box", "_texture", ["_icon", ICON_PLAIN, [[]]], ["_color", [1, 1, 1, 1]], ["_turned", false],
    ["_aspect", 1], ["_clip", []], ["_events", true]
];

_icon params [["_scale", 1], ["_across", 0], ["_down", 0]];

// The picture as it is fitted: one control, nothing to cut. Also for a placeholder or a file that is not there
// (fnc_safePicture): nothing is drawn, so there is nothing to cut.
private _plain = _scale == 1 && {_across == 0} && {_down == 0};

if (!_plain && {([_texture] call FUNC(safePicture)) isEqualTo ""}) then {
    _plain = true;
};

if (_plain) exitWith {
    if (_turned) then {
        [_display, _parent, _box, _texture, _color, _aspect] call FUNC(uiPictureTurned)
    } else {
        [_display, _parent, _box, _texture, _color] call FUNC(uiPicture)
    }
};

_box params ["_boxX", "_boxY", "_boxW", "_boxH"];

if (_clip isEqualTo []) then {
    _clip = +_box;
};

_clip params ["_clipX", "_clipY", "_clipW", "_clipH"];

// The picture's own shape, width to height: where its image really ends inside the control it is fitted into.
private _info = getTextureInfo _texture;
private _ratio = 0;

if (_info isEqualType [] && {(_info param [0, 0]) > 0} && {(_info param [1, 0]) > 0}) then {
    _ratio = (_info select 0) / (_info select 1);
};

// How far the picture moves on the screen. Turned a quarter clockwise, what went across now goes down and
// what went down now goes left.
private _shiftX = _across * _clipW;
private _shiftY = _down * _clipH;

if (_turned) then {
    _shiftX = -_down * _clipW;
    _shiftY = _across * _clipH;
};

private _centerX = _boxX + _boxW / 2 + _shiftX;
private _centerY = _boxY + _boxH / 2 + _shiftY;

// The control it is made as (upright) and the image in it, which is all that has to stay inside.
private _rect = [];
private _imageW = 0;
private _imageH = 0;

if (_turned) then {
    private _shape = [_aspect, _ratio] select (_ratio > 0);

    if (_shape <= 0) then {
        _shape = 1;
    };

    // The square fnc_uiPictureTurned makes, in pixels; the picture keeps its shape in it, and turned its width
    // runs down the box and its height across.
    private _side = (floor ((((_boxW / pixelW) / ((1 / _shape) min 1)) min ((_boxH / pixelH) / (_shape min 1))) * _scale)) max 1;
    private _short = _side / (_shape max (1 / _shape));

    if (_shape >= 1) then {
        _imageW = _short * pixelW;
        _imageH = _side * pixelH;
    } else {
        _imageW = _side * pixelW;
        _imageH = _short * pixelH;
    };
} else {
    private _width = _boxW * _scale;
    private _height = _boxH * _scale;

    _rect = [_centerX - _width / 2, _centerY - _height / 2, _width, _height];
    _imageW = _width;
    _imageH = _height;

    // Kept in its shape, the image fills the control along the side it is longer on.
    if (_ratio > 0) then {
        if ((_width / pixelW) / (_height / pixelH) > _ratio) then {
            _imageW = (_height / pixelH) * _ratio * pixelW;
        } else {
            _imageH = (_width / pixelW) / _ratio * pixelH;
        };
    };
};

// Half a pixel of give: the edges of a tile are on pixels, the picture's maths is not.
private _inside = _centerX - _imageW / 2 >= _clipX - pixelW / 2
    && {_centerX + _imageW / 2 <= _clipX + _clipW + pixelW / 2}
    && {_centerY - _imageH / 2 >= _clipY - pixelH / 2}
    && {_centerY + _imageH / 2 <= _clipY + _clipH + pixelH / 2};

// Where it is made: where it was asked for when it stays inside, else in a group of the rectangle.
private _target = _parent;
private _group = controlNull;
private _originX = 0;
private _originY = 0;

if (!_inside) then {
    _group = [_display, "EINV_Group", _parent, _clip] call FUNC(uiCreate);
    _target = _group;

    // The group's corner sits on a pixel, a little off where it was asked for; its picture counts from it.
    private _position = ctrlPosition _group;

    _originX = _position select 0;
    _originY = _position select 1;
};

private _picture = if (_turned) then {
    [
        _display, _target, [_boxX - _originX, _boxY - _originY, _boxW, _boxH], _texture, _color, _aspect, _scale, [_shiftX, _shiftY]
    ] call FUNC(uiPictureTurned)
} else {
    [
        _display, _target, [(_rect select 0) - _originX, (_rect select 1) - _originY, _rect select 2, _rect select 3], _texture, _color
    ] call FUNC(uiPicture)
};

if (_inside) exitWith {_picture};

_group setVariable [QGVAR(inner), _picture];
_group setVariable [QGVAR(clip), true];

if (_events) then {
    // Hooked here, so the build's sweep leaves it alone (it hooks every group it finds that is not).
    _group setVariable [QGVAR(hooked), true];
    _group ctrlAddEventHandler ["MouseButtonDown", {[true, _this] call FUNC(onMouseButton)}];
    _group ctrlAddEventHandler ["MouseButtonUp", {[false, _this] call FUNC(onMouseButton)}];
    _group ctrlAddEventHandler ["MouseZChanged", {[_this] call FUNC(onMouseZ)}];
} else {
    // No window to hand the wheel to: at least the picture stays where it is put.
    _group ctrlAddEventHandler ["MouseZChanged", {(_this select 0) ctrlSetScrollValues [0, 0]}];
};

_group
