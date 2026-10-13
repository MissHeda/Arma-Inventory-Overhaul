#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Where a container's compartments (einv_storage_fnc_getBlocks) lie in a block STORAGE_COLS cells wide:
 * side by side as far as that reaches, then on the next line - and, should anything not fit any of
 * them, a line of its own for that, each such item in a little compartment of its own size. A column's
 * section (fnc_drawSection) and a kit's window (fnc_drawWindow) lay their grids out the same way, and
 * fnc_drawCompartments draws them where this put them.
 *
 * Compartments drawn on a canvas (grid=aab/acc, a pos of their own) are not flowed: they lie where they
 * were drawn, cell for cell - the owner draws a backpack the way it is built and wants it to look like
 * that - but with the flow's gap on every seam where two of them meet (fnc_canvasSeams), so painted
 * compartments read as the separate blocks the Blocks view shows. Such a compartment's place brings the
 * left edge of each of its columns and the top edge of each of its rows (from its own corner); its grid
 * keeps them (fnc_createGrid "colX", "rowY") and everything that turns a cell into a place on the screen
 * or back reads them there. The canvas is one piece of the flow, the box around its compartments, and
 * whatever comes after it starts below it. Two of them may share a box (a ring and the cell inside it);
 * the grids find a point by the cells they have (fnc_screenToCell), never by their box.
 *
 * Arguments:
 * 0: Layout, see einv_storage_fnc_getLayout <HASHMAP>
 * 1: Cell size [w, h] <ARRAY> (default: fnc_getCell's)
 *
 * Return Value:
 * [places, height, width] <ARRAY>
 *   places - [x, y] from the block's top left corner per compartment, then per overflowing item; [] for
 *            a compartment with no rows, which takes no place. A canvas's compartment has
 *            [x, y, colX, rowY]: its columns' and rows' offsets from that corner, seams included
 *   height - how tall all of it is, 0 for nothing at all
 *   width  - how wide its widest line is: a canvas with seams may reach past STORAGE_COLS cells
 *
 * Example:
 * ([_layout] call einv_gui_fnc_flowCompartments) params ["_places", "_height", "_width"];
 *
 * Public: No
 */

params ["_layout", ["_cell", [], [[]]]];

if (_cell isEqualTo []) then {
    _cell = call FUNC(getCell);
};

_cell params ["_cellW", "_cellH"];

private _gridW = STORAGE_COLS * _cellW;
private _gap = round (_cellW * COMPARTMENT_GAP / pixelW) * pixelW;
private _gapY = round (_cellH * COMPARTMENT_GAP / pixelH) * pixelH;
private _places = [];
private _lineX = 0;
private _lineY = 0;
private _lineHeight = 0;
private _widest = 0;

// Where the next piece goes, of _width by _height: [x, y].
private _fnc_flow = {
    params ["_width", "_height"];

    if (_lineX > 0 && {_lineX + _width > _gridW + 0.0001}) then {
        _lineX = 0;
        _lineY = _lineY + _lineHeight + _gapY;
        _lineHeight = 0;
    };

    private _place = [_lineX, _lineY];

    _lineX = _lineX + _width + _gap;
    _lineHeight = _lineHeight max _height;
    _widest = _widest max (_lineX - _gap);

    _place
};

private _blocks = _layout getOrDefault ["blocks", []];
private _index = 0;

while {_index < count _blocks} do {
    (_blocks select _index) params ["_cols", "_rows", "", ["_pos", []]];

    switch (true) do {
        // A compartment with no rows - a container that holds nothing at all - takes no place.
        case (_rows <= 0): {
            _places pushBack [];
            _index = _index + 1;
        };
        case (_pos isEqualTo []): {
            _places pushBack ([_cols * _cellW, _rows * _cellH] call _fnc_flow);
            _index = _index + 1;
        };
        default {
            // The canvas: this compartment and the ones placed with it that follow, as one piece.
            private _last = _index;

            while {_last + 1 < count _blocks && {((_blocks select (_last + 1)) param [3, []]) isNotEqualTo []}} do {
                _last = _last + 1;
            };

            private _group = _blocks select [_index, _last - _index + 1];
            private _minX = selectMin (_group apply {(_x select 3) select 0});
            private _minY = selectMin (_group apply {(_x select 3) select 1});

            // Where its columns and rows lie with the seams opened up; it takes that much room.
            ([_group, _cell] call FUNC(canvasSeams)) params ["_colX", "_rowY", "_width", "_height"];
            ([_width, _height] call _fnc_flow) params ["_canvasX", "_canvasY"];

            {
                _x params ["_cols", "_rows", "", "_pos"];

                private _firstCol = (_pos select 0) - _minX;
                private _firstRow = (_pos select 1) - _minY;
                private _left = _colX select _firstCol;
                private _top = _rowY select _firstRow;

                _places pushBack [
                    _canvasX + _left, _canvasY + _top,
                    (_colX select [_firstCol, _cols]) apply {_x - _left},
                    (_rowY select [_firstRow, _rows]) apply {_x - _top}
                ];
            } forEach _group;

            // Nothing beside it: what follows starts under the canvas.
            _lineX = 1e6;
            _index = _last + 1;
        };
    };
};

// What has no room: on a line of its own, each item in a little compartment of its own size.
private _overflow = _layout getOrDefault ["overflow", []];

if (_overflow isNotEqualTo []) then {
    _lineX = 1e6;

    {
        _places pushBack ([(_x get "w") * _cellW, (_x get "h") * _cellH] call _fnc_flow);
    } forEach _overflow;
};

[_places, [0, _lineY + _lineHeight] select ((_places findIf {_x isNotEqualTo []}) >= 0), _widest]
