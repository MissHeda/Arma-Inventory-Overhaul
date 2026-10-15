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
 * compartment. The canvas is one uniform grid: every cell is the same size with the same gap to the next
 * wherever it lies and whichever compartment it belongs to, and a compartment is only the set of cells
 * it covers. Each is a grid of its own, with "pos" where it lies on the canvas; the lines behind the
 * cells are drawn once for the whole canvas as one shape, so a pixel of line is drawn once and is as
 * faint where two compartments meet as inside one.
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

// The block's corner on a pixel, once: every compartment lies a whole number of pixels from it, so the
// cells of two that touch keep one pitch even where the corner itself lies between two pixels.
_gridX = _originX + round ((_gridX - _originX) / pixelW) * pixelW;
_bodyTop = _originY + round ((_bodyTop - _originY) / pixelH) * pixelH;

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

// The lines behind a grid of _cols by _rows places at [_x0, _y0], holes the places without a cell: one surface
// a pixel bigger on the left and at the top, so every cell is outlined on all four sides. On the grid's own
// pixels, as fnc_createGrid places it.
private _fnc_lines = {
    params ["_x0", "_y0", "_cols", "_rows", "_holes", "_color"];

    private _snapX = _originX + round ((_x0 - _originX) / pixelW) * pixelW;
    private _snapY = _originY + round ((_y0 - _originY) / pixelH) * pixelH;

    if (_holes isEqualTo []) then {
        [_display, _parent, [_snapX - pixelW, _snapY - pixelH, _cols * _cellW + pixelW, _rows * _cellH + pixelH], _color] call FUNC(uiPanel);
    } else {
        [_snapX, _snapY, _cols, _rows, _holes] call _fnc_shapeLines;
    };
};

// The lines of a canvas: the blocks _first to _last are its compartments (each with a pos), and the cells
// of all of them are one shape. A surface per compartment would overlap where two meet, and the see-through
// lines would show it; as one shape every pixel is drawn once. A hole of one compartment that is a cell of
// another (the ring and the cell inside it) is no hole of the canvas.
private _fnc_canvasLines = {
    params ["_first", "_last"];

    private _group = _blocks select [_first, _last - _first + 1];
    private _minX = selectMin (_group apply {(_x select 3) select 0});
    private _minY = selectMin (_group apply {(_x select 3) select 1});
    private _cols = selectMax (_group apply {((_x select 3) select 0) + (_x select 0)}) - _minX;
    private _rows = selectMax (_group apply {((_x select 3) select 1) + (_x select 1)}) - _minY;

    // The places of the canvas some compartment has a cell on.
    private _taken = createHashMap;

    {
        _x params ["_blockCols", "_blockRows", ["_blockHoles", []], "_pos"];
        _pos params ["_posX", "_posY"];

        for "_row" from 0 to (_blockRows - 1) do {
            for "_col" from 0 to (_blockCols - 1) do {
                if !((_row * _blockCols + _col) in _blockHoles) then {
                    _taken set [(_posY - _minY + _row) * _cols + _posX - _minX + _col, true];
                };
            };
        };
    } forEach _group;

    private _holes = [];

    for "_place" from 0 to (_cols * _rows - 1) do {
        if !(_place in _taken) then {
            _holes pushBack _place;
        };
    };

    // The canvas's corner: where the first compartment lies, less its own place on the canvas.
    (_places select _first) params ["_placeX", "_placeY"];
    ((_group select 0) select 3) params ["_firstX", "_firstY"];

    [
        _gridX + _placeX - (_firstX - _minX) * _cellW, _bodyTop + _placeY - (_firstY - _minY) * _cellH,
        _cols, _rows, _holes, _colorLine
    ] call _fnc_lines;
};

private _fnc_compartment = {
    params ["_index", "_cols", "_rows", "_place", "_isOverflow", "_overflowIndex", ["_holes", []], ["_pos", []]];
    _place params ["_dx", "_dy"];

    private _x0 = _gridX + _dx;
    private _y0 = _bodyTop + _dy;

    // The lines behind its cells - those of a canvas's compartments were drawn with the whole canvas's.
    if (_pos isEqualTo []) then {
        [_x0, _y0, _cols, _rows, _holes, [_colorLine, _theme getOrDefault ["loss", [1, 0, 0, 1]]] select _isOverflow] call _fnc_lines;
    };

    private _grid = [_display, _parent, [_x0, _y0], _rows, _theme, _id, _cols, _holes] call FUNC(createGrid);

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

// The lines of every canvas first, as a canvas is the compartments with a pos that follow one another
// (fnc_flowCompartments): all of them lie behind the cells.
private _index = 0;

while {_index < count _blocks} do {
    (_blocks select _index) params ["", "_rows", "", ["_pos", []]];

    if (_rows > 0 && {_pos isNotEqualTo []}) then {
        private _last = _index;

        while {_last + 1 < count _blocks && {((_blocks select (_last + 1)) param [3, []]) isNotEqualTo []}} do {
            _last = _last + 1;
        };

        [_index, _last] call _fnc_canvasLines;
        _index = _last + 1;
    } else {
        _index = _index + 1;
    };
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
