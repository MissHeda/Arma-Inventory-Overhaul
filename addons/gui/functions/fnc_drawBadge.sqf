#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * What says a compartment takes only some categories (grid=2x2:medical) or is a single slot (grid=1x1:grenade:one), also when
 * something lies in it: the watermark. A compartment with nothing in it shows its first category's picture, large and faint, in
 * the middle; one with something in it shows it, small and fainter, on each free cell while at most WATERMARK_CELLS_MAX are free.
 * Which picture, where it takes several categories, is the container's show= (aio_items_fnc_getInfo): one of them by its id,
 * "none" for no picture, "all" for a small picture of each of them in the compartment's top left corner instead, else the first.
 * Made again each time the cells'
 * squares are (fnc_drawCells, at the end of every draw of tiles), so it lies over the tiles and follows them.
 * Hovering a tile or a free cell of such a compartment says in the footer what it takes (fnc_updateHover).
 * The controls are kept in the grid under "badge" and deleted when it is drawn again.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: The grid, with "accepts" and "single" (fnc_drawCompartments) <HASHMAP>
 * 2: What each cell is: 0 free, 1 under a tile, 2 no cell or not on the page that shows (fnc_drawCells) <ARRAY of NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, _grid, _state] call aio_gui_fnc_drawBadge;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_grid", ["_state", [], [[]]]];

{ctrlDelete _x} forEach (_grid getOrDefault ["badge", []]);
_grid set ["badge", []];

private _accepts = _grid getOrDefault ["accepts", []];
private _single = _grid getOrDefault ["single", false];
private _parent = _grid getOrDefault ["parent", controlNull];

if ((_accepts isEqualTo [] && {!_single}) || {_grid getOrDefault ["overflow", false]} || {isNull _parent} || {_state isEqualTo []}) exitWith {};

private _cols = _grid get "cols";
private _colX = _grid get "colX";
private _rowY = _grid get "rowY";
private _cellW = _grid get "cellW";
private _cellH = _grid get "cellH";
private _rowTo = _grid getOrDefault ["rowTo", _grid get "rows"];

(_grid get "rel") params ["_left", "_top"];

private _made = [];
private _show = _grid getOrDefault ["show", ""];

if (_show isEqualTo "none") exitWith {};

// The one asked for first.
if (_show in _accepts) then {
    _accepts = [_show] + (_accepts - [_show]);
};

private _textures = (_accepts apply {[_x] call FUNC(groupTexture)}) select {_x isNotEqualTo ""};
private _shown = 0;
private _free = [];

{
    if (_x != 2) then {_shown = _shown + 1};
    if (_x == 0) then {_free pushBack _forEachIndex};
} forEach _state;

if (_shown == 0) exitWith {};

// ----- Small pictures of all of them in the corner (show=all) -----
if (_show isEqualTo "all" && {count _textures > 1}) exitWith {
    private _side = ((_cellW / pixelW) min (_cellH / pixelH)) * 0.42;
    private _pad = _side * 0.18;

    {
        _made pushBack ([
            _display, _parent,
            [_left + (_pad + _forEachIndex * (_side + _pad)) * pixelW, _top + _pad * pixelH, _side * pixelW, _side * pixelH],
            _x, [1, 1, 1, [0.35, 0.45] select _single]
        ] call FUNC(uiPicture));
    } forEach _textures;

    _grid set ["badge", _made];
};

// ----- The watermark -----
// Empty: one large picture in the middle of the compartment. Something lies in it: a small one on each free cell, unless there are
// many.
if (_textures isNotEqualTo [] && {_free isNotEqualTo []}) then {
    private _alpha = [0.12, 0.2] select _single;

    if (count _free == _shown) then {
        private _widthPx = ((_colX param [_cols - 1, (_cols - 1) * _cellW]) + _cellW) / pixelW;
        private _heightPx = ((_rowY param [(_rowTo - 1) max 0, 0]) + _cellH) / pixelH;
        private _side = (_widthPx min _heightPx) * 0.6;

        _made pushBack ([
            _display, _parent,
            [_left + (_widthPx - _side) / 2 * pixelW, _top + (_heightPx - _side) / 2 * pixelH, _side * pixelW, _side * pixelH],
            _textures select 0, [1, 1, 1, _alpha]
        ] call FUNC(uiPicture));
    } else {
        if (count _free <= WATERMARK_CELLS_MAX) then {
            private _side = ((_cellW / pixelW) min (_cellH / pixelH)) * 0.5;

            {
                private _col = _x mod _cols;
                private _row = floor (_x / _cols);

                _made pushBack ([
                    _display, _parent,
                    [
                        _left + (_colX param [_col, _col * _cellW]) + (_cellW / pixelW - _side) / 2 * pixelW,
                        _top + (_rowY param [_row, _row * _cellH]) + (_cellH / pixelH - _side) / 2 * pixelH,
                        _side * pixelW, _side * pixelH
                    ],
                    _textures select 0, [1, 1, 1, _alpha * 0.8]
                ] call FUNC(uiPicture));
            } forEach _free;
        };
    };
};

_grid set ["badge", _made];
