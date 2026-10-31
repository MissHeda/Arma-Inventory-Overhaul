#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * A turn of the mouse wheel that a picture's clip group (fnc_uiItemPicture) took: the group lies over its tile
 * and, like every group nested in a scrolling column, keeps the wheel from the column (fnc_createGrid). So it
 * is handed on: the column the group lies in scrolls by WHEEL_STEP, up or down with the wheel, as far as its
 * content reaches. For the dragged ghost, which lies on the display, it is the column or kit window's body
 * under the mouse that the drag holds (fnc_startDrag, "dragScroll").
 *
 * The group scrolls by nothing of its own: the picture in it is larger than it, which makes it scrollable,
 * and a picture that scrolled off its tile would be a bug. Its scroll is put back to the top at every turn.
 *
 * Arguments:
 * 0: The clip group <CONTROL>
 * 1: The turn of the wheel, positive for up <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_group, 1] call einv_gui_fnc_passWheel;
 *
 * Public: No
 */

disableSerialization;

params [["_clip", controlNull, [controlNull]], ["_scroll", 0, [0]]];

if (isNull _clip || {_scroll == 0}) exitWith {};

_clip ctrlSetScrollValues [0, 0];

private _column = ctrlParentControlsGroup _clip;

// Held on the display: the scrolling group under the mouse, on the layer that lies on top there.
if (isNull _column) then {
    private _mouse = getMousePosition;
    private _onTop = [_mouse] call FUNC(topAt);

    {
        _x params ["_group", "", ["_layer", ""]];

        if (isNull _group || {_layer isNotEqualTo _onTop}) then {continue};

        (ctrlPosition _group) params ["_relX", "_relY", "_groupW", "_groupH"];
        ([createHashMapFromArray [["rel", [_relX, _relY]], ["parent", ctrlParentControlsGroup _group]]] call FUNC(gridOrigin)) params ["_groupX", "_groupY"];

        if ((_mouse select 0) >= _groupX && {(_mouse select 0) < _groupX + _groupW} && {(_mouse select 1) >= _groupY} && {(_mouse select 1) < _groupY + _groupH}) exitWith {
            _column = _group;
        };
    } forEach (uiNamespace getVariable [QGVAR(dragScroll), []]);
};

if (isNull _column || {ctrlType _column != 15}) exitWith {};

(ctrlPosition _column) params ["", "", "", "_height"];

private _range = (_column getVariable [QGVAR(contentH), _height]) - _height;

if (_range <= 0) exitWith {};

// A column made a moment ago has its place still to be put back (fnc_scrollPixels); a turn in that one frame is lost.
if ((uiNamespace getVariable [QGVAR(scrollRestore), []]) findIf {(_x select 0) isEqualTo _column} >= 0) exitWith {};

private _pixels = ([_column] call FUNC(scrollPixels)) - (_scroll / abs _scroll) * WHEEL_STEP;

_column ctrlSetScrollValues [((_pixels max 0) min _range) / _range, -1];
