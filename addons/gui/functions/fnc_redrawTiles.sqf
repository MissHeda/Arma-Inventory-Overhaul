#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Draws the tiles of some sections of the loot column anew without building the window: what another
 * player rearranged in a crate, or took out of it, shows within a second while everything else - the
 * scroll of every column, the open kit windows, the hover - stays as it is.
 *
 * Per section the layout is worked out again (einv_storage_fnc_getLayout), its tiles' controls are
 * deleted and the cells they hid shown, the tiles are drawn again (fnc_drawTiles), the caption's weight
 * text is updated, and what is searched is queued anew (fnc_markHidden); then the moves under way
 * (fnc_drawPending), the selection (fnc_drawSelection) and the search field's fading come back. A
 * section folded away has no tiles: only its weight text changes.
 *
 * Only where it is certain to look right: the compartments (and the rows of an open grid, the number of
 * overflow tiles) must be the ones drawn, the Take all or Put all in button must stay what it is, the
 * ground pile must still hold something; the caption then changes in place. The glass and ring of the item
 * being searched go and come back with the queue (fnc_showSearch), wherever it lies.
 * Anything else - a pile that vanished, a rule changed - answers false before a single control is
 * touched, and the caller builds the window anew.
 *
 * Arguments:
 * 0: The sections, by their number in the list of sections the last build drew
 *    (GVAR(context) "lootSections", see fnc_getSignature) <ARRAY of NUMBERs>
 *
 * Return Value:
 * Done - false: the window has to be built anew <BOOL>
 *
 * Example:
 * [[1, 3]] call einv_gui_fnc_redrawTiles;
 *
 * Public: No
 */

disableSerialization;

params [["_numbers", [], [[]]]];

private _display = uiNamespace getVariable [QGVAR(display), displayNull];

if (isNull _display || {_numbers isEqualTo []} || {GVAR(dragging)} || {GVAR(press) isNotEqualTo []}) exitWith {false};

private _lootSections = GVAR(context) getOrDefault ["lootSections", []];
private _grids = uiNamespace getVariable [QGVAR(grids), []];
private _infos = uiNamespace getVariable [QGVAR(sectionInfo), []];
private _theme = GVAR(theme);

// ---------------------------------------------------------------------------
// First look: everything that has to hold, before anything is touched.
// ---------------------------------------------------------------------------
private _jobs = [];
private _ok = true;

{
    private _section = _lootSections param [_x, createHashMap];
    private _holder = _section getOrDefault ["container", objNull];
    private _info = _infos param [_infos findIf {(_x getOrDefault ["holder", objNull]) isEqualTo _holder}, createHashMap];

    if (isNull _holder || {count _info == 0}) exitWith {
        _ok = false;
    };

    private _entries = [_holder] call EFUNC(storage,getContents);

    // A pile that was emptied is no section any more.
    if ((_section get "id") isEqualTo "ground" && {_entries isEqualTo []}) exitWith {
        _ok = false;
    };

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
        ([_layout, _holder] call FUNC(viewBlocks)) params ["_blocks", "", "_foldable"];

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
    };

    _jobs pushBack [_section, _holder, _info, _entries, _layout, _holderGrids];
} forEach _numbers;

if (!_ok) exitWith {false};

// ---------------------------------------------------------------------------
// Then the sections, one by one.
// ---------------------------------------------------------------------------
private _cellColor = _theme getOrDefault ["cell", [1, 1, 1, 0.045]];

if (_cellColor isEqualTo []) then {
    _cellColor = [0, 0, 0, 0];
};

{
    _x params ["_section", "_holder", "_info", "_entries", "_layout", "_holderGrids"];

    // The weight on the caption line.
    private _label = _info get "load";

    if (!isNull _label) then {
        _label ctrlSetText ([_entries] call FUNC(loadText));
    };

    // Folded away: no tiles to draw.
    if (_info get "folded") then {continue};

    // Search knowledge is a count per class on the container, so what was revealed stays so; what is
    // still hidden is queued again from the new arrangement.
    GVAR(searchQueue) = GVAR(searchQueue) select {(_x select 0) isNotEqualTo _holder};

    {
        private _grid = _x;

        {
            {ctrlDelete _x} forEach (_x getOrDefault ["controls", []]);
        } forEach (_grid get "tiles");

        {
            _x ctrlShow true;
            _x ctrlSetBackgroundColor _cellColor;
        } forEach (_grid get "cells");

        _grid set ["tiles", []];
    } forEach _holderGrids;

    [_holder, _layout get "entries"] call FUNC(markHidden);

    // An entry with no room anywhere lies in a row of its own, from the first cell.
    {
        _x set ["col", 0];
        _x set ["row", 0];
    } forEach (_layout get "overflow");

    {
        [_display, _x, _layout, _theme] call FUNC(drawTiles);
    } forEach _holderGrids;

    // Places and cargo disagree: noted for the authority, as a build notes it (fnc_drawCompartments).
    private _driftIndex = GVAR(drift) findIf {(_x select 0) isEqualTo _holder};

    if (_layout getOrDefault ["drift", false]) then {
        if (_driftIndex < 0) then {
            GVAR(drift) pushBack [_holder, _section getOrDefault ["root", objNull], diag_tickTime];
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

[_display] call FUNC(showSearch);

// What lay over the tiles that went: the moves under way, the selection, the search field's fading.
call FUNC(drawPending);
[] call FUNC(drawSelection);

if (GVAR(filter) isNotEqualTo "") then {
    [] call FUNC(applyFilter);
};

// The mouse is on other tiles now, whatever stood still: looked at again, and no double click across it.
GVAR(hover) = [];
GVAR(lastClick) = [[], -1];
GVAR(lastMouse) = [];

true
