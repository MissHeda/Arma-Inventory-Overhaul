#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Turns a paged compartment's page for a click on its bar (an arrow, the words) - not once per click when it is clicked fast:
 * the page the player wants is worked out at once (GVAR(pageWanted), per container and compartment: every click moves it on or
 * back from where the last one left it, to the first or the last page at the most) and shown through fnc_coalesce, so a fast
 * run of clicks draws the pages the first one and the last one asked for, not each page between. A drag turns the page
 * itself (fnc_turnPage) and is not slowed by this.
 *
 * Arguments:
 * 0: The grid of a paged compartment <HASHMAP>
 * 1: The step to turn (relative) or the page to go to, from 0 (not relative) <NUMBER>
 * 2: The number is a step <BOOL> (default: true)
 *
 * Return Value:
 * None
 *
 * Example:
 * [_grid, 1] call einv_gui_fnc_pageSoon;
 * [_grid, 0, false] call einv_gui_fnc_pageSoon;
 *
 * Public: No
 */

params [["_grid", createHashMap, [createHashMap]], ["_number", 0, [0]], ["_relative", true, [false]]];

private _ranges = _grid getOrDefault ["pageRanges", []];

if (_ranges isEqualTo []) exitWith {};

private _holder = _grid getOrDefault ["holder", objNull];
private _block = _grid getOrDefault ["block", 0];
private _key = format ["page|%1|%2", _holder, _block];

private _wanted = GVAR(pageWanted) getOrDefault [_key, _grid getOrDefault ["page", 0]];

if (_relative) then {
    _wanted = _wanted + _number;
} else {
    _wanted = _number;
};

GVAR(pageWanted) set [_key, (_wanted min (count _ranges - 1)) max 0];

[_key, {
    params ["_key", "_holder", "_block"];

    private _wanted = GVAR(pageWanted) getOrDefault [_key, -1];

    GVAR(pageWanted) deleteAt _key;

    // The grid as it is now: the window may have been built again since the click.
    private _grids = uiNamespace getVariable [QGVAR(grids), []];
    private _grid = _grids param [
        _grids findIf {
            (_x getOrDefault ["holder", objNull]) isEqualTo _holder && {(_x getOrDefault ["block", -1]) == _block} && {(_x getOrDefault ["pageRanges", []]) isNotEqualTo []}
        }, createHashMap
    ];

    if (_wanted >= 0 && {count _grid > 0}) then {
        [_grid, _wanted] call FUNC(setPage);
    };
}, [_key, _holder, _block], COALESCE_GAP] call FUNC(coalesce);
