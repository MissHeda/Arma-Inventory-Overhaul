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
 * Every compartment lies on a panel of its own: a faint card (the theme's "card") behind its cells that
 * reaches COMPARTMENT_PAD_PX pixels past them, its corners round as far as the corner cells stay inside
 * the round (the theme's radius, at most three times the pad; square in a look without one). The panel covers
 * exactly the compartment's cells and the room between them; a shaped one's holes stay open, as a union
 * of rectangles that do not overlap (fnc_uiShape "panel"), so a see-through panel is as strong
 * everywhere. Between two panels lies the gap between blocks, or on a canvas (grid=aab/acc) the seam
 * fnc_flowCompartments opened where two compartments touch, so each reads as the block it is: painted
 * and flowed containers look alike. Every cell is the same size with the same gap to the next, the
 * panel showing in that gap. Each compartment is a grid of its own, with "pos" where it lies on the
 * canvas and its columns' and rows' places (fnc_createGrid "colX", "rowY"): one that reaches over a seam
 * opened for two others has that room between two of its cells, inside its panel. All panels are drawn
 * before any cell, so the panel of the cell inside a ring lies under nothing of the ring.
 * What has no room keeps the loss colour's lines round its cells, and no panel.
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

// A compartment cut into pages (fnc_viewBlocks): [page, [[from, to], ...]] per compartment, [] for one that is not. Its grid
// is the whole compartment with only the rows of its page showing (fnc_createGrid), its panel the page's down to the tallest
// page's last row, and under it - as the bottom part of the same panel - the bar that turns the page (fnc_drawPageBar).
private _paging = _layout getOrDefault ["paging", []];
private _pagePanels = createHashMap;

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
    } else {
        // A kit's grid: the container its tile lies in leads to its root (the Arsenal's panel, whose staging space
        // is no root the kit finder would think of).
        private _parent = _section getOrDefault ["parent", objNull];

        if (_parent isEqualType objNull) then {
            _liesIn = _parent;
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

// The panels: COMPARTMENT_PAD_PX pixels past the cells, round up to three times that.
private _pad = COMPARTMENT_PAD_PX(_cellW);
private _padW = _pad * pixelW;
private _padH = _pad * pixelH;
private _radius = (_theme getOrDefault ["radius", 0]) min (_pad * 3 * pixelH);
private _colorPanel = _theme getOrDefault ["card", []];

if (_colorPanel isEqualTo []) then {
    _colorPanel = _colorLine;
};

// The places of _count columns (rows) at the plain pitch _pitch, for a compartment that flows.
private _fnc_plain = {
    params ["_count", "_pitch"];

    private _starts = [];

    for "_i" from 0 to (_count - 1) do {
        _starts pushBack (_i * _pitch);
    };

    _starts
};

// The panel of a compartment at [_x0, _y0], its columns and rows starting at _colX and _rowY from there: a
// round card from its first cell's corner to its last cell's far edge, the pad all round - over the room a
// seam opens inside it too -, or for a shaped one its cells grown by the pad, its holes left open.
private _fnc_panel = {
    params ["_x0", "_y0", "_cols", "_rows", "_holes", "_colX", "_rowY"];

    if (_holes isEqualTo []) exitWith {
        private _right = _x0 + (_colX select (_cols - 1)) + _cellW - pixelW;
        private _bottom = _y0 + (_rowY select (_rows - 1)) + _cellH - pixelH;

        [
            _display, _parent, [_x0 - _padW, _y0 - _padH, _right - _x0 + _padW * 2, _bottom - _y0 + _padH * 2],
            _colorPanel, _radius
        ] call FUNC(uiPanel);
    };

    [
        _display, _parent, [_x0, _y0], _cellW, _cellH, [_cols, _rows, _holes], _colorPanel, "panel", _pad,
        [createHashMapFromArray [["colX", _colX], ["rowY", _rowY]], 0, 0]
    ] call FUNC(uiShape);
};

private _fnc_compartment = {
    params ["_index", "_cols", "_rows", "_place", "_isOverflow", "_overflowIndex", ["_holes", []], ["_pos", []], ["_paged", []], ["_extra", []]];
    _extra params [["_accepts", []], ["_single", false]];
    _place params ["_dx", "_dy", ["_colX", []], ["_rowY", []]];

    private _x0 = _gridX + _dx;
    private _y0 = _bodyTop + _dy;

    // What has no room: the loss colour's lines round and between its cells, a surface a pixel bigger on the
    // left and at the top behind them.
    if (_isOverflow) then {
        [
            _display, _parent, [_x0 - pixelW, _y0 - pixelH, _cols * _cellW + pixelW, _rows * _cellH + pixelH],
            _theme getOrDefault ["loss", [1, 0, 0, 1]]
        ] call FUNC(uiPanel);
    };

    private _pageWindow = [];

    if (_paged isNotEqualTo []) then {
        _pageWindow = (_paged select 1) select (_paged select 0);
    };

    // A compartment that takes only some categories, and a single slot (one tile whatever its size, einv_storage_fnc_blockMode),
    // says so with a faint picture on its free cells: made over the tiles, after them (fnc_drawBadge, from fnc_drawCells).

    private _grid = [_display, _parent, [_x0, _y0], _rows, _theme, _id, _cols, _holes, [_colX, _rowY], _pageWindow] call FUNC(createGrid);

    if (_paged isNotEqualTo []) then {
        _grid set ["pageRanges", _paged select 1];
        _grid set ["page", _paged select 0];
        _grid set ["pageHeight", selectMax ((_paged select 1) apply {(_x param [2, _x select 1]) - (_x select 0)})];
        _grid set ["panel", _pagePanels getOrDefault [_index, []]];
    };

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
    _grid set ["accepts", _accepts];
    _grid set ["single", _single];
    _grid set ["pos", _pos];
    _grid set ["overflow", _isOverflow];
    _grid set ["overflowIndex", _overflowIndex];

    // The overflow lies on a square panel of the loss colour: nothing follows a round corner there (fnc_gridCorner).
    if (_isOverflow) then {
        _grid set ["corner", 0];
    };
    _grid set ["window", _window];
    _grid set ["side", _section getOrDefault ["side", ""]];

    [_display, _grid, _layout, _theme] call FUNC(drawTiles);

    // The cells' squares after the tiles: only where no tile lies (fnc_drawCells).
    [_display, _grid] call FUNC(drawCells);

    if (_paged isNotEqualTo []) then {
        [_display, _grid] call FUNC(drawPageBar);
    };
};

// Every compartment's panel first, behind every cell.
{
    _x params ["_cols", "_rows", ["_holes", []]];

    private _place = _places param [_forEachIndex, []];

    if (_place isEqualTo [] || {_cols <= 0} || {_rows <= 0}) then {continue};

    _place params ["_dx", "_dy", ["_colX", []], ["_rowY", []]];

    // A page: its own panel, of the rows that show.
    private _pageOf = _paging param [_forEachIndex, []];

    if (_pageOf isNotEqualTo []) then {
        private _pageWindow = (_pageOf select 1) select (_pageOf select 0);

        _pagePanels set [_forEachIndex, [_display, _parent, [_gridX + _dx, _bodyTop + _dy], _cols, _pageWindow select 0, _pageWindow param [2, _pageWindow select 1], _holes, _theme, selectMax ((_pageOf select 1) apply {(_x param [2, _x select 1]) - (_x select 0)})] call FUNC(drawPagePanel)];
        continue;
    };

    if (count _colX != _cols) then {
        _colX = [_cols, _cellW] call _fnc_plain;
    };

    if (count _rowY != _rows) then {
        _rowY = [_rows, _cellH] call _fnc_plain;
    };

    [_gridX + _dx, _bodyTop + _dy, _cols, _rows, _holes, _colX, _rowY] call _fnc_panel;
} forEach _blocks;

{
    _x params ["_cols", "_rows", ["_holes", []], ["_pos", []]];

    if ((_places param [_forEachIndex, []]) isEqualTo []) then {continue};

    [_forEachIndex, _cols, _rows, _places select _forEachIndex, false, -1, _holes, _pos, _paging param [_forEachIndex, []], _x select [4]] call _fnc_compartment;
} forEach _blocks;

{
    _x set ["col", 0];
    _x set ["row", 0];

    [-1, _x get "w", _x get "h", _places select (count _blocks + _forEachIndex), true, _forEachIndex] call _fnc_compartment;
} forEach _overflow;
