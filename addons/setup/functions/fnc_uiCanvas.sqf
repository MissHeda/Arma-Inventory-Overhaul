#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * A canvas of cells to draw on, the way cells are picked on a sheet: the one widget the Items step draws
 * an item's shape on (fnc_drawItemEditor) and the Containers step a container's compartments
 * (fnc_drawCellEditor).
 *   - A click on a place makes it a cell - filled dark - or takes the cell away again - light.
 *   - With dividers (the Containers step), a click on the gap between two places puts a divider on that
 *     seam - drawn as a line in the accent - or takes it away. The gap reaches CANVAS_SEAM_REACH of a cell
 *     into each place beside it, so it is not a pixel to aim at; the corners stay the places'. Cells that
 *     touch with no divider between them are one compartment (fnc_canvasBlocks).
 *   - With a picture (the Items step), the item's picture lies faintly over the box of its cells.
 * Taller than its place, it scrolls.
 *
 * A click changes the canvas in place and only the controls of that place or seam, at once - a canvas of
 * 40 rows has well over a thousand controls, too many to make anew for every click -, then calls the
 * caller's code with it, which redraws what depends on it.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group to create it in <CONTROL>
 * 2: Position [x, y, w, h], relative to the group <ARRAY>
 * 3: Canvas, see fnc_canvasFromBlocks - changed by the clicks <HASHMAP>
 * 4: Theme <HASHMAP>
 * 5: Options <HASHMAP> (default: none)
 *    "cellH"     - a place's height, the pixel to the next one included <NUMBER> (default: UNIT * 0.95)
 *    "dividers"  - the seams take dividers <BOOL> (default: false)
 *    "editable"  - clicks change it; else it is only shown <BOOL> (default: true)
 *    "picture"   - drawn faintly over the box of its cells <STRING> (default: "")
 *    "onChange"  - called after a click changed it, with [canvas, arguments] <CODE> (default: {})
 *    "arguments" - for that <ANY> (default: [])
 *    "scrollId"  - its scroll position kept under this name when the step is drawn again <STRING> (default: "")
 *
 * Return Value:
 * Its group <CONTROL>
 *
 * Example:
 * [_display, _box, [0, 0.1, 0.2, 0.3], _canvas, _theme, createHashMapFromArray [["dividers", true]]] call einv_setup_fnc_uiCanvas;
 *
 * Public: No
 */

disableSerialization;

params [
    "_display", "_parent", "_rect", ["_canvas", createHashMap, [createHashMap]],
    ["_theme", createHashMap, [createHashMap]], ["_options", createHashMap, [createHashMap]]
];

private _cols = _canvas getOrDefault ["cols", STORAGE_COLS];
private _rows = _canvas getOrDefault ["rows", 1];
private _cells = _canvas getOrDefault ["cells", []];
private _right = _canvas getOrDefault ["right", []];
private _below = _canvas getOrDefault ["below", []];
private _cellH = _options getOrDefault ["cellH", UNIT * 0.95];
private _cellW = SQUARE(_cellH);
private _dividers = _options getOrDefault ["dividers", false];
private _editable = _options getOrDefault ["editable", true];
private _picture = _options getOrDefault ["picture", ""];
private _accent = _theme getOrDefault ["accent", [0.84, 0.54, 0.1, 1]];
private _clear = [0, 0, 0, 0];

private _group = [_display, "EINV_ScrollGroup", _parent, _rect] call EFUNC(gui,uiCreate);

_group setVariable [QGVAR(scrollId), _options getOrDefault ["scrollId", ""]];
_group setVariable [QGVAR(canvas), _canvas];
_group setVariable [QGVAR(canvasOptions), _options];

// The places, then the picture over them, then what is clicked: a control made later lies on top and
// takes the click, so the seams' strips go last, over the edges of the places.
private _panels = [];

for "_index" from 0 to (_cols * _rows - 1) do {
    private _place = [(_index mod _cols) * _cellW, floor (_index / _cols) * _cellH, _cellW - pixelW, _cellH - pixelH];

    _panels pushBack ([_display, _group, _place, [CANVAS_OFF, CANVAS_ON] select (_cells select _index)] call EFUNC(gui,uiPanel));
};

if (_picture isNotEqualTo "") then {
    ([_canvas] call FUNC(canvasBox)) params ["_boxCol", "_boxRow", "_boxW", "_boxH"];

    private _ctrl = [
        _display, _group, [_boxCol * _cellW, _boxRow * _cellH, (_boxW * _cellW - pixelW) max 0, (_boxH * _cellH - pixelH) max 0], _picture, [1, 1, 1, 0.4]
    ] call EFUNC(gui,uiPicture);

    _ctrl ctrlShow (_boxW > 0);
    _group setVariable [QGVAR(canvasPicture), _ctrl];
};

// A click: the cell or divider turns over, its controls at once, then the caller's code.
private _click = {
    params ["_group", "_key", "_index", "_hit"];

    private _canvas = _group getVariable [QGVAR(canvas), createHashMap];
    private _options = _group getVariable [QGVAR(canvasOptions), createHashMap];
    private _list = _canvas getOrDefault [_key, []];

    if (_index >= count _list) exitWith {};

    private _on = !(_list select _index);

    _list set [_index, _on];

    private _panel = ((_hit getVariable [QGVAR(surface), [[]]]) select 0) param [0, controlNull];
    private _normal = [CANVAS_OFF, CANVAS_ON] select _on;
    private _hover = [CANVAS_OFF_HOVER, CANVAS_ON_HOVER] select _on;

    if (_key isNotEqualTo "cells") then {
        private _accent = GVAR(theme) getOrDefault ["accent", [0.84, 0.54, 0.1, 1]];
        private _faint = +_accent;

        _faint set [3, CANVAS_SEAM_HOVER];
        _normal = [[0, 0, 0, 0], _accent] select _on;
        _hover = [_faint, ACCENT_HOVER] select _on;
    };

    // The mouse is still on it.
    _panel ctrlSetBackgroundColor _hover;
    _hit setVariable [QGVAR(surface), [[_panel], _normal, _hover]];

    // The picture follows the box of the cells.
    private _picture = _group getVariable [QGVAR(canvasPicture), controlNull];

    if (!isNull _picture) then {
        private _cellH = _options getOrDefault ["cellH", UNIT * 0.95];
        private _cellW = SQUARE(_cellH);

        ([_canvas] call FUNC(canvasBox)) params ["_boxCol", "_boxRow", "_boxW", "_boxH"];

        _picture ctrlSetPosition [_boxCol * _cellW, _boxRow * _cellH, (_boxW * _cellW - pixelW) max 0, (_boxH * _cellH - pixelH) max 0];
        _picture ctrlCommit 0;
        _picture ctrlShow (_boxW > 0);
    };

    [_canvas, _options getOrDefault ["arguments", []]] call (_options getOrDefault ["onChange", {}]);
};

if (_editable) then {
    {
        private _on = _cells select _forEachIndex;
        private _hit = [
            _display, _group, ctrlPosition (_x select 0), _x, [CANVAS_OFF, CANVAS_ON] select _on, [CANVAS_OFF_HOVER, CANVAS_ON_HOVER] select _on
        ] call FUNC(uiHit);

        _hit setVariable [QGVAR(action), [_click, [_group, "cells", _forEachIndex, _hit]]];
    } forEach _panels;
};

// The seams: a line where a divider lies - also on a canvas only shown -, and a strip on either side
// of it to click.
if (_dividers) then {
    private _faint = +_accent;

    _faint set [3, CANVAS_SEAM_HOVER];

    private _reachW = _cellW * CANVAS_SEAM_REACH;
    private _reachH = _cellH * CANVAS_SEAM_REACH;

    for "_index" from 0 to (_cols * _rows - 1) do {
        private _col = _index mod _cols;
        private _row = floor (_index / _cols);

        {
            _x params ["_key", "_list", "_exists", "_line", "_strip"];

            if (!_exists) then {continue};

            private _on = _list select _index;

            if (!_on && {!_editable}) then {continue};

            private _panel = [_display, _group, _line, [_clear, _accent] select _on] call EFUNC(gui,uiPanel);

            if (_editable) then {
                private _hit = [_display, _group, _strip, _panel, [_clear, _accent] select _on, [_faint, ACCENT_HOVER] select _on] call FUNC(uiHit);

                _hit setVariable [QGVAR(action), [_click, [_group, _key, _index, _hit]]];
            };
        } forEach [
            // The seam to its right: the line over the pixel between the two places and one either side.
            [
                "right", _right, _col < _cols - 1,
                [(_col + 1) * _cellW - pixelW * 2, _row * _cellH, pixelW * 3, _cellH - pixelH],
                [(_col + 1) * _cellW - pixelW - _reachW, _row * _cellH + _reachH, _reachW * 2 + pixelW, _cellH - _reachH * 2]
            ],
            // The seam under it.
            [
                "below", _below, _row < _rows - 1,
                [_col * _cellW, (_row + 1) * _cellH - pixelH * 2, _cellW - pixelW, pixelH * 3],
                [_col * _cellW + _reachW, (_row + 1) * _cellH - pixelH - _reachH, _cellW - _reachW * 2, _reachH * 2 + pixelH]
            ]
        ];
    };
};

_group
