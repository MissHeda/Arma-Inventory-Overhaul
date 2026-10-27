#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Turns the picture of a tile that lies turned (issue #24; fnc_createTile, "rotated"). The tile keeps the upright
 * picture it was drawn with (fnc_uiItemPicture) as its fallback, and a turned one (fnc_uiPictureTurned) is laid
 * over it on the display: a turned control inside a controls group that is moved or scrolled - every column,
 * section and kit window is one - is drawn in the wrong place, one on the display is not.
 *
 * fnc_syncTurned keeps the turned picture on its tile every frame (the columns scroll, the windows move): it
 * shows where the fallback would show - shown, faded as it is, wholly inside every group it lies in, under no
 * kit window, inspect or comparison card that lies over the tile - and the fallback is made see-through
 * meanwhile. Where it cannot show (a tile half scrolled out of its column, under a window) the fallback shows
 * upright as before. Only turned tiles get this: one more control, one more record looked at per frame.
 *
 * Only on the inventory's own display (or one that attached to it, fnc_attach), whose frame (fnc_onFrame) keeps
 * the pictures in place; anywhere else (the setup wizard's preview) the tile keeps its upright picture.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Grid, see fnc_createGrid <HASHMAP>
 * 2: The box the picture is fitted into, [x, y, w, h], in the grid's parent's space <ARRAY>
 * 3: Texture <STRING>
 * 4: The icon, [scale, across, down] <ARRAY>
 * 5: The rectangle it must stay in (the tile's), [x, y, w, h], in the same space <ARRAY>
 * 6: The fallback, what fnc_uiItemPicture returned (the picture, or the group that clips it) <CONTROL>
 *
 * Return Value:
 * The turned picture, or controlNull where none is made <CONTROL>
 *
 * Example:
 * [_display, _grid, _box, _picture, ICON_PLAIN, _tileRect, _fallback] call einv_gui_fnc_turnPicture;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_grid", "_box", "_texture", ["_icon", ICON_PLAIN, [[]]], "_clip", "_fallback"];

if (
    isNull _fallback || {_display isNotEqualTo (uiNamespace getVariable [QGVAR(display), displayNull])}
    || {([_texture] call FUNC(safePicture)) isEqualTo ""}
) exitWith {controlNull};

private _parent = _grid getOrDefault ["parent", controlNull];

// Where the grid's parent's space lies on the screen now (as fnc_gridOrigin counts it).
([createHashMapFromArray [["rel", [0, 0]], ["parent", _parent]]] call FUNC(gridOrigin)) params ["_originX", "_originY"];

_box params ["_boxX", "_boxY", "_boxW", "_boxH"];
_clip params ["_clipX", "_clipY", "_clipW", "_clipH"];

private _overlay = [
    _display, controlNull, [_boxX + _originX, _boxY + _originY, _boxW, _boxH], _texture, [1, 1, 1, 1], _icon,
    [_clipX + _originX, _clipY + _originY, _clipW, _clipH]
] call FUNC(uiPictureTurned);

_overlay ctrlShow false;

// It lies over the column on the display: disabled, so the mouse and the wheel reach the tile and the column
// under it as they reach the upright picture.
_overlay ctrlEnable false;

// Its middle in the grid's parent's space: where it goes when that space has moved.
(ctrlPosition _overlay) params ["_overlayX", "_overlayY", "_overlayW", "_overlayH"];

private _inner = _fallback getVariable [QGVAR(inner), _fallback];

// [turned, fallback, its picture, its colour, the group the tile lies in, middle, state]
private _record = [
    _overlay, _fallback, _inner, ctrlTextColor _inner, _parent,
    [_overlayX + _overlayW / 2 - _originX, _overlayY + _overlayH / 2 - _originY], []
];

private _list = uiNamespace getVariable [QGVAR(turnedPictures), []];

_list pushBack _record;
uiNamespace setVariable [QGVAR(turnedPictures), _list];

// In place at once, not a frame later: no upright flash at every redraw.
[[_record]] call FUNC(syncTurned);

_overlay
