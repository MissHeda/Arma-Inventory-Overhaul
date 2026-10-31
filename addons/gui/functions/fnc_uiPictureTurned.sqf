#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * An item's picture turned a quarter clockwise (issue #24), the way the footprint of a tile turned with R
 * lies: the turned tiles' pictures (fnc_turnPicture) and the dragged ghost held turned (fnc_makeGhost).
 *
 * Nothing on the screen is turned: ctrlSetAngle turns in the screen's UI units, which are not square, and cuts
 * what it draws to the control's rectangle before the turn, so a rifle came out short and fat (issue #28, and
 * every try from 0.4.7 to 0.6.5). The picture is turned inside a texture of its own instead (fnc_turnedTexture):
 * square, the turned picture in its own shape in the middle, transparent round it. AIO_PictureTurned stretches
 * that texture over a control that is square in pixels, as long as the turned picture is, so the picture shows
 * exactly as turned. The control is still made on the display by the callers (fnc_turnPicture keeps it over its
 * tile; the ghost is on the display anyway).
 *
 * The control is fitted so that, turned, it fills the box along its longer side: shown, it is as wide as the
 * control is high and as high as it is wide. An item's icon= scale makes it larger or smaller, never larger
 * than the rectangle it must stay in; its offsets turn with it (what the upright picture moves right the
 * turned one moves down, what it moves down the turned one moves left), and its middle is held inside that
 * rectangle. QGVAR(angle) is 0: the control itself is not turned, whoever moves it has nothing to turn again.
 *
 * With "Log window timings (debug)" on, the RPT gets one line per texture and box size: what the texture says
 * of its shape, the box, the control before the turn and where it lies, and what ctrlAngle reads back.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group to create it in, or controlNull for the display <CONTROL>
 * 2: The box it is fitted into, [x, y, w, h] as it shows (the turned footprint) <ARRAY>
 * 3: Texture <STRING>
 * 4: Colour <ARRAY> (default: [1, 1, 1, 1])
 * 5: The icon, [scale, across, down] (the item's "icon") <ARRAY> (default: [1, 0, 0])
 * 6: The rectangle it must stay in, [x, y, w, h]; the box when left out <ARRAY> (default: [])
 * 7: The size the offsets are a share of, [w, h]; the rectangle's own when left out <ARRAY> (default: [])
 *
 * Return Value:
 * The picture <CONTROL>
 *
 * Example:
 * [_display, controlNull, [0.5, 0.2, 0.04, 0.16], _picture] call aio_gui_fnc_uiPictureTurned;
 *
 * Public: No
 */

disableSerialization;

params [
    "_display", "_parent", "_box", "_texture", ["_color", [1, 1, 1, 1]], ["_icon", ICON_PLAIN, [[]]], ["_clip", []], ["_share", []]
];

_box params ["_boxX", "_boxY", "_boxW", "_boxH"];
_icon params [["_scale", 1], ["_across", 0], ["_down", 0]];

if (_clip isEqualTo []) then {
    _clip = +_box;
};

_clip params ["_clipX", "_clipY", "_clipW", "_clipH"];

if (_share isEqualTo []) then {
    _share = [_clipW, _clipH];
};

_share params ["_shareW", "_shareH"];

// The texture's own shape, width to height.
private _info = getTextureInfo _texture;
private _aspect = 1;

if (_info isEqualType [] && {(_info param [0, 0]) > 0} && {(_info param [1, 0]) > 0}) then {
    _aspect = (_info select 0) / (_info select 1);
};

// In pixels. Turned, the control shows _ctrlH wide and _ctrlW high, and _ctrlW is _aspect times _ctrlH.
private _boxWp = _boxW / pixelW;
private _boxHp = _boxH / pixelH;
private _ctrlH = (_boxWp min (_boxHp / _aspect)) * (_scale max 0.05);
private _ctrlW = _ctrlH * _aspect;

// Never larger than the rectangle it must stay in.
private _fit = ((_clipW / pixelW) / (_ctrlH max 1)) min ((_clipH / pixelH) / (_ctrlW max 1)) min 1;

_ctrlW = (round (_ctrlW * _fit)) max 1;
_ctrlH = (round (_ctrlH * _fit)) max 1;

// Shown, in screen units.
private _shownW = _ctrlH * pixelW;
private _shownH = _ctrlW * pixelH;

// The offsets turn with the picture, and its middle stays inside the rectangle.
private _centerX = _boxX + _boxW / 2 - _down * _shareW;
private _centerY = _boxY + _boxH / 2 + _across * _shareH;

_centerX = (_centerX max (_clipX + _shownW / 2)) min (_clipX + _clipW - _shownW / 2);
_centerY = (_centerY max (_clipY + _shownH / 2)) min (_clipY + _clipH - _shownH / 2);

// Square, as long as the turned picture: the turned texture holds the picture in its own shape in the middle.
private _side = _ctrlW max _ctrlH;

private _ctrl = [_display, "AIO_PictureTurned", _parent, [
    _centerX - _side * pixelW / 2, _centerY - _side * pixelH / 2, _side * pixelW, _side * pixelH
]] call FUNC(uiCreate);

private _source = [_texture] call FUNC(safePicture);

_ctrl ctrlSetText ([_display, _source] call FUNC(turnedTexture));
_ctrl setVariable [QGVAR(turnedSource), _source];
_ctrl ctrlSetTextColor _color;
_ctrl setVariable [QGVAR(angle), 0];
_ctrl setVariable [QGVAR(shown), [_shownW, _shownH]];

if (missionNamespace getVariable [QGVAR(debugTiming), false]) then {
    private _logged = uiNamespace getVariable [QGVAR(turnLogged), createHashMap];
    private _key = format ["%1|%2|%3", _texture, round _boxWp, round _boxHp];

    if !(_key in _logged) then {
        _logged set [_key, true];
        uiNamespace setVariable [QGVAR(turnLogged), _logged];

        private _boxPixels = [round _boxWp, round _boxHp];
        private _ctrlPixels = [_ctrlW, _ctrlH, ctrlPosition _ctrl, ctrlAngle _ctrl, ["group", "display"] select (isNull _parent)];

        INFO_4("turned picture: %1 (texture %2), box %3 px, control before the turn and where (w h, position, ctrlAngle, made on) %4",_texture,_info,_boxPixels,_ctrlPixels);
    };
};

_ctrl
