#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * How many rows of each compartment a column shows. Crates and vehicles are big - a vehicle's hold is
 * up to MAX_ROWS rows of STORAGE_COLS cells - and Mia did not want them smaller, only far less to scroll
 * through (0.2.3). So a tall compartment shows its rows down to the last one in use and
 * COLLAPSE_SPARE_ROWS more to put things into, at least COLLAPSE_MIN_ROWS; the empty rows below fold
 * into one line under the grid that says how many there are and opens them (fnc_drawSection,
 * fnc_toggleRows). Nothing of the room is hidden that way: the line names it, the weight beside the caption
 * still counts the whole container, and moves that find a place by themselves (Take all, a quick move, a
 * group packed in) use every row - the column grows with what lands there.
 *
 * Only for what the view shows: the arrangement, the places and every machine's layout stay the
 * container's whole compartments. Rows a move under way goes to (GVAR(inFlight)) count as in use, so
 * their outline is never cut off. A compartment that would hide fewer than COLLAPSE_HIDE_MIN rows shows
 * all of them; one the player opened (GVAR(expanded)) as well, and it can be folded again. A
 * compartment drawn on a canvas (a pos of its own, einv_storage_fnc_blocksFor) never folds: its
 * neighbours lie where they were drawn beside it, and a shorter one would leave a hole in the drawing.
 *
 * Arguments:
 * 0: Layout, see einv_storage_fnc_getLayout <HASHMAP>
 * 1: Holder its places are kept on - the container, or a key <OBJECT or STRING>
 * 2: Cut tall compartments into pages (einv_gui_pageRows) - false for a section that is never paged (default: true) <BOOL>
 *
 * Return Value:
 * [blocks, hidden, foldable, cells, paging] <ARRAY>
 *   blocks   - [cols, rows, holes, pos] per compartment as the column shows it - a shaped one's
 *              holes in the rows folded away go with them
 *   hidden   - how many rows are folded away, all compartments together <NUMBER>
 *   foldable - rows are folded away now, or would be without the player having opened them <BOOL>
 *   cells    - how many cells those rows hold, holes not counted <NUMBER>
 *   paging   - per compartment, [page, [[from, to], ...]] when it is cut into pages (einv_gui_pageRows, fnc_pageRanges:
 *              its blocks entry then holds all the rows the pages cover, and it neither folds nor counts in hidden,
 *              foldable and cells), [] when it is not <ARRAY>
 *
 * Example:
 * ([_layout, _crate] call einv_gui_fnc_viewBlocks) params ["_blocks", "_hidden", "_foldable", "_cells"];
 *
 * Public: No
 */

params [["_layout", createHashMap, [createHashMap]], ["_holder", objNull, [objNull, ""]], ["_pages", true, [true]]];

private _blocks = _layout getOrDefault ["blocks", []];
private _entries = _layout getOrDefault ["entries", []];
private _expanded = _holder in GVAR(expanded);

// The lowest row in use per compartment: what lies there, and what a move under way is bringing.
private _used = _blocks apply {0};

{
    if !(_x getOrDefault ["overflow", false]) then {
        private _block = _x getOrDefault ["block", 0];

        if (_block >= 0 && {_block < count _used}) then {
            _used set [_block, (_used select _block) max ((_x getOrDefault ["row", 0]) + (_x getOrDefault ["h", 1]))];
        };
    };
} forEach _entries;

// A HashMap: _y is a move's record, the cells it goes to second - [holder, block, col, row, w, h].
{
    {
        _x params [["_toHolder", objNull], ["_toBlock", 0], "", ["_toRow", 0], "", ["_toH", 1]];

        if (_toHolder isEqualTo _holder && {_toBlock >= 0} && {_toBlock < count _used}) then {
            _used set [_toBlock, (_used select _toBlock) max (_toRow + _toH)];
        };
    } forEach (_y param [1, []]);
} forEach GVAR(inFlight);

private _hidden = 0;
private _cells = 0;
private _foldable = false;

private _shown = [];
private _paging = [];
private _perPage = [0, call FUNC(pageRows)] select _pages;

{
    _x params ["_cols", "_rows", ["_holes", []], ["_pos", []]];

    private _want = ((_used select _forEachIndex) + COLLAPSE_SPARE_ROWS) max COLLAPSE_MIN_ROWS;
    private _folds = !(_rows - _want < COLLAPSE_HIDE_MIN || {_pos isNotEqualTo []});

    // The rows the compartment shows if the player has not opened them: down to a little below its last row in use, or
    // all of them where that would hide too few.
    private _domain = [_rows, _want] select _folds;

    // Taller than a page: cut into pages over exactly those rows. The pages replace the fold - there is no line to open
    // the empty rows below, the pages end with the spare rows after the last in use - and the player's opening of the rows
    // does not apply (fnc_toggleRows is a line's only).
    if (_perPage > 0 && {_pos isEqualTo []} && {_domain > _perPage}) then {
        private _ranges = [_entries, _forEachIndex, _domain, _perPage] call FUNC(pageRanges);
        private _page = (([_holder, _forEachIndex] call FUNC(pageOf)) min (count _ranges - 1)) max 0;

        _shown pushBack [_cols, _domain, _holes select {_x < _domain * _cols}, _pos];
        _paging pushBack [_page, _ranges];
        continue;
    };

    _paging pushBack [];

    if (!_folds) then {
        _shown pushBack [_cols, _rows, _holes, _pos];
    } else {
        _foldable = true;

        if (_expanded) then {
            _shown pushBack [_cols, _rows, _holes, _pos];
        } else {
            // The holes in the rows that stay keep their indices: a row is as wide as before.
            private _end = _want * _cols;
            private _keptHoles = _holes select {_x < _end};

            _hidden = _hidden + _rows - _want;
            _cells = _cells + (_rows - _want) * _cols - (count _holes - count _keptHoles);
            _shown pushBack [_cols, _want, _keptHoles, _pos];
        };
    };
} forEach _blocks;

[_shown, _hidden, _foldable, _cells, _paging]
