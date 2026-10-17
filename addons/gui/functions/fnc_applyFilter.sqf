#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Fades every tile whose item does not match the search field (GVAR(filter), fnc_drawFilter) - by its
 * name or short name as the window shows them (fnc_matchesFilter) - and brings back every tile that does.
 * Items not searched yet match nothing: what they are is not known. An empty field shows everything. The
 * tiles of a source grid (fnc_createGrid) are never faded, and a window that attached is told afterwards
 * (the "filter" hook).
 *
 * A tall compartment cut into pages (fnc_pageRanges) is searched on every page, not only the one shown: the
 * tiles of the other pages are on the grid too (fnc_pageCounts). Asked to jump (the field was typed in or emptied),
 * each such box turns to the first page with a match when the page it stands on has none (it stays where it is while
 * it still shows one, so refining a word does not move it) - the pages it moved are kept (GVAR(pagesMoved)) and
 * given back when the field is emptied, but for one the player turned himself since. Its bar shows how many matches
 * lie before and after the page (fnc_drawPageBar). The tiles that match are the ones not faded, as ever.
 *
 * A section folded away to its caption (fnc_drawSection) shows no tile to fade, so with text in the field
 * its caption tab is tinted in the soft accent colour when something searched in it matches - the player
 * knows which crate to unfold.
 *
 * Arguments:
 * 0: Turn the paged boxes to what the search found, or back when it is empty - the field changed <BOOL> (default: false)
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call einv_gui_fnc_applyFilter;
 * [true] call einv_gui_fnc_applyFilter;
 *
 * Public: No
 */

disableSerialization;

params [["_jump", false, [false]]];

private _filter = toLower GVAR(filter);
private _display = uiNamespace getVariable [QGVAR(display), displayNull];

// ----- Paged boxes: found on any page -----
if (_jump && {!isNull _display}) then {
    if (_filter isEqualTo "") then {
        // Emptied: the pages the search moved go back.
        private _moved = +GVAR(pagesMoved);

        GVAR(pagesMoved) = [];

        {
            _x params ["_holder", "_block", "_back"];

            private _grid = (uiNamespace getVariable [QGVAR(grids), []]) param [
                (uiNamespace getVariable [QGVAR(grids), []]) findIf {
                    (_x getOrDefault ["holder", objNull]) isEqualTo _holder && {(_x getOrDefault ["block", -1]) == _block} && {(_x getOrDefault ["pageRanges", []]) isNotEqualTo []}
                }, createHashMap
            ];

            if (count _grid > 0) then {
                [_grid, _back] call FUNC(setPage);
            } else {
                [_holder, _block, _back] call FUNC(pageOf);
            };
        } forEach _moved;

        // The marks on the arrows go.
        {
            if ((_x getOrDefault ["pageRanges", []]) isNotEqualTo []) then {
                [_display, _x] call FUNC(drawPageBar);
            };
        } forEach (uiNamespace getVariable [QGVAR(grids), []]);
    } else {
        {
            private _grid = _x;

            if ((_grid getOrDefault ["pageRanges", []]) isEqualTo []) then {continue};

            ([_grid] call FUNC(pageCounts)) params ["", "_matches"];

            private _page = _grid getOrDefault ["page", 0];
            private _first = _matches findIf {_x > 0};

            if ((_matches select _page) == 0 && {_first >= 0}) then {
                [_grid, _first, true] call FUNC(setPage);
            } else {
                [_display, _grid] call FUNC(drawPageBar);
            };
        } forEach (uiNamespace getVariable [QGVAR(grids), []]);
    };
};

{
    // A place things come from (a source grid, as the Arsenal panel makes of ACE's list) holds no container: the search leaves it alone.
    if ((_x getOrDefault ["source", ""]) isNotEqualTo "") then {continue};

    {
        private _tile = _x;
        private _match = _filter isEqualTo "" || {
            !(_tile getOrDefault ["hidden", false]) && {[_tile getOrDefault ["class", ""]] call FUNC(matchesFilter)}
        };

        private _fade = [FILTER_FADE, 0] select _match;

        {
            _x ctrlSetFade _fade;
            _x ctrlCommit FILTER_TIME;
        } forEach (_tile getOrDefault ["controls", []]);
    } forEach (_x getOrDefault ["tiles", []]);
} forEach (uiNamespace getVariable [QGVAR(grids), []]);

// ----- The caption tabs of folded sections -----

{
    private _info = _x;

    if !(_info getOrDefault ["folded", false]) then {continue};

    private _holder = _info getOrDefault ["holder", objNull];
    private _tab = _info getOrDefault ["tab", []];
    private _tint = false;

    if (_filter isNotEqualTo "" && {!isNull _holder}) then {
        // What is searched in there, in the order it lies - the rest is not known to match anything.
        private _placed = ([_holder, [_holder] call EFUNC(storage,getContents)] call EFUNC(storage,getLayout)) get "entries";

        [_holder, _placed, false] call FUNC(markHidden);

        _tint = _placed findIf {
            !(_x getOrDefault ["hidden", false]) && {[_x getOrDefault ["class", ""]] call FUNC(matchesFilter)}
        } >= 0;
    };

    private _color = [
        _info getOrDefault ["tabColor", [0, 0, 0, 0.5]],
        GVAR(theme) getOrDefault ["accentSoft", [0.84, 0.54, 0.1, 0.2]]
    ] select _tint;

    {
        _x ctrlSetBackgroundColor _color;
    } forEach _tab;
} forEach (uiNamespace getVariable [QGVAR(sectionInfo), []]);

// The window that attached may show what matches the search in its own places.
["filter", []] call FUNC(hook);
