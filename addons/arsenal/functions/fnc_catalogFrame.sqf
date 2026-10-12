#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * What the catalog does every frame: reads the rows of the items in the background for a small share of the
 * frame (WARM_BUDGET, at most WARM_MAX_PER_FRAME classes) - the shown category first -, works out the list
 * when something changed (after a search once the typing has been still for SEARCH_DEBOUNCE seconds), steps
 * the pool by the wheel exactly one card row a turn and follows its scroll bar, rebinds the cards when the
 * first visible row moved, and draws the bar again when its state changed. Nothing is rebound while
 * something is dragged.
 *
 * Changes elsewhere only mark the column ("dirty", "barDirty"); the work is done here, once a frame.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Mouse position [x, y] <ARRAY>
 * 2: Time of the frame <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, getMousePosition, diag_tickTime] call einv_arsenal_fnc_catalogFrame;
 *
 * Public: No
 */

disableSerialization;

params ["", "", ["_now", 0, [0]]];

// The loadouts have their own frame.
if (GVAR(view) isNotEqualTo "items") exitWith {};

private _column = uiNamespace getVariable [QGVAR(column), createHashMap];
private _pool = _column getOrDefault ["pool", controlNull];

if (isNull _pool) exitWith {};

// Held where it is while something is dragged: nothing is rebound under the mouse.
if (EGVAR(gui,dragging)) exitWith {};

// ----- The supply changed, or the rules dropped the rows -----
private _rowCount = count GVAR(rows);

if ((_column getOrDefault ["stamp", -1]) != GVAR(availableStamp) || {_rowCount < (_column getOrDefault ["rowsSeen", 0])}) then {
    _column set ["stamp", GVAR(availableStamp)];
    [true] call FUNC(refreshCatalog);
    _rowCount = count GVAR(rows);
};

_column set ["rowsSeen", _rowCount];

private _searching = EGVAR(gui,filter) isNotEqualTo "";

// ----- Reading the rows in the background: the shown category first -----
private _warmKey = [GVAR(availableStamp), GVAR(category), _searching];

if ((_column getOrDefault ["warmKey", []]) isNotEqualTo _warmKey) then {
    private _categories = call FUNC(categories);
    private _queue = [];
    private _queued = createHashMap;

    private _fnc_take = {
        params ["_category"];

        if ((_category select 1) isEqualTo "identity") exitWith {};

        {
            private _lc = toLowerANSI _x;

            if !(_lc in _queued) then {
                _queued set [_lc, true];

                if !(_lc in GVAR(rows)) then {
                    _queue pushBack _x;
                };
            };
        } forEach (_category select 4);
    };

    if (!_searching) then {
        private _shown = _categories select {(_x select 0) isEqualTo GVAR(category)};

        {
            [_x] call _fnc_take;
        } forEach _shown;
    };

    {
        [_x] call _fnc_take;
    } forEach _categories;

    _column set ["warmKey", _warmKey];
    _column set ["warmQueue", _queue];
    _column set ["warmIndex", 0];
};

private _queue = _column getOrDefault ["warmQueue", []];
private _index = _column getOrDefault ["warmIndex", 0];

if (_index < count _queue) then {
    private _start = diag_tickTime;
    private _read = 0;

    while {_index < count _queue && {_read < WARM_MAX_PER_FRAME} && {diag_tickTime - _start < WARM_BUDGET}} do {
        [_queue select _index] call FUNC(catalogRow);
        _index = _index + 1;
        _read = _read + 1;
    };

    _column set ["warmIndex", _index];
};

// ----- The list -----
private _applied = false;

if (_column getOrDefault ["dirty", false]) then {
    private _wait = _searching && {_now < (_column getOrDefault ["searchAt", 0]) + SEARCH_DEBOUNCE};

    // A list that waits for rows is looked at again a few times a second, not every frame.
    if ((_column getOrDefault ["pending", 0]) > 0 && {_now < (_column getOrDefault ["pendingAt", 0]) + 0.25}) then {
        _wait = true;
    };

    if (!_wait) then {
        private _list = call FUNC(catalogList);

        _column set ["pendingAt", _now];

        if ((_column getOrDefault ["pending", 0]) == 0) then {
            _column set ["dirty", false];
        } else {
            _column set ["list", _list];
        };

        // The pool is as high as the list needs; the speck at its foot gives the engine that height.
        (_column get "pitch") params ["", "_pitchY"];

        private _rows = ceil ((count _list) / (_column get "cols"));
        private _contentH = ((_rows * _pitchY) max (_column get "poolH"));

        _column set ["contentH", _contentH];
        _pool setVariable [QEGVAR(gui,contentH), _contentH];

        private _speck = _column getOrDefault ["speck", controlNull];

        _speck ctrlSetPosition [0, _contentH - pixelH, pixelW, pixelH];
        _speck ctrlCommit 0;

        // The scroll goes back to where this list was left, a frame later: a group whose content changed
        // starts at the top.
        _pool ctrlSetScrollValues [0, -1];
        _column set ["firstRow", 0];
        _column set ["scrollPx", 0];
        _column set ["restoreFrame", diag_frameNo + 1];
        _column set ["wheel", 0];
        _applied = true;

        [false] call FUNC(bindCatalog);

        // The fits chip says what the list was made for.
        private _barFits = [_column getOrDefault ["fitsApplies", false], _column getOrDefault ["fitsLabel", ""]];

        if (_barFits isNotEqualTo (_column getOrDefault ["barFits", []])) then {
            _column set ["barFits", _barFits];
            _column set ["barDirty", true];
        };
    };
};

// ----- Scrolling: the wheel steps one row, the scroll bar is the engine's -----
private _range = (((_column get "contentH") - (_column get "poolH")) max 0);
(_column get "pitch") params ["", "_pitchY"];

private _px = 0;

if (_range > 0) then {
    _px = ((((ctrlScrollValues _pool) select 0) max 0) min 1) * _range;
};

private _wheel = _column getOrDefault ["wheel", 0];
private _restoreFrame = _column getOrDefault ["restoreFrame", -1];

if (_restoreFrame >= 0 && {diag_frameNo >= _restoreFrame} && {!_applied}) then {
    // Where this category was left.
    _column set ["restoreFrame", -1];

    if (_range > 0) then {
        _px = (((_column getOrDefault ["restoreRow", 0]) * _pitchY) min _range) max 0;
        _pool ctrlSetScrollValues [_px / _range, -1];
        _column set ["scrollPx", _px];
        _column set ["snapUntil", diag_frameNo + 2];
    };
} else {
    if (_wheel != 0) then {
        _column set ["wheel", 0];

        if (_range > 0) then {
            private _last = _column getOrDefault ["scrollPx", _px];
            private _row = (((round (_last / _pitchY)) + _wheel) max 0) min (ceil (_range / _pitchY));

            _px = (_row * _pitchY) min _range;
            _pool ctrlSetScrollValues [_px / _range, -1];
            _column set ["scrollPx", _px];
            _column set ["snapUntil", diag_frameNo + 2];
        };
    } else {
        if (diag_frameNo <= (_column getOrDefault ["snapUntil", -1]) && {_range > 0}) then {
            // The engine took its own step on the wheel: ours holds for a frame or two.
            private _held = _column getOrDefault ["scrollPx", 0];

            if (abs (_px - _held) > pixelH * 0.5) then {
                _pool ctrlSetScrollValues [_held / _range, -1];
                _px = _held;
            };
        } else {
            _column set ["scrollPx", _px];
        };
    };
};

private _firstRow = floor ((_px + pixelH * 0.25) / _pitchY);

if (_firstRow != (_column getOrDefault ["firstRow", 0])) then {
    _column set ["firstRow", _firstRow];
    GVAR(scrollRows) set [GVAR(category), _firstRow];
    [false] call FUNC(bindCatalog);
};

// ----- A line for a list that is empty, or being read -----
private _pending = _column getOrDefault ["pending", 0];
private _listCount = count (_column getOrDefault ["list", []]);
private _state = if (_pending > 0) then {"loading"} else {
    if (_listCount > 0) then {""} else {["empty", "nomatch"] select _searching}
};

private _progress = 1 - _pending / ((_column getOrDefault ["pendingTotal", 1]) max 1);
private _stateKey = [_state, round (_progress * 40)];

if (_stateKey isNotEqualTo (_column getOrDefault ["emptyState", []])) then {
    _column set ["emptyState", _stateKey];

    private _label = _column getOrDefault ["emptyCtrl", controlNull];
    private _track = _column getOrDefault ["loadTrack", controlNull];
    private _fill = _column getOrDefault ["loadFill", controlNull];

    _label ctrlSetText (switch (_state) do {
        case "loading": {LLSTRING(Catalog_Loading)};
        case "nomatch": {LLSTRING(Catalog_NoMatch)};
        case "empty": {LLSTRING(Catalog_Empty)};
        default {""};
    });
    _label ctrlShow (_state isNotEqualTo "");
    _track ctrlShow (_state isEqualTo "loading");
    _fill ctrlShow (_state isEqualTo "loading");

    if (_state isEqualTo "loading") then {
        (_column get "loadRect") params ["_loadX", "_loadY", "_loadW", "_loadH"];

        _fill ctrlSetPosition [_loadX, _loadY, (_loadW * _progress) max pixelW, _loadH];
        _fill ctrlCommit 0;
    };
};

// ----- The bar -----
if (_column getOrDefault ["barDirty", false]) then {
    call FUNC(drawCatalogBar);
};
