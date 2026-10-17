#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Selects a tile, as a click on it does:
 *
 *   "only"   - the selection is that tile, and the anchor
 *   "toggle" - Ctrl+click: the tile comes in or goes out; a tile of the other side starts a new selection
 *   "range"  - Shift+click: everything from the anchor to the tile in the anchor's holder, in reading
 *              order (compartment, row, column); with the anchor in another holder, that tile only
 *
 * One side at a time, the unit's own storage or what it loots. A tile not searched yet, one a move is
 * under way for, one on a body's doll, in the overflow row or in a kit's window cannot be selected. The
 * selection is view state and local to this player: it moves nothing (fnc_drawSelection shows it).
 *
 * Arguments:
 * 0: Grid index <NUMBER>
 * 1: Tile index <NUMBER>
 * 2: Mode, "only", "toggle" or "range" <STRING> (default: "only")
 *
 * Return Value:
 * Something is selected now <BOOL>
 *
 * Example:
 * [1, 4, "toggle"] call einv_gui_fnc_select;
 *
 * Public: No
 */

params [["_gridIndex", -1, [0]], ["_tileIndex", -1, [0]], ["_mode", "only", [""]]];

private _grids = uiNamespace getVariable [QGVAR(grids), []];

// What makes a tile selectable, and the ref it is kept by.
private _fnc_ref = {
    params ["_grid", "_tile"];

    if (
        count _tile == 0 || {_tile getOrDefault ["hidden", false]} || {_tile getOrDefault ["pending", false]} || {_tile getOrDefault ["offPage", false]}
        || {_grid getOrDefault ["virtual", true]} || {_grid getOrDefault ["overflow", false]}
        || {(_grid getOrDefault ["window", ""]) isNotEqualTo ""} || {(_grid getOrDefault ["side", ""]) isEqualTo ""}
    ) exitWith {[]};

    private _key = _tile getOrDefault ["key", ""];

    if (_key isEqualTo "") then {
        _key = [_tile] call EFUNC(storage,entryKey);
    };

    [_grid getOrDefault ["holder", objNull], _key, _grid getOrDefault ["block", 0], _tile getOrDefault ["col", 0], _tile getOrDefault ["row", 0]]
};

private _grid = _grids param [_gridIndex, createHashMap];
private _tile = (_grid getOrDefault ["tiles", []]) param [_tileIndex, createHashMap];
private _ref = [_grid, _tile] call _fnc_ref;

if (_ref isEqualTo [] || {(_ref select 0) isEqualType objNull && {isNull (_ref select 0)}}) exitWith {GVAR(selection) isNotEqualTo []};

private _side = _grid get "side";

// Set when the selection stays what it was, so that its frames are not made again for nothing.
private _unchanged = false;

switch (_mode) do {
    case "toggle": {
        if (_side isNotEqualTo GVAR(selectionSide) || {GVAR(selection) isEqualTo []}) then {
            GVAR(selection) = [_ref];
        } else {
            private _at = GVAR(selection) findIf {_x isEqualTo _ref};

            if (_at >= 0) then {
                GVAR(selection) deleteAt _at;
            } else {
                GVAR(selection) pushBack _ref;
            };
        };

        GVAR(selectionAnchor) = _ref;
    };
    case "range": {
        private _anchor = GVAR(selectionAnchor);
        private _holder = _ref select 0;

        // Every tile of the holder that can be selected, in reading order: [compartment, row, column,
        // number of its ref in _refs].
        private _order = [];
        private _refs = [];

        if (_anchor isNotEqualTo [] && {(_anchor select 0) isEqualTo _holder} && {_side isEqualTo GVAR(selectionSide)}) then {
            {
                private _inGrid = _x;

                if ((_inGrid getOrDefault ["holder", objNull]) isNotEqualTo _holder) then {continue};

                {
                    private _inRef = [_inGrid, _x] call _fnc_ref;

                    if (_inRef isNotEqualTo []) then {
                        _order pushBack [_inRef select 2, _inRef select 4, _inRef select 3, _refs pushBack _inRef];
                    };
                } forEach (_inGrid getOrDefault ["tiles", []]);
            } forEach _grids;

            _order sort true;
        };

        private _from = _order findIf {(_refs select (_x select 3)) isEqualTo _anchor};
        private _to = _order findIf {(_refs select (_x select 3)) isEqualTo _ref};

        if (_from < 0 || {_to < 0}) then {
            GVAR(selection) = [_ref];
            GVAR(selectionAnchor) = _ref;
        } else {
            GVAR(selection) = (_order select [_from min _to, (abs (_to - _from)) + 1]) apply {_refs select (_x select 3)};
        };
    };
    default {
        // The tile alone is selected already - lifting a tile that was clicked before: its frames stand.
        _unchanged = GVAR(selection) isEqualTo [_ref] && {GVAR(selectionAnchor) isEqualTo _ref} && {GVAR(selectionSide) isEqualTo _side};

        GVAR(selection) = [_ref];
        GVAR(selectionAnchor) = _ref;
    };
};

GVAR(selectionSide) = [_side, ""] select (GVAR(selection) isEqualTo []);

if (GVAR(selection) isEqualTo []) then {
    GVAR(selectionAnchor) = [];
};

if (!_unchanged) then {
    [] call FUNC(drawSelection);
};

GVAR(selection) isNotEqualTo []
