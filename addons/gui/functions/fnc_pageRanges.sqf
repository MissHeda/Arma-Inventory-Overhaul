#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Where the pages of a compartment begin and end: the rows [from, to) of each - a tile is on the page its top row is on -
 * cut from the top in steps of the page size, and the rows [from, shownTo) the page shows. A page ends at the row above a tile
 * that would reach over the cut, so the tiles lie whole on one page (a page may be a row or two shorter than the setting says).
 * Where every row of a page is reached over - tiles two rows high lying staggered, as a full crate of magazines does - it is cut
 * at the row the fewest tiles reach over, and shows as many rows more as its last tiles reach down (shownTo): a page no longer
 * grew to the end of the container then, and every page with it, as all pages are as tall as the tallest. A last page that
 * would hold no tile at all - only the spare rows - is joined to the page before it. Worked out from the layout's entries each
 * time the compartment is drawn: the pages follow what lies there.
 *
 * Arguments:
 * 0: The layout's entries (aio_storage_fnc_getLayout) <ARRAY>
 * 1: The compartment <NUMBER>
 * 2: How many rows are paged - the rows the compartment shows (fnc_viewBlocks) <NUMBER>
 * 3: Rows to a page <NUMBER>
 *
 * Return Value:
 * [[from, to, shownTo], ...] one per page; a single page when nothing needs cutting <ARRAY>
 *
 * Example:
 * [_entries, 0, 27, 10] call aio_gui_fnc_pageRanges;
 *
 * Public: No
 */

params [["_entries", [], [[]]], ["_block", 0, [0]], ["_total", 0, [0]], ["_perPage", 10, [0]]];

if (_total <= _perPage || {_perPage < 1}) exitWith {[[0, _total, _total]]};

// The cuts a tile reaches over: row n is not a place to cut when a tile starts above it and ends below it - and how many do.
private _blocked = [];
_blocked resize (_total + 1);
_blocked = _blocked apply {false};

private _crossing = [];
_crossing resize (_total + 1);
_crossing = _crossing apply {0};

// The lowest row a tile starting on each row reaches down to (its last row + 1).
private _reach = [];
_reach resize (_total + 1);
_reach = _reach apply {0};

{
    if (_x getOrDefault ["overflow", false] || {(_x getOrDefault ["block", -2]) != _block}) then {continue};

    private _row = _x getOrDefault ["row", 0];
    private _h = _x getOrDefault ["h", 1];

    for "_cut" from (_row + 1) to ((_row + _h - 1) min _total) do {
        _blocked set [_cut, true];
        _crossing set [_cut, (_crossing select _cut) + 1];
    };

    if (_row >= 0 && {_row < _total}) then {
        _reach set [_row, (_reach select _row) max ((_row + _h) min _total)];
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

    // No clean cut on the page: the row the fewest tiles reach over, as far down as the page goes. The tiles reaching over
    // it stay on this page, which shows the rows they reach down to.
    if (_to > _from && {_blocked select _to}) then {
        private _best = (_from + _perPage) min _total;

        for "_cut" from ((_from + _perPage) min _total) to (_from + 1) step -1 do {
            if ((_crossing select _cut) < (_crossing select _best)) then {_best = _cut};
        };

        _to = _best;
    };

    private _shownTo = _to;

    for "_row" from _from to (_to - 1) do {
        _shownTo = _shownTo max (_reach select _row);
    };

    _ranges pushBack [_from, _to, _shownTo min _total];
    _from = _to;
};

// A last page with no tile on it - only the spare rows after the last in use - would open a box on what looks like an empty
// container: its rows belong to the page before, which grows by them.
if (count _ranges > 1) then {
    private _lastFrom = (_ranges select -1) select 0;

    if (_entries findIf {
        !(_x getOrDefault ["overflow", false]) && {(_x getOrDefault ["block", -2]) == _block} && {(_x getOrDefault ["row", 0]) >= _lastFrom}
    } < 0) then {
        _ranges deleteAt (count _ranges - 1);
        (_ranges select -1) set [1, _total];
        (_ranges select -1) set [2, _total];
    };
};

_ranges
