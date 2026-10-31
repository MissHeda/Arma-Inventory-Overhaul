#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Where a tile is on the screen right now - through its grid's place, so a scrolled column or window is
 * taken into account (fnc_gridOrigin), and its cells' places on the grid, seams of a canvas included
 * (fnc_spanRect). As a tile ends a pixel before the next cell, so does this. A kit window opens beside
 * the tile it was opened from (aio_compat_efak_fnc_toggle, fnc_placeWindow).
 *
 * Arguments:
 * 0: Grid, see fnc_createGrid <HASHMAP>
 * 1: Tile, one of the grid's "tiles" <HASHMAP>
 *
 * Return Value:
 * [x, y, w, h] on the screen <ARRAY>
 *
 * Example:
 * [_grid, _tile] call aio_gui_fnc_tileRect;
 *
 * Public: No
 */

disableSerialization;

params [["_grid", createHashMap, [createHashMap]], ["_tile", createHashMap, [createHashMap]]];

if (count _grid == 0 || {count _tile == 0}) exitWith {[]};

private _col = _tile getOrDefault ["col", 0];
private _row = _tile getOrDefault ["row", 0];

// An entry wider than its grid is cut at the grid's edge (fnc_createTile).
private _w = ((_tile getOrDefault ["w", 1]) min ((_grid get "cols") - _col)) max 1;
private _h = (_tile getOrDefault ["h", 1]) max 1;

[_grid, [_grid] call FUNC(gridOrigin), _col, _row, _w, _h] call FUNC(spanRect)
