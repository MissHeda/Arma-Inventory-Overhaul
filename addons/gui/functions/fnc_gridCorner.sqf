#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Works out how round the corners of a grid's tiles, cells and outlines are where they touch a corner of the
 * compartment's panel (fnc_drawCompartments, fnc_drawPagePanel) and keeps it on the grid as "corner": the panel's
 * radius in pixels less the pad it lies past the cells (the card is round at its edge, the cells start a pad inside it,
 * so an item at the corner follows the same arc a pad nearer). 0 where the panel has no round corner: a square look
 * (theme radius 0), a compartment whose rows that show hold a hole (its panel is a shape of rectangles, fnc_uiShape),
 * and a corner too small to see. A page of a paged compartment (fnc_setWindow) is asked again - the holes of its rows
 * decide - and the overflow grid is told to have none by the caller.
 *
 * Arguments:
 * 0: Grid, see fnc_createGrid ("panelR" and "pad" in pixels, "holes", "cols", "rowFrom", "rowTo" read) <HASHMAP>
 *
 * Return Value:
 * The corner in pixels, 0 for none <NUMBER>
 *
 * Example:
 * [_grid] call einv_gui_fnc_gridCorner;
 *
 * Public: No
 */

params [["_grid", createHashMap, [createHashMap]]];

private _cols = _grid getOrDefault ["cols", 0];
private _from = _grid getOrDefault ["rowFrom", 0];
private _to = _grid getOrDefault ["rowTo", _grid getOrDefault ["rows", 0]];
private _holes = _grid getOrDefault ["holes", []];

// A hole in the rows that show makes the panel a shape of rectangles: square.
private _shaped = (_holes findIf {_x >= _from * _cols && {_x < _to * _cols}}) >= 0;
private _corner = (_grid getOrDefault ["panelR", 0]) - (_grid getOrDefault ["pad", 0]);

if (_shaped || {_corner < 2}) then {
    _corner = 0;
};

_grid set ["corner", _corner];

_corner
