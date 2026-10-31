#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Fades every tile whose item does not match the search field (GVAR(filter), fnc_drawFilter) - by its
 * name or short name as the window shows them (fnc_matchesFilter) - and brings back every tile that does. The field
 * only marks: what it does not find stays in its place, dimmed. A loot box that has a category chosen at its side
 * (GVAR(groupFilters), fnc_setGroup) shows ONLY that kind of item (Mia, 0.5.7): the tiles of other categories are hidden
 * (their controls not shown, the tile's "filteredOut" true) and the cells they lie on show as the empty cells they look
 * like (their squares are made or shown here, since fnc_drawCells leaves the cells under a tile without one), so the box
 * is a grid with the matching items in it; what is hidden is still on the grid - its cells are taken, a drop on one is
 * refused like a drop on any tile - but the mouse does not find it (fnc_updateHover). The field's dimming works
 * on what the category leaves.
 * Items not searched yet match nothing: what they are is not known - with a category they are hidden, with only the field
 * dimmed. An empty field and no category shows everything. The tiles of a source grid (fnc_createGrid) are never faded, and
 * a window that attached is told afterwards (the "filter" hook).
 *
 * A tile whose controls were just made (a page turned to, a box drawn again) takes its state at once, with no fade in
 * between: its first control carries the state it was given (aio_gui_fx: 0 shown, 1 dimmed, 2 hidden) and none yet means
 * new - so nothing lights up for a moment on a page of a filtered box (Mia, 0.5.7).
 *
 * A tall compartment cut into pages (fnc_pageRanges) is searched on every page, not only the one shown: the
 * tiles of the other pages are on the grid too (fnc_pageCounts). Asked to jump (the field was typed in or emptied, a
 * category chosen), each such box turns to the first page with a match when the page it stands on has none (it stays
 * where it is while it still shows one, so refining a word does not move it) - the pages it moved are kept
 * (GVAR(pagesMoved)) and given back box by box once nothing filters the box any more - the field is empty and the box has
 * no category chosen, whether another box still has one or not -, but for one the player turned himself since. Its bar shows how many matches
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
 * [] call aio_gui_fnc_applyFilter;
 * [true] call aio_gui_fnc_applyFilter;
 *
 * Public: No
 */

disableSerialization;

params [["_jump", false, [false]]];

private _filter = toLower GVAR(filter);
private _display = uiNamespace getVariable [QGVAR(display), displayNull];

// ----- Paged boxes: found on any page -----
if (_jump && {!isNull _display}) then {
    private _grids = uiNamespace getVariable [QGVAR(grids), []];

    // A box is filtered while the field holds something or it has a category of its own chosen: the text is every box's, the
    // category the one box's. The pages that were moved for a box that is filtered no more go back, whether another box still has a
    // category chosen or not.
    private _fnc_filtered = {
        params ["_holder"];

        _filter isNotEqualTo "" || {([_holder] call FUNC(boxGroup)) isNotEqualTo ""}
    };

    private _moved = +GVAR(pagesMoved);

    GVAR(pagesMoved) = _moved select {[_x select 0] call _fnc_filtered};

    {
        _x params ["_holder", "_block", "_back"];

        if ([_holder] call _fnc_filtered) then {continue};

        private _grid = _grids param [
            _grids findIf {
                (_x getOrDefault ["holder", objNull]) isEqualTo _holder && {(_x getOrDefault ["block", -1]) == _block} && {(_x getOrDefault ["pageRanges", []]) isNotEqualTo []}
            }, createHashMap
        ];

        if (count _grid > 0) then {
            [_grid, _back] call FUNC(setPage);
        } else {
            [_holder, _block, _back] call FUNC(pageOf);
        };
    } forEach _moved;

    {
        private _grid = _x;

        if ((_grid getOrDefault ["pageRanges", []]) isEqualTo []) then {continue};

        // A box with nothing filtering it keeps its page; its bar loses the marks.
        if !([_grid getOrDefault ["holder", _grid getOrDefault ["container", objNull]]] call _fnc_filtered) then {
            [_display, _grid] call FUNC(drawPageBar);
            continue
        };

        ([_grid] call FUNC(pageCounts)) params ["", "_matches"];

        private _page = _grid getOrDefault ["page", 0];
        private _first = _matches findIf {_x > 0};

        if ((_matches select _page) == 0 && {_first >= 0}) then {
            [_grid, _first, true] call FUNC(setPage);
        } else {
            [_display, _grid] call FUNC(drawPageBar);
        };
    } forEach _grids;
};

// The squares of the cells under the tiles a category hides, made or shown - and hidden again under a tile that is back. fnc_drawCells
// makes none under a tile; a hidden tile would leave a hole in the box's grid.
private _fnc_cells = {
    params ["_grid", "_anyHidden"];

    private _had = _grid getOrDefault ["filterCells", false];

    if (!_anyHidden && {!_had}) exitWith {};

    _grid set ["filterCells", _anyHidden];

    private _cols = _grid get "cols";
    private _rows = _grid get "rows";
    private _cells = _grid getOrDefault ["cells", []];

    if (_cols < 1 || {_rows < 1} || {count _cells < _cols * _rows}) exitWith {};

    private _parent = _grid getOrDefault ["parent", controlNull];
    private _color = _grid getOrDefault ["cellColor", [1, 1, 1, 0.05]];
    private _colX = _grid get "colX";
    private _rowY = _grid get "rowY";
    private _cellW = _grid get "cellW";
    private _cellH = _grid get "cellH";
    private _rowFrom = _grid getOrDefault ["rowFrom", 0];
    private _rowTo = _grid getOrDefault ["rowTo", _rows];
    private _gridHoles = _grid getOrDefault ["holes", []];
    private _parts = _grid getOrDefault ["cellParts", createHashMap];

    _grid set ["cellParts", _parts];

    (_grid get "rel") params ["_left", "_top"];

    {
        private _tile = _x;
        private _gone = _tile getOrDefault ["filteredOut", false];

        // Only tiles that are drawn have cells to look after; one that is not hidden has a square under it only if it was shown here before.
        if ((_tile getOrDefault ["offPage", false]) || {(_tile getOrDefault ["controls", []]) isEqualTo []} || {!_gone && {!_had}}) then {continue};

        private _col = _tile getOrDefault ["col", 0];
        private _row = _tile getOrDefault ["row", 0];
        private _fullW = _tile getOrDefault ["w", 1];
        private _h = (_tile getOrDefault ["h", 1]) max 1;
        private _w = (_fullW min (_cols - _col)) max 1;
        private _holes = [[], _tile getOrDefault ["holes", []]] select (_w == _fullW);

        for "_r" from (_row max _rowFrom) to ((_row + _h - 1) min (_rowTo - 1)) do {
            for "_c" from _col to ((_col + _w - 1) min (_cols - 1)) do {
                private _index = _r * _cols + _c;

                if (((_r - _row) * _w + _c - _col) in _holes || {_index in _gridHoles}) then {continue};

                private _cell = _cells select _index;

                if (!_gone) then {
                    _cell ctrlShow false;

                    {_x ctrlShow false} forEach (_parts getOrDefault [_index, []]);

                    continue
                };

                if (isNull _cell) then {
                    private _rect = [_left + (_colX select _c), _top + (_rowY select _r), _cellW - pixelW, _cellH - pixelH];
                    private _made = [_display, _parent, _rect, _color, [_grid, _rect] call FUNC(cornerRadii)] call FUNC(uiSurface);

                    _cells set [_index, _made select 0];

                    if (count _made > 1) then {
                        _parts set [_index, _made select [1]];
                    };
                } else {
                    _cell ctrlShow true;

                    {_x ctrlShow true} forEach (_parts getOrDefault [_index, []]);
                };
            };
        };
    } forEach (_grid getOrDefault ["tiles", []]);
};

{
    private _grid = _x;

    // A place things come from (a source grid, as the Arsenal panel makes of ACE's list) holds no container: the search leaves it alone.
    if ((_grid getOrDefault ["source", ""]) isNotEqualTo "") then {continue};

    // The category chosen at the side of this box, if any.
    private _group = [_grid getOrDefault ["holder", _grid getOrDefault ["container", objNull]]] call FUNC(boxGroup);
    private _anyHidden = false;

    // What a class is to the field and to the category, asked once per class in this pass.
    private _byClass = createHashMap;

    {
        private _tile = _x;
        private _class = _tile getOrDefault ["class", ""];
        private _unsearched = _tile getOrDefault ["hidden", false];
        private _answer = _byClass getOrDefault [_class, []];

        if (_answer isEqualTo []) then {
            _answer = [[_class] call FUNC(matchesFilter), [_class, _group] call FUNC(matchesGroup)];
            _byClass set [_class, _answer];
        };

        // A category shows only its own kind: what is not searched yet is of no kind. The field only dims.
        private _gone = _group isNotEqualTo "" && {_unsearched || {!(_answer select 1)}};
        private _match = !_gone && {_filter isEqualTo "" || {!_unsearched && {_answer select 0}}};
        private _state = [[1, 0] select _match, 2] select _gone;

        _tile set ["filteredOut", _gone];

        if (_gone) then {
            _anyHidden = true;
        };

        private _controls = _tile getOrDefault ["controls", []];

        if (_controls isEqualTo []) then {continue};

        private _was = (_controls select 0) getVariable [QGVAR(fx), -1];

        (_controls select 0) setVariable [QGVAR(fx), _state];

        if (_gone) then {
            {_x ctrlShow false} forEach _controls;

            continue
        };

        // Back from hidden: shown at once, in the state it gets.
        if (_was == 2) then {
            {_x ctrlShow true} forEach _controls;
        };

        private _fade = [FILTER_FADE, 0] select _match;

        // New controls take the state at once when a draw asked (no frame at full strength on a page turned to); the field and the strip
        // (the jump) fade as ever, and so do tiles that were shown already.
        private _time = [FILTER_TIME, 0] select ((_was < 0 && {!_jump}) || {_was == 2});

        {
            _x ctrlSetFade _fade;
            _x ctrlCommit _time;
        } forEach _controls;
    } forEach (_grid getOrDefault ["tiles", []]);

    [_grid, _anyHidden] call _fnc_cells;
} forEach (uiNamespace getVariable [QGVAR(grids), []]);

// ----- The caption tabs of folded sections -----

{
    private _info = _x;

    if !(_info getOrDefault ["folded", false]) then {continue};

    private _holder = _info getOrDefault ["holder", objNull];
    private _tab = _info getOrDefault ["tab", []];
    private _tint = false;

    private _foldedGroup = [_holder] call FUNC(boxGroup);

    if ((_filter isNotEqualTo "" || {_foldedGroup isNotEqualTo ""}) && {!isNull _holder}) then {
        // What is searched in there, in the order it lies - the rest is not known to match anything.
        private _placed = ([_holder, [_holder] call EFUNC(storage,getContents)] call EFUNC(storage,getLayout)) get "entries";

        [_holder, _placed, false] call FUNC(markHidden);

        _tint = _placed findIf {
            !(_x getOrDefault ["hidden", false]) && {[_x getOrDefault ["class", ""]] call FUNC(matchesFilter)}
            && {[_x getOrDefault ["class", ""], _foldedGroup] call FUNC(matchesGroup)}
        } >= 0;
    };

    private _color = [
        _info getOrDefault ["tabColor", [0, 0, 0, 0.5]],
        GVAR(theme) getOrDefault ["accentSoft", [0.84, 0.54, 0.1, 0.2]]
    ] select _tint;

    // The tab is a pill now: its round ends are pictures, painted as a surface.
    [_tab, _color] call FUNC(paintSurface);
} forEach (uiNamespace getVariable [QGVAR(sectionInfo), []]);

// The window that attached may show what matches the search in its own places.
["filter", []] call FUNC(hook);
