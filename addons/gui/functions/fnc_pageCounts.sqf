#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * How many tiles lie on each page of a paged compartment, and - while the search field holds something - how many of
 * them match it (fnc_matchesFilter, a tile not searched yet never does) and the category chosen at the box's side
 * (fnc_boxGroup, fnc_matchesGroup). Read from the grid's tiles, all of which it
 * keeps whatever page is turned to (fnc_drawTiles), so the pager can say what lies on the pages not shown: the bar's text
 * and the marks on its arrows (fnc_drawPageBar). One name is matched once per class.
 *
 * Arguments:
 * 0: The grid of a paged compartment (fnc_createGrid) <HASHMAP>
 *
 * Return Value:
 * [tiles per page, matches per page] <ARRAY>
 *
 * Example:
 * ([_grid] call einv_gui_fnc_pageCounts) params ["_tiles", "_matches"];
 *
 * Public: No
 */

params [["_grid", createHashMap, [createHashMap]]];

private _ranges = _grid getOrDefault ["pageRanges", []];
private _tiles = _ranges apply {0};
private _matches = _ranges apply {0};
private _group = [_grid getOrDefault ["holder", _grid getOrDefault ["container", objNull]]] call FUNC(boxGroup);
private _search = GVAR(filter) isNotEqualTo "" || {_group isNotEqualTo ""};
private _byClass = createHashMap;

{
    private _row = _x getOrDefault ["row", 0];
    private _page = _ranges findIf {_row >= (_x select 0) && {_row < (_x select 1)}};

    if (_page < 0) then {continue};

    _tiles set [_page, (_tiles select _page) + 1];

    if (_search && {!(_x getOrDefault ["hidden", false])}) then {
        private _class = _x getOrDefault ["class", ""];
        private _match = _byClass getOrDefault [_class, 2];

        if (_match isEqualTo 2) then {
            _match = ([_class] call FUNC(matchesFilter)) && {[_class, _group] call FUNC(matchesGroup)};
            _byClass set [_class, _match];
        };

        if (_match) then {
            _matches set [_page, (_matches select _page) + 1];
        };
    };
} forEach (_grid getOrDefault ["tiles", []]);

[_tiles, _matches]
