#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Which page a step on a paged compartment's bar leads to (fnc_pageSoon, fnc_turnPage). Without a category chosen at the box's side
 * (fnc_boxGroup) every page counts: the page asked for, kept between the first and the last. With one the box shows only that kind
 * of item (fnc_applyFilter), so only the pages with a match count (fnc_pageCounts): a step goes that many matching pages on, never
 * to one that shows nothing, and stays at the last one when there are no more that way. An absolute page is the first matching
 * page from there on (the last one when none lies after it) - the first page with a match for the words on the bar.
 *
 * Arguments:
 * 0: The grid of a paged compartment <HASHMAP>
 * 1: The page to start from, from 0 <NUMBER>
 * 2: The step (relative) or the page to go to (not relative) <NUMBER>
 * 3: The number is a step <BOOL> (default: true)
 *
 * Return Value:
 * The page, from 0 <NUMBER>
 *
 * Example:
 * private _page = [_grid, 1, -1] call einv_gui_fnc_pageStep;
 *
 * Public: No
 */

params [["_grid", createHashMap, [createHashMap]], ["_from", 0, [0]], ["_number", 1, [0]], ["_relative", true, [false]]];

private _pages = count (_grid getOrDefault ["pageRanges", []]);

if (_pages < 1) exitWith {0};

private _group = [_grid getOrDefault ["holder", _grid getOrDefault ["container", objNull]]] call FUNC(boxGroup);
private _target = [_number, _from + _number] select _relative;

if (_group isEqualTo "") exitWith {(_target min (_pages - 1)) max 0};

// The pages that hold a match.
private _matches = ([_grid] call FUNC(pageCounts)) select 1;
private _visible = [];

{
    if (_x > 0) then {
        _visible pushBack _forEachIndex;
    };
} forEach _matches;

if (_visible isEqualTo []) exitWith {(_from min (_pages - 1)) max 0};

if (!_relative) exitWith {
    private _at = _visible findIf {_x >= _target};

    if (_at < 0) then {
        _at = count _visible - 1;
    };

    _visible select _at
};

// Step by step over the pages that match, from the page the bar is on.
private _page = _from;
private _direction = [-1, 1] select (_number > 0);

for "_i" from 1 to abs _number do {
    private _candidates = _visible select {[_x < _page, _x > _page] select (_direction > 0)};

    if (_candidates isNotEqualTo []) then {
        _page = [_candidates select (count _candidates - 1), _candidates select 0] select (_direction > 0);
    };
};

_page
