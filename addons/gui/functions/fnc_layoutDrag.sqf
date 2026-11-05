#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Moves or resizes a column's frame in the edit mode (fnc_openLayoutEditor), as the sliders of the settings card follow the mouse
 * (fnc_sizeSlide): from the press, with the display's mouse handlers, a light box shows where it would go, on a grid of half a UNIT;
 * at the release its place goes to aio_gui_layoutRects, as shares of the content area (fnc_columnRects), written to CBA, and the
 * window is built again. It stays on the screen and no smaller than fnc_columnMinimum says.
 *
 * Arguments:
 * 0: What: "begin" [display, [column, "move" or a corner "tl", "tr", "bl", "br"], layer], "move", "up", "end" (without writing), "reset",
 *    or "step" [index of the size, step] for the size buttons of the edit mode's bar <STRING>
 * 1: Its argument <ANY> (default: [])
 *
 * Return Value:
 * None
 *
 * Example:
 * ["reset"] call aio_gui_fnc_layoutDrag;
 *
 * Public: No
 */

disableSerialization;

params [["_what", "", [""]], ["_argument", []]];

private _fnc_write = {
    params ["_value"];

    missionNamespace setVariable [QGVAR(layoutRects), _value];

    if (!isNil "CBA_settings_fnc_set") then {
        [QGVAR(layoutRects), _value, 0, "client"] call CBA_settings_fnc_set;
    };

    [] call FUNC(elementsChanged);
};

// Where the frame would be with the mouse where it is.
private _fnc_rect = {
    params ["_state"];
    _state params ["", "_id", "_mode", "_startMouse", "_startRect"];
    _startRect params ["_x0", "_y0", "_w0", "_h0"];

    private _mouse = getMousePosition;
    private _snapH = UNIT * 0.5;
    private _snapW = SQUARE(_snapH);
    private _dx = (round (((_mouse select 0) - (_startMouse select 0)) / _snapW)) * _snapW;
    private _dy = (round (((_mouse select 1) - (_startMouse select 1)) / _snapH)) * _snapH;

    (call FUNC(getCell)) params ["_cellW"];
    ([_id, COLUMN_W(_cellW)] call FUNC(columnMinimum)) params ["_leastW", "_leastH"];

    private _right = _x0 + _w0;
    private _bottom = _y0 + _h0;

    if (_mode isEqualTo "move") exitWith {
        [
            ((_x0 + _dx) max CONTENT_X) min (CONTENT_X + CONTENT_W - _w0),
            ((_y0 + _dy) max CONTENT_Y) min (CONTENT_B - _h0),
            _w0,
            _h0
        ]
    };

    private _left = _x0;
    private _top = _y0;

    if (_mode in ["tl", "bl"]) then {
        _left = ((_x0 + _dx) max CONTENT_X) min (_right - _leastW);
    } else {
        _right = ((_right + _dx) min (CONTENT_X + CONTENT_W)) max (_left + _leastW);
    };

    if (_mode in ["tl", "tr"]) then {
        _top = ((_y0 + _dy) max CONTENT_Y) min (_bottom - _leastH);
    } else {
        _bottom = ((_bottom + _dy) min CONTENT_B) max (_top + _leastH);
    };

    [_left, _top, _right - _left, _bottom - _top]
};

private _fnc_stop = {
    private _state = uiNamespace getVariable [QGVAR(layoutDragState), []];

    uiNamespace setVariable [QGVAR(layoutDragState), []];

    if (_state isEqualTo []) exitWith {};

    _state params ["_display", "", "", "", "", "_ghost", "_ids"];

    ctrlDelete _ghost;

    if (!isNull _display) then {
        _display displayRemoveEventHandler ["MouseMoving", _ids select 0];
        _display displayRemoveEventHandler ["MouseHolding", _ids select 1];
        _display displayRemoveEventHandler ["MouseButtonUp", _ids select 2];
    };
};

switch (_what) do {
    case "move": {
        private _state = uiNamespace getVariable [QGVAR(layoutDragState), []];

        if (_state isEqualTo []) exitWith {};

        ([_state] call _fnc_rect) params ["_x0", "_y0", "_w", "_h"];

        private _ghost = _state select 5;

        _ghost ctrlSetPosition [_x0 - safezoneX, _y0 - safezoneY, _w, _h];
        _ghost ctrlCommit 0;
    };

    case "up": {
        // Only the left button ends it.
        if ((_argument param [1, 0]) != 0) exitWith {};

        private _state = uiNamespace getVariable [QGVAR(layoutDragState), []];

        if (_state isEqualTo []) exitWith {};

        private _rect = [_state] call _fnc_rect;
        private _unmoved = _rect isEqualTo (_state select 4);
        private _id = _state select 1;

        [] call _fnc_stop;

        if (_unmoved) exitWith {};

        _rect params ["_x0", "_y0", "_w", "_h"];

        // This column's shares, the others as they are.
        private _entries = ((missionNamespace getVariable [QGVAR(layoutRects), ""]) splitString ";") select {((_x splitString ":") param [0, ""]) isNotEqualTo _id};

        _entries pushBack format [
            "%1:%2,%3,%4,%5", _id,
            ((_x0 - CONTENT_X) / CONTENT_W) toFixed 4, ((_y0 - CONTENT_Y) / CONTENT_H) toFixed 4,
            (_w / CONTENT_W) toFixed 4, (_h / CONTENT_H) toFixed 4
        ];

        [_entries joinString ";"] call _fnc_write;
    };

    case "end": {
        [] call _fnc_stop;
    };

    case "step": {
        // On the next frame: the window is built again, and this press must not delete what it was pressed on.
        [{
            params ["_index", "_step"];

            ["value", [_index, ([_index] call FUNC(sizeValue)) + _step]] call FUNC(sizeSet);
            ["commit"] call FUNC(sizeSet);
        }, _argument] call FUNC(later);
    };

    case "reset": {
        [] call _fnc_stop;
        [""] call _fnc_write;
    };

    case "begin": {
        _argument params ["_display", ["_drag", []], "_layer"];
        _drag params [["_id", ""], ["_mode", "move"]];

        [] call _fnc_stop;

        if (isNull _display || {_id isEqualTo ""}) exitWith {};

        private _start = ([true] call FUNC(columnRects)) get _id;
        private _accent = (GVAR(theme) getOrDefault ["accent", [0.84, 0.54, 0.1, 1]]) select [0, 3];
        private _ghost = [
            _display, "AIO_PanelRect", _layer,
            [(_start select 0) - safezoneX, (_start select 1) - safezoneY, _start select 2, _start select 3]
        ] call FUNC(uiCreate);

        _ghost ctrlSetBackgroundColor (_accent + [0.45]);
        _ghost ctrlEnable false;

        private _ids = [
            _display displayAddEventHandler ["MouseMoving", {["move", _this] call FUNC(layoutDrag); false}],
            _display displayAddEventHandler ["MouseHolding", {["move", _this] call FUNC(layoutDrag); false}],
            _display displayAddEventHandler ["MouseButtonUp", {["up", _this] call FUNC(layoutDrag); false}]
        ];

        uiNamespace setVariable [QGVAR(layoutDragState), [_display, _id, _mode, getMousePosition, _start, _ghost, _ids]];
    };
};
