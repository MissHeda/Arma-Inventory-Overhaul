#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Draws the tiles of some sections anew without building the window: what another player rearranged in a
 * crate, or took out of it, shows within a second, and a move of the window's own redraws only the sections
 * it touched (fnc_refresh) - while everything else - the scroll of every column, the open kit windows, the
 * hover - stays as it is. Sections of the loot column, and in the inventory those of the unit's own storage
 * column (a window that attached draws that column its own way).
 *
 * Per section the layout is worked out again (einv_storage_fnc_getLayout), only the tiles that changed
 * are drawn again - a tile that looks as it did is kept with its controls, the others' controls are deleted
 * (fnc_drawTiles) - and the cells' squares follow (fnc_drawCells), the caption's weight text is updated, and what is searched is queued anew (fnc_markHidden); then the moves under way
 * (fnc_drawPending), the selection (fnc_drawSelection) and the search field's fading come back, and an
 * open context menu is made again on top (fnc_raiseMenu) - or closed, when it was opened on a tile of a
 * section drawn anew. A section folded away has no tiles: only its weight text changes.
 *
 * Only where it is certain to look right: the compartments (and the rows of an open grid, the number of
 * overflow tiles) must be the ones drawn, the Take all or Put all in button must stay what it is, the
 * ground pile must still hold something, and the new weight must fit the caption's label - or there must
 * be none when there was none; the caption then changes in place. The chips of the caption lines
 * (what a box is searching or moving, fnc_updateStatus) are made true again after it.
 * Anything else - a pile that vanished, a rule changed - answers false before a single control is
 * touched, and the caller builds the window anew.
 *
 * Arguments:
 * 0: The loot sections, by their number in the list of sections the last build drew
 *    (GVAR(context) "lootSections", see fnc_getSignature) <ARRAY of NUMBERs>
 * 1: The unit's own sections, by their number in GVAR(context) "ownSections" <ARRAY of NUMBERs> (default: [])
 *
 * Return Value:
 * Done - false: the window has to be built anew <BOOL>
 *
 * Example:
 * [[1, 3]] call einv_gui_fnc_redrawTiles;
 * [[0], [2]] call einv_gui_fnc_redrawTiles;
 *
 * Public: No
 */

disableSerialization;

params [["_numbers", [], [[]]], ["_ownNumbers", [], [[]]]];

private _display = uiNamespace getVariable [QGVAR(display), displayNull];

if (
    isNull _display || {_numbers isEqualTo [] && {_ownNumbers isEqualTo []}} || {GVAR(dragging)} || {GVAR(press) isNotEqualTo []}
    || {_ownNumbers isNotEqualTo [] && {!([] call FUNC(isInventoryMode))}}
) exitWith {false};

private _lootSections = GVAR(context) getOrDefault ["lootSections", []];
private _ownSections = GVAR(context) getOrDefault ["ownSections", []];
private _sections = (_numbers apply {_lootSections param [_x, createHashMap]}) + (_ownNumbers apply {_ownSections param [_x, createHashMap]});
private _grids = uiNamespace getVariable [QGVAR(grids), []];
private _infos = uiNamespace getVariable [QGVAR(sectionInfo), []];
private _theme = GVAR(theme);

// ---------------------------------------------------------------------------
// First look: everything that has to hold, before anything is touched.
// ---------------------------------------------------------------------------
private _jobs = [];
private _ok = true;

// The caption's weight, as fnc_drawSection writes it.
private _loadFont = _theme getOrDefault ["font", "PuristaMedium"];
private _loadSize = TEXT_UNIT * 0.46;

{
    private _section = _x;
    private _holder = _section getOrDefault ["container", objNull];
    private _pagedNow = [];
    private _info = _infos param [_infos findIf {(_x getOrDefault ["holder", objNull]) isEqualTo _holder}, createHashMap];

    // A sealed section (fnc_isSealed) has no tiles to draw again: its unsealing, or anything else, builds the window.
    if (isNull _holder || {count _info == 0} || {_info getOrDefault ["sealed", false]}) exitWith {
        _ok = false;
    };

    private _entries = [_holder] call EFUNC(storage,getContents);

    // A pile that was emptied is no section any more.
    if ((_section getOrDefault ["id", ""]) isEqualTo "ground" && {_entries isEqualTo []}) exitWith {
        _ok = false;
    };

    // The weight on the caption line: its label is as wide as the text it was made for, and there is none
    // for a section that held nothing.
    private _label = _info getOrDefault ["load", controlNull];
    private _load = [_entries] call FUNC(loadText);

    if (isNull _label) then {
        if (_load isNotEqualTo "") exitWith {
            _ok = false;
        };
    } else {
        if ((_load getTextWidth [_loadFont, _loadSize]) * TEXT_SLACK > ((ctrlPosition _label) select 2)) exitWith {
            _ok = false;
        };
    };

    if (!_ok) exitWith {};

    private _layout = [_section getOrDefault ["layoutKey", _holder], _entries] call EFUNC(storage,getLayout);
    private _placed = _layout get "entries";

    // Searched tiles decide whether the button is there: it must stay as it is.
    [_holder, _placed, false] call FUNC(markHidden);

    private _revealed = _placed findIf {!(_x getOrDefault ["hidden", false])} >= 0;

    if ((_info get "button") isNotEqualTo (["", _info get "eligible"] select _revealed)) exitWith {
        _ok = false;
    };

    private _holderGrids = [];

    if !(_info get "folded") then {
        {
            if ((_x getOrDefault ["holder", objNull]) isEqualTo _holder && {(_x getOrDefault ["window", ""]) isEqualTo ""}) then {
                _holderGrids pushBack _x;
            };
        } forEach _grids;

        // The compartments drawn are the ones there are, as the column shows them (fnc_viewBlocks: a tall
        // one down to a little below its last row in use - one that would show more or fewer rows now, or
        // fold another number of them away, is built anew), and so is the number of overflow tiles.
        ([_layout, _holder, (_section getOrDefault ["side", ""]) isEqualTo "loot"] call FUNC(viewBlocks)) params ["_blocks", "", "_foldable", "", ["_paging", []]];

        if (_foldable isNotEqualTo (_info getOrDefault ["foldable", false])) exitWith {
            _ok = false;
        };

        private _plain = _holderGrids select {!(_x get "overflow")};
        private _overflow = _holderGrids select {_x get "overflow"};

        if (count _overflow != count (_layout get "overflow")) exitWith {
            _ok = false;
        };

        if (_plain findIf {(_blocks param [_x get "block", []]) isNotEqualTo [_x get "cols", _x get "rows", _x getOrDefault ["holes", []], _x getOrDefault ["pos", []]]} >= 0) exitWith {
            _ok = false;
        };

        // Compartments without a grid hold no cell.
        if (count _plain != count (_blocks select {(_x select 0) * (_x select 1) > 0})) exitWith {
            _ok = false;
        };

        // The pages (fnc_pageRanges): a compartment that was paged still is and the other way round, and the tallest page
        // is as tall as the box was made for - the bar and everything below it lie where they were drawn. The pages
        // themselves may have moved with what lies there; the box is drawn to the page it stands on (below).
        _pagedNow = _paging;

        if (_plain findIf {
            private _now = _paging param [_x get "block", []];
            private _was = _x getOrDefault ["pageRanges", []];

            (_now isEqualTo []) != (_was isEqualTo [])
            || {_now isNotEqualTo [] && {selectMax ((_now select 1) apply {(_x select 1) - (_x select 0)}) != (_x getOrDefault ["pageHeight", 0])}}
        } >= 0) exitWith {
            _ok = false;
        };
    };

    _jobs pushBack [_section, _holder, _info, _entries, _layout, _holderGrids, _load, _pagedNow];
} forEach _sections;

if (!_ok) exitWith {false};

// ---------------------------------------------------------------------------
// Then the sections, one by one.
// ---------------------------------------------------------------------------
private _start = diag_tickTime;
private _keptCount = 0;
private _madeCount = 0;

{
    _x params ["_section", "_holder", "_info", "_entries", "_layout", "_holderGrids", "_load", ["_pagedNow", []]];

    // The weight on the caption line.
    private _label = _info get "load";

    if (!isNull _label) then {
        _label ctrlSetText _load;
    };

    // Folded away: no tiles to draw.
    if (_info get "folded") then {continue};

    // Search knowledge is a count per class on the container, so what was revealed stays so; what is
    // still hidden is queued again from the new arrangement.
    GVAR(searchQueue) = GVAR(searchQueue) select {(_x select 0) isNotEqualTo _holder};

    // A paged compartment's page may have moved with what lies there (a page is cut at a tile, fnc_pageRanges): where
    // the rows that show changed, the box is drawn anew from its panel - none of its tiles lies where it did.
    {
        private _pagedGrid = _x;
        private _paging = _pagedNow param [_pagedGrid getOrDefault ["block", -1], []];

        if (_paging isEqualTo [] || {_pagedGrid getOrDefault ["overflow", false]}) then {continue};

        _pagedGrid set ["pageRanges", _paging select 1];
        _pagedGrid set ["page", _paging select 0];

        private _window = (_paging select 1) select (_paging select 0);

        if (_window isEqualTo [_pagedGrid get "rowFrom", _pagedGrid get "rowTo"]) then {continue};

        {
            {ctrlDelete _x} forEach (_x getOrDefault ["controls", []]);
        } forEach (_pagedGrid get "tiles");

        // And every other control the compartment's tiles made (fnc_createTile, "tileControls").
        {ctrlDelete _x} forEach (_pagedGrid getOrDefault ["tileControls", []]);
        _pagedGrid set ["tileControls", []];

        [_pagedGrid] call FUNC(clearCells);
        _pagedGrid set ["tiles", []];

        {ctrlDelete _x} forEach (_pagedGrid getOrDefault ["panel", []]);

        [_pagedGrid, _window select 0, _window select 1] call FUNC(setWindow);

        (_pagedGrid get "rel") params ["_pageLeft", "_pageTop"];

        _pagedGrid set ["panel", [
            _display, _pagedGrid get "parent", [_pageLeft, _pageTop], _pagedGrid get "cols", _window select 0, _window select 1,
            _pagedGrid getOrDefault ["holes", []], _theme, _pagedGrid getOrDefault ["pageHeight", 0]
        ] call FUNC(drawPagePanel)];
    } forEach _holderGrids;

    // The tiles each grid had: what did not change is kept as it is (fnc_drawTiles), the rest goes below.
    private _before = _holderGrids apply {_x get "tiles"};

    {
        _x set ["tiles", []];
    } forEach _holderGrids;

    [_holder, _layout get "entries"] call FUNC(markHidden);

    // An entry with no room anywhere lies in a row of its own, from the first cell.
    {
        _x set ["col", 0];
        _x set ["row", 0];
    } forEach (_layout get "overflow");

    {
        private _old = _before select _forEachIndex;
        private _left = [_display, _x, _layout, _theme, _old] call FUNC(drawTiles);

        {
            {ctrlDelete _x} forEach (_x getOrDefault ["controls", []]);
        } forEach _left;

        private _kept = count _old - count _left;

        _keptCount = _keptCount + _kept;
        _madeCount = _madeCount + count (_x get "tiles") - _kept;

        // The cells' squares: shown where a tile went, hidden where one came, made where none was yet.
        [_display, _x] call FUNC(drawCells);

        // A paged compartment's bar: what lies on the pages not shown may have changed (it is left alone when it says the same).
        if ((_x getOrDefault ["pageRanges", []]) isNotEqualTo []) then {
            [_display, _x] call FUNC(drawPageBar);
        };
    } forEach _holderGrids;

    // Places and cargo disagree: noted for the authority, as a build notes it (fnc_drawCompartments).
    private _driftIndex = GVAR(drift) findIf {(_x select 0) isEqualTo _holder};

    if (_layout getOrDefault ["drift", false]) then {
        if (_driftIndex < 0) then {
            // The unit's own sections carry no root: worked out as fnc_drawCompartments does.
            private _root = _section getOrDefault ["root", objNull];

            if (isNull _root) then {
                _root = [_holder] call EFUNC(storage,rootOf);
            };

            GVAR(drift) pushBack [_holder, _root, diag_tickTime];
        };
    } else {
        if (_driftIndex >= 0) then {
            GVAR(drift) deleteAt _driftIndex;
        };
    };
} forEach _jobs;

// What is still to be searched, one container after the other, each from the top left (fnc_build).
private _containers = [];

{
    if !((_x select 0) in _containers) then {
        _containers pushBack (_x select 0);
    };
} forEach GVAR(searchQueue);

GVAR(searchQueue) = [GVAR(searchQueue), [], {
    (_containers find (_x select 0)) * 1e7 + ((_x param [5, 0]) + 1) * 100000 + (_x select 2) * 100 + (_x select 3)
}, "ASCEND"] call BIS_fnc_sortBy;

// What lay over the tiles that went: the moves under way, the selection, the search field's fading.
call FUNC(drawPending);
[] call FUNC(drawSelection);

if (GVAR(filter) isNotEqualTo "" || {GVAR(groupFilters) isNotEqualTo []}) then {
    [] call FUNC(applyFilter);
};

// An open context menu (fnc_openMenu): one opened on a tile of a section drawn anew goes - its rows name
// that tile by its number in the grid, which may be another item's now. Any other is made again on top
// (fnc_raiseMenu), over everything drawn here.
if ((uiNamespace getVariable [QGVAR(menu), []]) isNotEqualTo []) then {
    GVAR(menuFor) params [["_menuKind", ""], ["_menuGrid", -1]];

    private _menuHolders = _jobs apply {_x select 1};
    private _target = if (_menuGrid isEqualType 0 && {_menuGrid >= 0}) then {_grids param [_menuGrid, createHashMap]} else {createHashMap};

    if (
        _menuKind isEqualTo "tile" && {(_target getOrDefault ["window", ""]) isEqualTo ""}
        && {(_target getOrDefault ["holder", objNull]) in _menuHolders}
    ) then {
        call FUNC(closeMenu);
    } else {
        [true] call FUNC(raiseMenu);
    };
};

// The mouse is on other tiles now, whatever stood still: looked at again, and no double click across it. The
// hover outline of a tile lay in a group that was drawn anew.
{ctrlDelete _x} forEach (uiNamespace getVariable [QGVAR(hoverRing), []]);
uiNamespace setVariable [QGVAR(hoverRing), []];
GVAR(hover) = [];
GVAR(lastClick) = [[], -1];
GVAR(lastMouse) = [];

// For the timing line of the redraw (fnc_refresh, einv_gui_debugTiming): how many tiles stayed, how many were made.
GVAR(redrawCounts) = [_keptCount, _madeCount, (diag_tickTime - _start) * 1000];

true
