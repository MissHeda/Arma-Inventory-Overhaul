#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * A canvas of cells to draw on, the way cells are picked on a sheet: the one widget the Items step draws
 * an item's shape on (fnc_drawItemEditor) and the Containers step paints a container's compartments on
 * (fnc_drawCellEditor).
 *   - Cells (the Items step): a click on a place makes it a cell - filled dark - or takes the cell away
 *     again - light. The item's picture lies faintly over the box of its cells.
 *   - Painted (the Containers step, "palette"): a click paints the place in the brush's colour
 *     (GVAR(cellBrush), 1 to PAINT_COUNT) - or takes the colour away, when it already has that one or the
 *     brush is "none" (0). With the button held, the mouse paints every place it passes the same way, as
 *     the first one went: from a cell of the brush's colour it rubs out, from any other it paints. Cells
 *     of one colour that touch are one compartment (fnc_canvasBlocks).
 * Taller than its place, it scrolls.
 *
 * A click changes the canvas in place and only the controls of that place, at once - a canvas of 40
 * rows has 800 controls, too many to make anew for every click -, then calls the caller's code with
 * it, which redraws what depends on it. Painting starts on the button's press, not its release, so a
 * stroke that ends on another place still paints the first; the press and every place the mouse enters
 * while the left button is down (inputMouse) hand their change to fnc_defer, as every click of the
 * wizard does - the caller's code may draw the editor again. Where the engine gives no press to a
 * button, the click alone still paints: the press marks the place, so a click after a press does
 * nothing more.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group to create it in <CONTROL>
 * 2: Position [x, y, w, h], relative to the group <ARRAY>
 * 3: Canvas, see fnc_canvasFromBlocks - changed by the clicks <HASHMAP>
 * 4: Theme <HASHMAP>
 * 5: Options <HASHMAP> (default: none)
 *    "cellH"     - a place's height, the pixel to the next one included <NUMBER> (default: UNIT * 0.95)
 *    "palette"   - painted in colours: the canvas's "paint" instead of its "cells" <BOOL> (default: false)
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
 * [_display, _box, [0, 0.1, 0.2, 0.3], _canvas, _theme, createHashMapFromArray [["palette", true]]] call einv_setup_fnc_uiCanvas;
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
private _palette = _options getOrDefault ["palette", false];
private _values = if (_palette) then {
    _canvas getOrDefault ["paint", []]
} else {
    (_canvas getOrDefault ["cells", []]) apply {parseNumber _x}
};
private _cellH = _options getOrDefault ["cellH", UNIT * 0.95];
private _cellW = SQUARE(_cellH);
private _editable = _options getOrDefault ["editable", true];
private _picture = _options getOrDefault ["picture", ""];

private _group = [_display, "EINV_ScrollGroup", _parent, _rect] call EFUNC(gui,uiCreate);

_group setVariable [QGVAR(scrollId), _options getOrDefault ["scrollId", ""]];
_group setVariable [QGVAR(canvas), _canvas];
_group setVariable [QGVAR(canvasOptions), _options];

// A place's colour and its colour under the mouse, by what it holds: a colour of the palette, or dark
// for a cell, light for none.
private _fnc_colors = {
    params ["_value", "_palette"];

    switch (true) do {
        case (_value <= 0): {[CANVAS_OFF, CANVAS_OFF_HOVER]};
        case (_palette): {[PAINT_COLORS select (_value - 1), PAINT_HOVER select (_value - 1)]};
        default {[CANVAS_ON, CANVAS_ON_HOVER]};
    }
};

_group setVariable [QGVAR(canvasColors), _fnc_colors];

// The places, then the picture over them, then what is clicked: a control made later lies on top and
// takes the click.
private _panels = [];

for "_index" from 0 to (_cols * _rows - 1) do {
    private _place = [(_index mod _cols) * _cellW, floor (_index / _cols) * _cellH, _cellW - pixelW, _cellH - pixelH];

    _panels pushBack ([_display, _group, _place, ([_values param [_index, 0], _palette] call _fnc_colors) select 0] call EFUNC(gui,uiPanel));
};

if (_picture isNotEqualTo "" && {!_palette}) then {
    ([_canvas] call FUNC(canvasBox)) params ["_boxCol", "_boxRow", "_boxW", "_boxH"];

    private _ctrl = [
        _display, _group, [_boxCol * _cellW, _boxRow * _cellH, (_boxW * _cellW - pixelW) max 0, (_boxH * _cellH - pixelH) max 0], _picture, [1, 1, 1, 0.4]
    ] call EFUNC(gui,uiPicture);

    _ctrl ctrlShow (_boxW > 0);
    _group setVariable [QGVAR(canvasPicture), _ctrl];
};

if (!_editable) exitWith {_group};

// A place changes to a value: a cell (1) or none (0), or a colour. Its controls at once, then the
// caller's code.
private _set = {
    params ["_group", "_index", "_hit", "_value"];

    if (isNull _group) exitWith {};

    private _canvas = _group getVariable [QGVAR(canvas), createHashMap];
    private _options = _group getVariable [QGVAR(canvasOptions), createHashMap];
    private _palette = _options getOrDefault ["palette", false];
    private _list = _canvas getOrDefault [["cells", "paint"] select _palette, []];

    if (_index >= count _list) exitWith {};

    private _old = _list select _index;
    private _new = [_value > 0, _value] select _palette;

    if (_old isEqualTo _new) exitWith {};

    _list set [_index, _new];

    if (!isNull _hit) then {
        private _panel = ((_hit getVariable [QGVAR(surface), [[]]]) select 0) param [0, controlNull];

        ([_value, _palette] call (_group getVariable [QGVAR(canvasColors), {[[], []]}])) params ["_normal", "_hover"];

        // Lit while the mouse is still on it: a stroke may have moved on by the time this runs.
        _panel ctrlSetBackgroundColor ([_normal, _hover] select (_hit getVariable [QGVAR(over), false]));
        _hit setVariable [QGVAR(surface), [[_panel], _normal, _hover]];
    };

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

_group setVariable [QGVAR(canvasSet), _set];

// What a click on a place turns it into: a cell becomes none and none a cell; painted, the brush's
// colour, or none where it has that colour already.
private _fnc_target = {
    params ["_group", "_index"];

    private _canvas = _group getVariable [QGVAR(canvas), createHashMap];

    if !((_group getVariable [QGVAR(canvasOptions), createHashMap]) getOrDefault ["palette", false]) exitWith {
        parseNumber !((_canvas getOrDefault ["cells", []]) param [_index, false])
    };

    private _brush = GVAR(cellBrush);

    [_brush, 0] select (_brush > 0 && {((_canvas getOrDefault ["paint", []]) param [_index, 0]) == _brush})
};

_group setVariable [QGVAR(canvasTarget), _fnc_target];

{
    ([_values param [_forEachIndex, 0], _palette] call _fnc_colors) params ["_normal", "_hover"];

    private _hit = [_display, _group, ctrlPosition (_x select 0), _x, _normal, _hover] call FUNC(uiHit);

    _hit setVariable [QGVAR(canvasPlace), [_group, _forEachIndex]];

    // The click, where no press came before it.
    _hit setVariable [QGVAR(action), [{
        params ["_hit"];

        if (isNull _hit) exitWith {};

        if (_hit getVariable [QGVAR(pressed), false]) exitWith {
            _hit setVariable [QGVAR(pressed), false];
        };

        (_hit getVariable [QGVAR(canvasPlace), []]) params [["_group", controlNull], ["_index", -1]];

        if (isNull _group) exitWith {};

        [_group, _index, _hit, [_group, _index] call (_group getVariable [QGVAR(canvasTarget), {0}])] call (_group getVariable [QGVAR(canvasSet), {}]);
    }, [_hit]]];

    // The press: the stroke takes this place's change along.
    _hit ctrlAddEventHandler ["MouseButtonDown", {
        params ["_hit", "_button"];

        if (_button != 0) exitWith {};

        (_hit getVariable [QGVAR(canvasPlace), []]) params [["_group", controlNull], ["_index", -1]];

        if (isNull _group) exitWith {};

        private _value = [_group, _index] call (_group getVariable [QGVAR(canvasTarget), {0}]);

        _hit setVariable [QGVAR(pressed), true];
        uiNamespace setVariable [QGVAR(canvasStroke), [_group getVariable [QGVAR(scrollId), ""], _value]];

        [_group getVariable [QGVAR(canvasSet), {}], [_group, _index, _hit, _value]] call FUNC(defer);
    }];

    // Entered with the left button down: the stroke goes on here. Up, the stroke is over.
    _hit ctrlAddEventHandler ["MouseEnter", {
        params ["_hit"];

        _hit setVariable [QGVAR(over), true];

        private _stroke = uiNamespace getVariable [QGVAR(canvasStroke), []];

        if (_stroke isEqualTo []) exitWith {};

        if (inputMouse 0 == 0) exitWith {
            uiNamespace setVariable [QGVAR(canvasStroke), []];
        };

        (_hit getVariable [QGVAR(canvasPlace), []]) params [["_group", controlNull], ["_index", -1]];
        _stroke params ["_scrollId", "_value"];

        // A stroke stays on its canvas, known by its scroll id: the first place may have drawn the editor
        // again (the working copy made), and the canvas under the mouse is a new control then.
        if (isNull _group || {(_group getVariable [QGVAR(scrollId), ""]) isNotEqualTo _scrollId}) exitWith {};

        [_group getVariable [QGVAR(canvasSet), {}], [_group, _index, _hit, _value]] call FUNC(defer);
    }];

    _hit ctrlAddEventHandler ["MouseExit", {
        params ["_hit"];

        _hit setVariable [QGVAR(over), false];
    }];

    _hit ctrlAddEventHandler ["MouseButtonUp", {
        uiNamespace setVariable [QGVAR(canvasStroke), []];
    }];
} forEach _panels;

_group
