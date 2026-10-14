#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Draws a container's compartments where fnc_flowCompartments put them, each a grid (fnc_createGrid)
 * with a tile for every entry lying in it, and what has no room on grids of its own in the loss colour.
 * A column's section (fnc_drawSection) and a kit's window (fnc_drawWindow) both draw their grids here.
 * A shaped compartment's holes (einv_storage_fnc_blocksFor) are drawn as no cell at all: no surface,
 * no line, nothing to hover (fnc_createGrid).
 *
 * Compartments drawn on a canvas (grid=aab/acc) touch, a cell's pitch apart like the cells of one
 * compartment. Each is a grid of its own, with "pos" where it lies on the canvas, and draws its cells and
 * its frame in by half the flow's gap on every cell side that borders another compartment's cell
 * (fnc_canvasInsets, the place brings them, the grid keeps them): two that meet show the gap and two
 * frames a flowed block would, while every cell keeps its place and a compartment stays one whole space
 * however its neighbours are cut.
 *
 * Each grid gets what moving items in and out of it needs (fnc_onMouseButton, fnc_endDrag):
 *   "container" - the section's container, objNull for a kit's
 *   "virtual"   - true: nothing moves in or out - a body's worn gear has no container to take from
 *   "kit"       - the kit class its grid stands for (einv_compat_efak), "" for a container
 *   "layoutKey" - where its layout is kept, for a grid with no container (einv_storage_fnc_getLayout)
 *   "unit", "block", "overflow"
 *   "window"    - the key of the kit window it lies in, "" in a column: the mouse finds a grid only
 *                 while nothing lies over it (fnc_topAt)
 *   "holder"    - what its places are kept on (einv_storage_fnc_readPlaces): the container, or for a
 *                 grid with none its layoutKey; objNull for neither
 *   "root"      - whose locality decides who may change it (einv_storage_fnc_rootOf) - for a uniform,
 *                 vest or backpack opened from inside a container through the one it lies in
 *                 (GVAR(opened))
 *   "side"      - "own" for the unit's storage column, "loot" for the loot column, "" in a kit's window:
 *                 selecting works on one side at a time (fnc_select)
 *   "overflowIndex" - which of the layout's overflow entries an overflow grid shows
 *
 * A layout whose places disagree with what the holder holds - something came or went without a place,
 * by a script or another mod - notes the holder as drifted (GVAR(drift)): reported to its authority
 * after a moment (fnc_onFrame, fnc_requestNormalize), which then keeps exactly what every window already
 * shows. One that agrees again is taken off.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group to draw in <CONTROL>
 * 2: Top left corner of the block [x, y] in the group <ARRAY>
 * 3: Section, see einv_storage_fnc_getSections <HASHMAP>
 * 4: Layout, see einv_storage_fnc_getLayout <HASHMAP>
 * 5: Places, see fnc_flowCompartments <ARRAY>
 * 6: Theme <HASHMAP>
 * 7: Key of the kit window it is drawn in <STRING> (default: "")
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, _group, [_gridX, _top], _section, _layout, _places, _theme] call einv_gui_fnc_drawCompartments;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_parent", "_corner", "_section", "_layout", "_places", "_theme", ["_window", ""]];
_corner params ["_gridX", "_bodyTop"];

(call FUNC(getCell)) params ["_cellW", "_cellH"];

private _id = _section getOrDefault ["id", ""];
private _colorLine = _theme getOrDefault ["line", [1, 1, 1, 0.07]];
private _container = _section getOrDefault ["container", objNull];
private _placed = _layout getOrDefault ["entries", []];
private _blocks = _layout getOrDefault ["blocks", []];
private _overflow = _layout getOrDefault ["overflow", []];

// Loot not searched yet shows as "?" (fnc_markHidden).
[_container, _placed] call FUNC(markHidden);

// What its places are kept on, and whose machine may change them. A grid with no container keeps them
// under its layout's key (an open kit); one with neither - a section that only shows - has none.
private _layoutKey = _section getOrDefault ["layoutKey", ""];
private _holder = [_container, _layoutKey] select (_layoutKey isNotEqualTo "");
private _hasHolder = (_holder isEqualType "") || {!isNull _holder};
private _root = objNull;

if (_hasHolder) then {
    // Opened from inside a container: the one it lies in leads to its root, should no tag say so yet.
    private _liesIn = objNull;

    if (_holder isEqualType objNull) then {
        private _openedIndex = GVAR(opened) findIf {(_x select 1) isEqualTo _holder};

        if (_openedIndex >= 0) then {
            _liesIn = (GVAR(opened) select _openedIndex) param [2, objNull];
        };
    };

    _root = [_holder, _liesIn] call EFUNC(storage,rootOf);

    // Drift: noted the first time it shows, so the time it started is kept while it lasts.
    private _driftIndex = GVAR(drift) findIf {(_x select 0) isEqualTo _holder};

    if (_layout getOrDefault ["drift", false]) then {
        if (_driftIndex < 0) then {
            GVAR(drift) pushBack [_holder, _root, diag_tickTime];
        };
    } else {
        if (_driftIndex >= 0) then {
            GVAR(drift) deleteAt _driftIndex;
        };
    };
};

private _originX = [safezoneX, 0] select !isNull _parent;
private _originY = [safezoneY, 0] select !isNull _parent;

// The lines of a shaped compartment (einv_items_fnc_parseGrid, "xxx/x-x"): one surface behind the
// cells would show through its holes, so a hole would read as a cell after all. Instead every line
// pixel is drawn once, by the slot it lies in - a slot is a cell and the pixel gap to its right and
// below it, and the slots tile the grid. A row's cells next to each other share one surface, as the
// whole grid does otherwise. A hole draws only the gap that borders a cell: to its right, below it,
// or the corner between; so does the slot left of the first column and above the first row, which
// makes the outer line. Nothing overlaps, so the see-through lines are as bright everywhere.
private _fnc_shapeLines = {
    params ["_snapX", "_snapY", "_cols", "_rows", "_holes"];

    private _fnc_isCell = {
        params ["_col", "_row"];

        _col >= 0 && {_row >= 0} && {_col < _cols} && {_row < _rows} && {!((_row * _cols + _col) in _holes)}
    };

    private _fnc_line = {
        params ["_lineX", "_lineY", "_lineW", "_lineH"];

        [_display, _parent, [_lineX, _lineY, _lineW, _lineH], _colorLine] call FUNC(uiPanel);
    };

    // The cells, a run of them in a row at a time.
    for "_row" from 0 to (_rows - 1) do {
        private _start = -1;

        for "_col" from 0 to _cols do {
            private _isCell = [_col, _row] call _fnc_isCell;

            if (_isCell && {_start < 0}) then {
                _start = _col;
            };

            if (!_isCell && {_start >= 0}) then {
                [_snapX + _start * _cellW, _snapY + _row * _cellH, (_col - _start) * _cellW, _cellH] call _fnc_line;
                _start = -1;
            };
        };
    };

    // The holes, and the slots outside the grid's left and top edge.
    for "_row" from -1 to (_rows - 1) do {
        for "_col" from -1 to (_cols - 1) do {
            if ([_col, _row] call _fnc_isCell) then {continue};

            private _slotX = _snapX + _col * _cellW;
            private _slotY = _snapY + _row * _cellH;
            private _right = [_col + 1, _row] call _fnc_isCell;
            private _below = [_col, _row + 1] call _fnc_isCell;

            // The gap to the right, with the corner below it.
            if (_right) then {
                [_slotX + _cellW - pixelW, _slotY, pixelW, _cellH] call _fnc_line;
            };

            // The gap below - with the corner unless the gap to the right took it.
            if (_below) then {
                [_slotX, _slotY + _cellH - pixelH, _cellW - ([0, pixelW] select _right), pixelH] call _fnc_line;
            };

            // Only the corner: a cell diagonally below to the right.
            if (!_right && {!_below} && {[_col + 1, _row + 1] call _fnc_isCell}) then {
                [_slotX + _cellW - pixelW, _slotY + _cellH - pixelH, pixelW, pixelH] call _fnc_line;
            };
        };
    };
};

// The lines of a canvas's compartment drawn in beside another one (fnc_canvasInsets): every cell's own
// frame - the cell as fnc_createGrid draws it, a pixel bigger all round - and where two cells of it meet
// the one line between them. One surface each would overlap there and on the corners, and the
// see-through lines would show it; so the frames are joined first: cut into bands where any of them
// starts or ends, each band is the runs across it they cover, and bands that cover the same runs make
// one rectangle together. A plain rectangle stays one surface, a drawn-in one a few.
private _fnc_insetLines = {
    params ["_snapX", "_snapY", "_cols", "_rows", "_holes", "_insets", "_color"];

    private _frames = [];

    for "_row" from 0 to (_rows - 1) do {
        for "_col" from 0 to (_cols - 1) do {
            if ((_row * _cols + _col) in _holes) then {continue};

            (_insets param [_row * _cols + _col, [0, 0, 0, 0]]) params ["_inL", "_inT", "_inR", "_inB"];

            // [left, top, right, bottom], the far edges outside it.
            _frames pushBack [
                _snapX + _col * _cellW + _inL - pixelW,
                _snapY + _row * _cellH + _inT - pixelH,
                _snapX + (_col + 1) * _cellW - _inR,
                _snapY + (_row + 1) * _cellH - _inB
            ];
        };
    };

    // Where a band starts or ends, a value once: within half a pixel is the same pixel.
    private _all = [];

    {
        _all pushBack (_x select 1);
        _all pushBack (_x select 3);
    } forEach _frames;

    _all sort true;

    private _edges = [];

    {
        if (_edges isEqualTo [] || {_x - (_edges select (count _edges - 1)) > pixelH / 2}) then {
            _edges pushBack _x;
        };
    } forEach _all;

    // The runs [left, right] across a band; and the bands so far that cover the same, from where.
    private _fnc_flush = {
        params ["_runs", "_from", "_to"];

        {
            [_display, _parent, [_x select 0, _from, (_x select 1) - (_x select 0), _to - _from], _color] call FUNC(uiPanel);
        } forEach _runs;
    };

    private _open = [];
    private _openFrom = 0;

    for "_i" from 0 to (count _edges - 2) do {
        private _from = _edges select _i;
        private _to = _edges select (_i + 1);
        private _middle = (_from + _to) / 2;
        private _across = (_frames select {(_x select 1) < _middle && {(_x select 3) > _middle}}) apply {[_x select 0, _x select 2]};
        private _runs = [];

        _across sort true;

        {
            _x params ["_left", "_right"];

            if (_runs isNotEqualTo [] && {_left <= ((_runs select (count _runs - 1)) select 1) + pixelW / 2}) then {
                private _last = _runs select (count _runs - 1);

                _last set [1, (_last select 1) max _right];
            } else {
                _runs pushBack [_left, _right];
            };
        } forEach _across;

        // The same runs as the band above: it goes on.
        private _same = count _runs == count _open;

        {
            private _other = _open select _forEachIndex;

            if (abs ((_x select 0) - (_other select 0)) > pixelW / 2 || {abs ((_x select 1) - (_other select 1)) > pixelW / 2}) exitWith {
                _same = false;
            };
        } forEach ([[], _runs] select _same);

        if (!_same) then {
            [_open, _openFrom, _from] call _fnc_flush;
            _open = _runs;
            _openFrom = _from;
        };
    };

    [_open, _openFrom, _edges param [count _edges - 1, 0]] call _fnc_flush;
};

private _fnc_compartment = {
    params ["_index", "_cols", "_rows", "_place", "_isOverflow", "_overflowIndex", ["_holes", []], ["_pos", []]];
    _place params ["_dx", "_dy", ["_insets", []]];

    private _x0 = _gridX + _dx;
    private _y0 = _bodyTop + _dy;

    // The lines: a surface behind the cells, a pixel bigger on the left and at the top, so every cell
    // is outlined on all four sides. On the grid's own pixels, as fnc_createGrid places it. A canvas's
    // compartment that borders another one draws them in along those sides, as its cells are.
    private _snapX = _originX + round ((_x0 - _originX) / pixelW) * pixelW;
    private _snapY = _originY + round ((_y0 - _originY) / pixelH) * pixelH;
    private _lineColor = [_colorLine, _theme getOrDefault ["loss", [1, 0, 0, 1]]] select _isOverflow;

    switch (true) do {
        case (_insets isNotEqualTo []): {
            [_snapX, _snapY, _cols, _rows, _holes, _insets, _lineColor] call _fnc_insetLines;
        };
        case (_holes isEqualTo []): {
            [_display, _parent, [_snapX - pixelW, _snapY - pixelH, _cols * _cellW + pixelW, _rows * _cellH + pixelH], _lineColor] call FUNC(uiPanel);
        };
        default {
            [_snapX, _snapY, _cols, _rows, _holes] call _fnc_shapeLines;
        };
    };

    private _grid = [_display, _parent, [_x0, _y0], _rows, _theme, _id, _cols, _holes, _insets] call FUNC(createGrid);

    // What the grid shows, for moving items in and out of it (fnc_onMouseButton, fnc_endDrag): a
    // virtual section - a body's worn gear - has no container to take from; nothing can be put into
    // the overflow. An open kit has no container either, but its grid takes and gives like one
    // (einv_compat_efak): it says so, and which kit it is.
    _grid set ["container", _container];
    _grid set ["virtual", _section getOrDefault ["virtual", "entries" in _section]];
    _grid set ["kit", _section getOrDefault ["kit", ""]];
    _grid set ["layoutKey", _layoutKey];
    _grid set ["holder", [objNull, _holder] select _hasHolder];
    _grid set ["root", _root];
    _grid set ["unit", _section getOrDefault ["unit", objNull]];
    _grid set ["block", _index];
    _grid set ["pos", _pos];
    _grid set ["overflow", _isOverflow];
    _grid set ["overflowIndex", _overflowIndex];
    _grid set ["window", _window];
    _grid set ["side", _section getOrDefault ["side", ""]];

    [_display, _grid, _layout, _theme] call FUNC(drawTiles);
};

{
    _x params ["_cols", "_rows", ["_holes", []], ["_pos", []]];

    if ((_places param [_forEachIndex, []]) isEqualTo []) then {continue};

    [_forEachIndex, _cols, _rows, _places select _forEachIndex, false, -1, _holes, _pos] call _fnc_compartment;
} forEach _blocks;

{
    _x set ["col", 0];
    _x set ["row", 0];

    [-1, _x get "w", _x get "h", _places select (count _blocks + _forEachIndex), true, _forEachIndex] call _fnc_compartment;
} forEach _overflow;
