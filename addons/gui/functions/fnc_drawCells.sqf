#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The faint squares of a grid's cells (fnc_createGrid) where no tile lies: made where there is none yet, shown
 * where one was hidden, hidden where a tile lies now. Called once the tiles lie on the grid - by the build
 * (fnc_drawCompartments) and by a redraw of tiles (fnc_redrawTiles) -, so a cell under a tile never gets a
 * square at all: a full pile of ninety tiles makes no ninety squares only to hide them, and the display has
 * that many controls fewer to go through every frame.
 *
 * A square made here comes after the tiles of its group, which the engine draws over the controls made
 * before them; it lies over nothing but its compartment's panel all the same - a tile keeps to its own cells,
 * and whatever is drawn over cells (an outline, a footprint, the selection) is made later again.
 *
 * Which cells a tile covers is its box less its own holes, cut at the grid's edge, as fnc_createTile hides them.
 * A hole of the grid has no square, ever.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Grid, see fnc_createGrid <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, _grid] call einv_gui_fnc_drawCells;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_grid"];

private _cols = _grid get "cols";
private _rows = _grid get "rows";
private _cells = _grid get "cells";

if (isNil "_cells" || {_cols < 1} || {_rows < 1}) exitWith {};

// 0 free, 1 under a tile, 2 a hole of the grid.
private _state = [];
_state resize (_cols * _rows);
_state = _state apply {0};

{
    if (_x >= 0 && {_x < count _state}) then {
        _state set [_x, 2];
    };
} forEach (_grid getOrDefault ["holes", []]);

{
    private _col = _x getOrDefault ["col", 0];
    private _row = _x getOrDefault ["row", 0];
    private _fullW = _x getOrDefault ["w", -1];
    private _h = _x getOrDefault ["h", -1];

    // An entry without its size (none the layout made) has the size its rules give it, as fnc_createTile reads it.
    if (_fullW < 0 || {_h < 0}) then {
        (([_x getOrDefault ["class", ""]] call EFUNC(items,getInfo)) getOrDefault ["size", [1, 1]]) params ["_sizeW", "_sizeH"];

        if (_fullW < 0) then {_fullW = _sizeW};
        if (_h < 0) then {_h = _sizeH};
    };

    private _w = (_fullW min (_cols - _col)) max 1;
    _h = _h max 1;

    // Cut at the grid's edge, its holes no longer match its cells: the box is drawn then, and covered.
    private _holes = [[], _x getOrDefault ["holes", []]] select (_w == _fullW);

    for "_r" from _row to ((_row + _h - 1) min (_rows - 1)) do {
        for "_c" from _col to ((_col + _w - 1) min (_cols - 1)) do {
            private _index = _r * _cols + _c;

            if ((_state select _index) == 0 && {!(((_r - _row) * _w + _c - _col) in _holes)}) then {
                _state set [_index, 1];
            };
        };
    };
} forEach (_grid getOrDefault ["tiles", []]);

private _parent = _grid getOrDefault ["parent", controlNull];
private _color = _grid getOrDefault ["cellColor", [1, 1, 1, 0.05]];
private _colX = _grid get "colX";
private _rowY = _grid get "rowY";
private _cellW = _grid get "cellW";
private _cellH = _grid get "cellH";

(_grid get "rel") params ["_left", "_top"];

{
    if (_x == 2) then {continue};

    private _cell = _cells select _forEachIndex;

    if (_x == 1) then {
        _cell ctrlShow false;
        continue;
    };

    if (isNull _cell) then {
        private _row = floor (_forEachIndex / _cols);
        private _col = _forEachIndex - _row * _cols;

        _cell = [_display, "EINV_PanelRect", _parent, [
            _left + (_colX select _col),
            _top + (_rowY select _row),
            _cellW - pixelW,
            _cellH - pixelH
        ]] call FUNC(uiCreate);

        _cell ctrlSetBackgroundColor _color;
        _cells set [_forEachIndex, _cell];
    } else {
        _cell ctrlShow true;
    };
} forEach _state;
