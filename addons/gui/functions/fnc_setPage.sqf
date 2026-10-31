#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Turns a paged compartment to a page: keeps the page for the container (fnc_pageOf, so a window opened on it again
 * shows the same), shows it (fnc_showPage) and ends the search's claim on it - a page the player turned himself stays
 * when the search is emptied (fnc_applyFilter gives back only the pages it moved).
 * Also while an item is dragged (the arrows turn the page when the item is held over one, fnc_updateDrag): what the drag
 * worked out about the grids' geometry and cells is dropped, the next frame works it out anew.
 *
 * Arguments:
 * 0: The grid of a paged compartment <HASHMAP>
 * 1: The page, from 0 <NUMBER>
 * 2: By the search, not the player's hand <BOOL> (default: false)
 *
 * Return Value:
 * It turned <BOOL>
 *
 * Example:
 * [_grid, 3] call aio_gui_fnc_setPage;
 *
 * Public: No
 */

disableSerialization;

params [["_grid", createHashMap, [createHashMap]], ["_page", 0, [0]], ["_bySearch", false, [false]]];

private _display = uiNamespace getVariable [QGVAR(display), displayNull];
private _ranges = _grid getOrDefault ["pageRanges", []];

if (isNull _display || {_ranges isEqualTo []}) exitWith {false};

_page = (_page min (count _ranges - 1)) max 0;

if (_page == (_grid getOrDefault ["page", 0])) exitWith {false};

private _holder = _grid getOrDefault ["holder", objNull];
private _block = _grid getOrDefault ["block", 0];
private _before = _grid getOrDefault ["page", 0];

if (_holder isEqualType objNull && {!isNull _holder}) then {
    [_holder, _block, _page] call FUNC(pageOf);

    // The pages the search moved are given back when it is emptied: not one the player turned since.
    private _moved = GVAR(pagesMoved) findIf {(_x select 0) isEqualTo _holder && {(_x select 1) == _block}};

    if (_bySearch) then {
        if (_moved < 0) then {
            GVAR(pagesMoved) pushBack [_holder, _block, _before];
        };
    } else {
        if (_moved >= 0) then {
            GVAR(pagesMoved) deleteAt _moved;
        };
    };
};

[_display, _grid, _page] call FUNC(showPage);

// A drag under way: what it knows of the grids and their cells is another page's.
if (GVAR(dragging)) then {
    private _room = GVAR(dragRoom);

    {
        _room deleteAt _x;
    } forEach ((keys _room) select {_x in ["geometry", "hold", "spot", "frame"] || {(_x select [0, 6]) isEqualTo "cells|"} || {(_x select [0, 5]) isEqualTo "swap|"}});

    GVAR(lastMouse) = [];
};

true
