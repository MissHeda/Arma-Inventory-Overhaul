#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Shows the selected tiles: a faint accent fill and a frame two pixels thick on each, made in the tile's
 * own controls group so they scroll and clip with it. The ones made before go first, so it can be called
 * again after every change of the selection - and at the end of a build and of a redraw of tiles
 * (fnc_build, fnc_redrawTiles), which made the tiles anew.
 *
 * While a frame is dragged out from an empty cell (fnc_updateBand), the tiles it touches are shown the same
 * way before it is let go.
 *
 * Arguments:
 * 0: Tiles that only look selected, [[grid index, tile index], ...] <ARRAY> (default: [])
 *
 * Return Value:
 * None
 *
 * Example:
 * call einv_gui_fnc_drawSelection;
 *
 * Public: No
 */

disableSerialization;

params [["_preview", [], [[]]]];

{ctrlDelete _x} forEach (uiNamespace getVariable [QGVAR(selectionFrames), []]);
uiNamespace setVariable [QGVAR(selectionFrames), []];

private _display = uiNamespace getVariable [QGVAR(display), displayNull];

if (isNull _display) exitWith {};

private _tiles = call FUNC(selectionTiles);

{
    _tiles pushBackUnique _x;
} forEach _preview;

if (_tiles isEqualTo []) exitWith {};

private _grids = uiNamespace getVariable [QGVAR(grids), []];
private _accent = GVAR(theme) getOrDefault ["accent", [0.84, 0.54, 0.1, 1]];
private _fill = +_accent;
_fill set [3, SELECT_FILL_ALPHA];

private _frames = [];

{
    _x params ["_gridIndex", "_tileIndex"];

    private _grid = _grids param [_gridIndex, createHashMap];
    private _tile = (_grid getOrDefault ["tiles", []]) param [_tileIndex, createHashMap];

    if (count _tile == 0) then {continue};

    private _parent = _grid getOrDefault ["parent", controlNull];
    (_grid get "rel") params ["_gridX", "_gridY"];

    private _cellW = _grid get "cellW";
    private _cellH = _grid get "cellH";

    // As a tile ends a pixel before the next cell, so does its frame - over a seam's gap as the tile does
    // (fnc_spanRect).
    private _rect = [_grid, [_gridX, _gridY], _tile get "col", _tile get "row", _tile get "w", _tile get "h"] call FUNC(spanRect);

    // A shaped tile (size=xx/x-) on its own cells only, as it is drawn (fnc_createTile, fnc_uiShape).
    private _holes = _tile getOrDefault ["holes", []];

    if (_holes isNotEqualTo []) then {
        private _footprint = [_tile get "w", _tile get "h", _holes];
        private _origin = [_rect select 0, _rect select 1];
        private _seams = [_grid, _tile get "col", _tile get "row", _tile get "w", _tile get "h"] call FUNC(spanSeams);

        _frames append ([_display, _parent, _origin, _cellW, _cellH, _footprint, _fill, "surface", 0, _seams] call FUNC(uiShape));
        _frames append ([_display, _parent, _origin, _cellW, _cellH, _footprint, _accent, "frame", 0, _seams] call FUNC(uiShape));
        _frames append ([_display, _parent, _origin, _cellW, _cellH, _footprint, _accent, "frame", 1, _seams] call FUNC(uiShape));
        continue;
    };

    private _filled = [_display, "EINV_PanelRect", _parent, _rect] call FUNC(uiCreate);
    _filled ctrlSetBackgroundColor _fill;
    _frames pushBack _filled;

    // Two pixels thick: the frame, and another inside it.
    _frames pushBack ([_display, _parent, _rect, _accent] call FUNC(uiFrame));
    _frames pushBack ([
        _display, _parent, [(_rect select 0) + pixelW, (_rect select 1) + pixelH, (_rect select 2) - pixelW * 2, (_rect select 3) - pixelH * 2], _accent
    ] call FUNC(uiFrame));
} forEach _tiles;

uiNamespace setVariable [QGVAR(selectionFrames), _frames];
