#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * What says a compartment takes only some categories (grid=2x2:medical) or is a single slot (grid=1x1:grenade:one), also when
 * something lies in it. Made again each time the cells' squares are (fnc_drawCells, at the end of every draw of tiles), so it
 * lies over the tiles and follows them:
 *   - The badge: a small dark film with the pictures of the categories it takes (at most BADGE_ICONS_MAX, as many as fit the
 *     compartment's width) and, for a single slot, a "1", at the compartment's top left cell, a few pixels in from its corner.
 *     One badge a compartment - a paged one carries it to every page.
 *   - The watermark: a compartment with nothing in it shows its first category's picture, large and faint, in the middle; one
 *     with something in it shows it, small and fainter, on each free cell while at most WATERMARK_CELLS_MAX are free.
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
 * [_display, _grid, _state] call einv_gui_fnc_drawBadge;
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
private _textures = (_accepts apply {[_x] call FUNC(groupTexture)}) select {_x isNotEqualTo ""};
private _shown = 0;
private _free = [];

{
    if (_x != 2) then {_shown = _shown + 1};
    if (_x == 0) then {_free pushBack _forEachIndex};
} forEach _state;

if (_shown == 0) exitWith {};

// ----- The watermark -----
// Empty: one large picture in the middle of the compartment. Something lies in it: a small one on each free cell, unless there are
// many - the badge says it then.
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

// ----- The badge -----
private _firstCell = _state findIf {_x != 2};
private _col0 = _firstCell mod _cols;
private _row0 = floor (_firstCell / _cols);
private _sidePx = round (((((_cellW / pixelW) min (_cellH / pixelH)) * 0.34) max 8));
private _gapPx = 2;
private _padPx = 2;
private _insetPx = 2;

// How many marks fit across the compartment from its first cell on.
private _roomPx = ((((_colX param [_cols - 1, (_cols - 1) * _cellW]) + _cellW) - (_colX param [_col0, _col0 * _cellW])) / pixelW) - _insetPx - _padPx * 2;
private _fit = (floor ((_roomPx + _gapPx) / (_sidePx + _gapPx))) max 1;
private _keepOne = _single && {_fit > 1};
private _icons = _textures select [0, (BADGE_ICONS_MAX min (_fit - (parseNumber _keepOne))) max (parseNumber (_textures isNotEqualTo []))];
private _marks = +_icons;

if (_single && {_icons isEqualTo [] || {count _icons < _fit}}) then {
    _marks pushBack "single";
};

if (_marks isEqualTo []) exitWith {_grid set ["badge", _made]};

private _count = count _marks;
private _widthPx = _count * _sidePx + (_count - 1) * _gapPx + _padPx * 2;
private _heightPx = _sidePx + _padPx * 2;
private _boxX = _left + (_colX param [_col0, _col0 * _cellW]) + _insetPx * pixelW;
private _boxY = _top + (_rowY param [_row0, _row0 * _cellH]) + _insetPx * pixelH;
private _theme = GVAR(theme);

_made append ([_display, _parent, [_boxX, _boxY, _widthPx * pixelW, _heightPx * pixelH], [0, 0, 0, 0.5], 3 * pixelH] call FUNC(uiPanel));

{
    private _rect = [_boxX + (_padPx + _forEachIndex * (_sidePx + _gapPx)) * pixelW, _boxY + _padPx * pixelH, _sidePx * pixelW, _sidePx * pixelH];

    if (_x isEqualTo "single") then {
        _made pushBack ([
            _display, _parent, _rect, "1", _sidePx * pixelH, [1, 1, 1, 0.85], _theme getOrDefault ["fontBold", "PuristaSemibold"], 2
        ] call FUNC(uiLabel));
    } else {
        _made pushBack ([_display, _parent, _rect, _x, [1, 1, 1, 0.8]] call FUNC(uiIcon));
    };
} forEach _marks;

_grid set ["badge", _made];
