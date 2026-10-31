#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Shows the selected tiles: a frame (no fill - a tinted item was hard on the eyes) two pixels thick on each, made in the tile's
 * own controls group so they scroll and clip with it. The ones made before go first, so it can be called
 * again after every change of the selection - and at the end of a build and of a redraw of tiles
 * (fnc_build, fnc_redrawTiles), which made the tiles anew.
 *
 * The name at the mouse always lies over the frames (fnc_raiseTooltip).
 *
 * Arguments:
 * None
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

{ctrlDelete _x} forEach (uiNamespace getVariable [QGVAR(selectionFrames), []]);
uiNamespace setVariable [QGVAR(selectionFrames), []];

private _display = uiNamespace getVariable [QGVAR(display), displayNull];

if (isNull _display) exitWith {};

private _tiles = call FUNC(selectionTiles);

if (_tiles isEqualTo []) exitWith {};

private _grids = uiNamespace getVariable [QGVAR(grids), []];
private _accent = GVAR(theme) getOrDefault ["accent", [0.84, 0.54, 0.1, 1]];

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

    // As a tile ends a pixel before the next cell, so does its frame, over a seam inside its compartment too
    // (fnc_spanRect).
    private _rect = [_grid, [_gridX, _gridY], _tile get "col", _tile get "row", _tile get "w", _tile get "h"] call FUNC(spanRect);

    // A shaped tile (size=xx/x-) on its own cells only, as it is drawn (fnc_createTile, fnc_uiShape), where
    // the grid's columns and rows lie (a canvas's seams).
    private _holes = _tile getOrDefault ["holes", []];

    if (_holes isNotEqualTo []) then {
        private _footprint = [_tile get "w", _tile get "h", _holes];
        private _origin = [_rect select 0, _rect select 1];
        private _on = [_grid, _tile get "col", _tile get "row"];

        _frames append ([_display, _parent, _origin, _cellW, _cellH, _footprint, _accent, "frame", 0, _on] call FUNC(uiShape));
        _frames append ([_display, _parent, _origin, _cellW, _cellH, _footprint, _accent, "frame", 1, _on] call FUNC(uiShape));
        continue;
    };

    // At a corner of its compartment's panel the fill and the frame are round there (fnc_cornerRadii).
    private _corners = [_grid, _rect] call FUNC(cornerRadii);


    // Two pixels thick: the frame, and another inside it.
    _frames append ([_display, _parent, _rect, _accent, _corners, 2] call FUNC(uiOutline));
} forEach _tiles;

uiNamespace setVariable [QGVAR(selectionFrames), _frames];

// A frame on a grid that is not in a group is made over the name at the mouse: the name is made again
// over it (fnc_raiseTooltip).
[] call FUNC(raiseTooltip);
