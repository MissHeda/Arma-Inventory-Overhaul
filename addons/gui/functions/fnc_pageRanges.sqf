#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Where the pages of a compartment begin and end: the rows [from, to) of each, cut from the top in steps of
 * the page size - but never through a tile. A page ends at the row above a tile that would reach over the cut, so every
 * tile lies whole on one page (a page may be a row or two shorter than the setting says; only when one tile alone is
 * taller than a page does the page grow to take it). Worked out from the layout's entries each time the compartment is
 * drawn: the pages follow what lies there.
 *
 * Arguments:
 * 0: The layout's entries (einv_storage_fnc_getLayout) <ARRAY>
 * 1: The compartment <NUMBER>
 * 2: How many rows are paged - the rows the compartment shows (fnc_viewBlocks) <NUMBER>
 * 3: Rows to a page <NUMBER>
 *
 * Return Value:
 * [[from, to], ...] one per page; a single page when nothing needs cutting <ARRAY>
 *
 * Example:
 * [_entries, 0, 27, 10] call einv_gui_fnc_pageRanges;
 *
 * Public: No
 */

params [["_entries", [], [[]]], ["_block", 0, [0]], ["_total", 0, [0]], ["_perPage", 10, [0]]];

if (_total <= _perPage || {_perPage < 1}) exitWith {[[0, _total]]};

// The cuts a tile reaches over: row n is not a place to cut when a tile starts above it and ends below it.
private _blocked = [];
_blocked resize (_total + 1);
_blocked = _blocked apply {false};

{
    if (_x getOrDefault ["overflow", false] || {(_x getOrDefault ["block", -2]) != _block}) then {continue};

    private _row = _x getOrDefault ["row", 0];
    private _h = _x getOrDefault ["h", 1];

    for "_cut" from (_row + 1) to ((_row + _h - 1) min _total) do {
        _blocked set [_cut, true];
    };
} forEach _entries;

private _ranges = [];
private _from = 0;

while {_from < _total} do {
    private _to = (_from + _perPage) min _total;

    // Up to the row above the tile that would be cut; none to be had, down to the page's end past the tile.
    while {_to > _from + 1 && {_blocked select _to}} do {
        _to = _to - 1;
    };

    if (_to > _from && {_blocked select _to}) then {
        _to = (_from + _perPage) min _total;

        while {_to < _total && {_blocked select _to}} do {
            _to = _to + 1;
        };
    };

    _ranges pushBack [_from, _to];
    _from = _to;
};

_ranges
