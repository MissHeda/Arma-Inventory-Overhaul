#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Where the selected tiles are on the window now: the selection is kept as what its tiles stand for
 * (GVAR(selection): holder, key, compartment, cell), so it survives every build and another player's
 * rearranging. A tile that is not found - moved by someone else, taken, a move of it under way, not
 * searched - silently drops out of the selection.
 *
 * Only the tiles of the columns count: a kit's window and a body's worn gear are never selected.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Tiles, [[grid index, tile index], ...], in the order they were selected <ARRAY>
 *
 * Example:
 * call einv_gui_fnc_selectionTiles;
 *
 * Public: No
 */

if (GVAR(selection) isEqualTo []) exitWith {[]};

private _grids = uiNamespace getVariable [QGVAR(grids), []];
private _found = [];
private _kept = [];

{
    _x params ["_holder", "_key", "_block", "_col", "_row"];

    private _ref = _x;
    private _at = [];

    {
        private _gridIndex = _forEachIndex;
        private _grid = _x;

        if (
            (_grid getOrDefault ["holder", objNull]) isEqualTo _holder
            && {(_grid getOrDefault ["block", 0]) == _block}
            && {!(_grid getOrDefault ["virtual", true])}
            && {(_grid getOrDefault ["window", ""]) isEqualTo ""}
        ) then {
            private _tileIndex = (_grid getOrDefault ["tiles", []]) findIf {
                (_x getOrDefault ["col", -1]) == _col
                && {(_x getOrDefault ["row", -1]) == _row}
                && {(_x getOrDefault ["key", ""]) isEqualTo _key}
                && {!(_x getOrDefault ["hidden", false])}
                && {!(_x getOrDefault ["pending", false])}
                && {!(_x getOrDefault ["offPage", false])}
            };

            if (_tileIndex >= 0) then {
                _at = [_gridIndex, _tileIndex];
            };
        };

        if (_at isNotEqualTo []) exitWith {};
    } forEach _grids;

    if (_at isNotEqualTo []) then {
        _found pushBack _at;
        _kept pushBack _ref;
    };
} forEach GVAR(selection);

// What dropped out stays out.
if (count _kept != count GVAR(selection)) then {
    GVAR(selection) = _kept;

    if (_kept isEqualTo []) then {
        GVAR(selectionSide) = "";
        GVAR(selectionAnchor) = [];
    };
};

_found
