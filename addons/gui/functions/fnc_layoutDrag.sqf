#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Moves or resizes a frame in the edit mode (fnc_openLayoutEditor) - a column, or a part of the equipment column - as a window on
 * the desktop: its title or body moves it, an edge resizes it one way, a corner both. From the press, with the display's mouse
 * handlers, an outline follows the mouse with the size it would have, on a grid of a quarter UNIT; nothing is built until the
 * release. Then its place goes to aio_gui_layoutRects, as shares of the content area (fnc_columnRects), written to CBA, and the window
 * is built again. It stays on the screen and no smaller than fnc_columnMinimum says.
 *
 * A part of the equipment column moved out of it stands on its own from then on (fnc_layoutGlass); "attach" puts it back.
 *
 * Arguments:
 * 0: What: "begin" [display, [id, mode, start rect], layer] - mode "move", a corner "tl", "tr", "bl", "br" or an edge "l", "r",
 *    "t", "b" -, "move", "up", "end" (without writing), "reset", "attach" [id], "front" or "back" [id, ids drawn] for the layer
 *    order (fnc_layerOrder), or "step" [index of the size, step] for the size buttons of the edit mode's bar <STRING>
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
        [QGVAR(layoutRects), _value, 0, "client", true] call CBA_settings_fnc_set;
    };

    [] call FUNC(elementsChanged);
};

// The entries of aio_gui_layoutRects but the one for this id.
private _fnc_others = {
    params ["_id"];

    ((missionNamespace getVariable [QGVAR(layoutRects), ""]) splitString ";") select {((_x splitString ":") param [0, ""]) isNotEqualTo _id}
};

// Where the frame would be with the mouse where it is.
private _fnc_rect = {
    params ["_state"];
    _state params ["", "", "_mode", "_startMouse", "_startRect", "", "", "_least"];
    _startRect params ["_x0", "_y0", "_w0", "_h0"];
    _least params ["_leastW", "_leastH"];

    private _mouse = getMousePosition;
    private _snapH = UNIT * 0.25;
    private _snapW = SQUARE(_snapH);
    private _dx = (round (((_mouse select 0) - (_startMouse select 0)) / _snapW)) * _snapW;
    private _dy = (round (((_mouse select 1) - (_startMouse select 1)) / _snapH)) * _snapH;

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
    private _right = _x0 + _w0;
    private _bottom = _y0 + _h0;

    if (_mode in ["tl", "bl", "l"]) then {
        _left = ((_x0 + _dx) max CONTENT_X) min (_right - _leastW);
    };

    if (_mode in ["tr", "br", "r"]) then {
        _right = ((_right + _dx) min (CONTENT_X + CONTENT_W)) max (_left + _leastW);
    };

    if (_mode in ["tl", "tr", "t"]) then {
        _top = ((_y0 + _dy) max CONTENT_Y) min (_bottom - _leastH);
    };

    if (_mode in ["bl", "br", "b"]) then {
        _bottom = ((_bottom + _dy) min CONTENT_B) max (_top + _leastH);
    };

    [_left, _top, _right - _left, _bottom - _top]
};

// The outline: a film, four lines and the size, placed on the layer (screen less the safe zone's corner).
private _fnc_place = {
    params ["_ghost", "_rect"];
    _ghost params ["_fill", "_lines", "_size"];
    _rect params ["_x0", "_y0", "_w", "_h"];

    private _left = _x0 - safezoneX;
    private _top = _y0 - safezoneY;
    private _lineW = pixelW * 2;
    private _lineH = pixelH * 2;

    _fill ctrlSetPosition [_left, _top, _w, _h];

    {
        (_lines select _forEachIndex) ctrlSetPosition _x;
    } forEach [
        [_left, _top, _w, _lineH],
        [_left, _top + _h - _lineH, _w, _lineH],
        [_left, _top, _lineW, _h],
        [_left + _w - _lineW, _top, _lineW, _h]
    ];

    // The size in UNITs, as the tiles count it: what the frame would be.
    _size ctrlSetPosition [_left, _top + _h / 2 - UNIT * 0.4, _w, UNIT * 0.8];
    _size ctrlSetText format ["%1 x %2", (_w / SQUARE(UNIT)) toFixed 1, (_h / UNIT) toFixed 1];

    {_x ctrlCommit 0} forEach ([_fill, _size] + _lines);
};

private _fnc_stop = {
    private _state = uiNamespace getVariable [QGVAR(layoutDragState), []];

    uiNamespace setVariable [QGVAR(layoutDragState), []];

    if (_state isEqualTo []) exitWith {};

    _state params ["_display", "", "", "", "", "_ghost", "_ids"];

    _ghost params ["_fill", "_lines", "_size"];

    {ctrlDelete _x} forEach ([_fill, _size] + _lines);

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

        private _rect = [_state] call _fnc_rect;

        // Only where it changed: the mouse events come many to a frame.
        if (_rect isEqualTo (_state select 8)) exitWith {};

        _state set [8, _rect];
        [_state select 5, _rect] call _fnc_place;
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

        // This frame's shares, the others as they are.
        private _entries = [_id] call _fnc_others;

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

    case "attach": {
        _argument params [["_id", "", [""]]];

        [] call _fnc_stop;
        [([_id] call _fnc_others) joinString ";"] call _fnc_write;
    };

    case "front";
    case "back": {
        _argument params [["_id", "", [""]], ["_ids", [], [[]]]];

        private _order = ([_ids] call FUNC(layerOrder)) - [_id];

        if (_what isEqualTo "front") then {
            _order pushBack _id;
        } else {
            _order = [_id] + _order;
        };

        private _entries = ["order"] call _fnc_others;

        _entries pushBack format ["order:%1", _order joinString ","];

        [] call _fnc_stop;
        [_entries joinString ";"] call _fnc_write;
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
        _drag params [["_id", ""], ["_mode", "move"], ["_start", []]];

        [] call _fnc_stop;

        if (isNull _display || {_id isEqualTo ""} || {count _start != 4}) exitWith {};

        (call FUNC(getCell)) params ["_cellW"];

        private _least = [_id, COLUMN_W(_cellW)] call FUNC(columnMinimum);
        private _accent = (GVAR(theme) getOrDefault ["accent", [0.84, 0.54, 0.1, 1]]) select [0, 3];
        private _fill = [_display, "AIO_PanelRect", _layer, [0, 0, 0, 0]] call FUNC(uiCreate);

        _fill ctrlSetBackgroundColor (_accent + [0.18]);
        _fill ctrlEnable false;

        private _lines = [0, 1, 2, 3] apply {
            private _line = [_display, "AIO_PanelRect", _layer, [0, 0, 0, 0]] call FUNC(uiCreate);

            _line ctrlSetBackgroundColor (_accent + [1]);
            _line ctrlEnable false;
            _line
        };

        private _font = GVAR(theme) getOrDefault ["fontBold", "PuristaSemibold"];
        private _size = [_display, _layer, [0, 0, 0, 0], "", UNIT * 0.6, [1, 1, 1, 1], _font, 2, "never"] call FUNC(uiLabel);

        _size ctrlEnable false;

        private _ghost = [_fill, _lines, _size];

        [_ghost, _start] call _fnc_place;

        private _ids = [
            _display displayAddEventHandler ["MouseMoving", {["move", _this] call FUNC(layoutDrag); false}],
            _display displayAddEventHandler ["MouseHolding", {["move", _this] call FUNC(layoutDrag); false}],
            _display displayAddEventHandler ["MouseButtonUp", {["up", _this] call FUNC(layoutDrag); false}]
        ];

        uiNamespace setVariable [QGVAR(layoutDragState), [_display, _id, _mode, getMousePosition, _start, _ghost, _ids, _least, _start]];
    };
};
