#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Follows the mouse while a frame is dragged out from an empty cell (fnc_startBand), every frame: the
 * frame runs from the press point - which moves with the column when the column scrolls - to the mouse,
 * cut off at the column's edges, and the column itself scrolls when the mouse is at its top or bottom
 * edge, as it does for a drag. The tiles of that column the frame touches are shown as selected
 * (fnc_drawSelection) - they become the selection when the button comes up (fnc_endBand).
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Mouse position [x, y] <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, getMousePosition] call einv_gui_fnc_updateBand;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_mouse"];
_mouse params ["_mouseX", "_mouseY"];

if (!GVAR(band) || {GVAR(bandPress) isEqualTo []}) exitWith {};

GVAR(bandPress) params ["_group", "_start", "_scrollAtPress"];

if (isNull _group) exitWith {
    [_display] call FUNC(endBand);
};

(call FUNC(getCell)) params ["", "_cellH"];

// Where the column shows on the screen.
(ctrlPosition _group) params ["_groupRelX", "_groupRelY", "_groupW", "_groupH"];
([createHashMapFromArray [["rel", [_groupRelX, _groupRelY]], ["parent", ctrlParentControlsGroup _group]]] call FUNC(gridOrigin)) params ["_groupX", "_groupY"];

// At the top or bottom edge the column scrolls, as it does for a dragged item (fnc_updateDrag).
private _range = (_group getVariable [QGVAR(contentH), _groupH]) - _groupH;

if (_range > 0) then {
    private _band = _cellH * 0.6;
    private _now = ((ctrlScrollValues _group) select 0) max 0;
    private _want = _now;
    private _step = _cellH * 10 * diag_deltaTime / _range;

    if (_mouseY >= _groupY && {_mouseY < _groupY + _band} && {_mouseX >= _groupX} && {_mouseX < _groupX + _groupW}) then {
        _want = (_now - _step) max 0;
    };

    if (_mouseY > _groupY + _groupH - _band && {_mouseY <= _groupY + _groupH} && {_mouseX >= _groupX} && {_mouseX < _groupX + _groupW}) then {
        _want = (_now + _step) min 1;
    };

    if (abs (_want - _now) > 0.00001) then {
        _group ctrlSetScrollValues [_want, -1];
    };
};

// The press point lies on the content, so it moves with the scrolling.
private _startX = _start select 0;
private _startY = (_start select 1) + _scrollAtPress - ([_group] call FUNC(scrollPixels));

private _left = ((_startX min _mouseX) max _groupX) min (_groupX + _groupW);
private _right = ((_startX max _mouseX) max _groupX) min (_groupX + _groupW);
private _top = ((_startY min _mouseY) max _groupY) min (_groupY + _groupH);
private _bottom = ((_startY max _mouseY) max _groupY) min (_groupY + _groupH);

private _rect = [_left, _top, (_right - _left) max 0, (_bottom - _top) max 0];

{
    _x ctrlSetPosition _rect;
    _x ctrlCommit 0;
    _x ctrlShow true;
} forEach (uiNamespace getVariable [QGVAR(bandFrame), []]);

// The tiles of this column it touches.
private _touched = [];

{
    private _gridIndex = _forEachIndex;
    private _grid = _x;

    if (
        (_grid getOrDefault ["parent", controlNull]) isNotEqualTo _group || {_grid getOrDefault ["virtual", true]}
        || {_grid getOrDefault ["overflow", false]}
    ) then {continue};

    {
        if (_x getOrDefault ["hidden", false] || {_x getOrDefault ["pending", false]}) then {continue};

        private _tileRect = [_grid, _x] call FUNC(tileRect);
        private _holes = _x getOrDefault ["holes", []];

        // A shaped tile (size=xx/x-) is touched on its own cells only, not in the corner an L leaves open.
        // Cut at the grid's edge it is drawn as its box (fnc_createTile), and touched as one.
        private _rects = if (_holes isEqualTo [] || {(_x get "col") + (_x get "w") > (_grid get "cols")}) then {
            [_tileRect]
        } else {
            [[_tileRect select 0, _tileRect select 1], _grid get "cellW", _grid get "cellH", [_x get "w", _x get "h", _holes]] call FUNC(shapeRects)
        };

        if (_rects findIf {
            _x params ["_tileX", "_tileY", "_tileW", "_tileH"];

            _tileX < _right && {_tileX + _tileW > _left} && {_tileY < _bottom} && {_tileY + _tileH > _top}
        } >= 0) then {
            _touched pushBack [_gridIndex, _forEachIndex];
        };
    } forEach (_grid getOrDefault ["tiles", []]);
} forEach (uiNamespace getVariable [QGVAR(grids), []]);

if (_touched isNotEqualTo GVAR(bandTiles)) then {
    GVAR(bandTiles) = _touched;
    [_touched] call FUNC(drawSelection);
};
