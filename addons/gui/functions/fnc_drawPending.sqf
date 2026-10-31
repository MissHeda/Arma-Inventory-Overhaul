#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Shows what is under way, at the end of every build (fnc_build): each tile a move in flight takes from
 * (GVAR(inFlight)) fades (DRAG_SOURCE_FADE) and is flagged "pending", so it cannot be pressed or
 * dragged, and each cell it goes to gets a thin outline in the theme's accentSoft. Nothing is shown in
 * its new place before it got there.
 *
 * The hands' queue (fnc_queueMoves) is drawn here too (fnc_drawQueue): the tiles of the actions waiting are
 * flagged and faded the same way and the marks made, whether or not a move is in flight.
 *
 * A tile is found by its holder - a grid's "holder", else its container or, for a kit's grid, its
 * layout key - its key and its cell; one that moved meanwhile simply is not marked. Safe to call again
 * without a build: the outlines of the last call go first.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call aio_gui_fnc_drawPending;
 *
 * Public: No
 */

disableSerialization;

{ctrlDelete _x} forEach (uiNamespace getVariable [QGVAR(pendingFrames), []]);
uiNamespace setVariable [QGVAR(pendingFrames), []];

private _display = uiNamespace getVariable [QGVAR(display), displayNull];

if (isNull _display) exitWith {};

// The actions waiting for the hands (fnc_queueMoves) have their marks drawn here as well: this
// is what every build and every redraw of tiles ends with.
if (count GVAR(inFlight) == 0) exitWith {
    [_display] call FUNC(drawQueue);
};

// Only grids items can lie on - not a body's worn gear, not the overflow - each with its holder.
private _grids = (uiNamespace getVariable [QGVAR(grids), []]) select {
    !(_x getOrDefault ["virtual", true]) && {!(_x getOrDefault ["overflow", false])}
};

private _holders = _grids apply {
    if ((_x getOrDefault ["kit", ""]) isEqualTo "") then {
        _x getOrDefault ["holder", _x getOrDefault ["container", objNull]]
    } else {
        _x getOrDefault ["holder", _x getOrDefault ["layoutKey", ""]]
    };
};

private _color = GVAR(theme) getOrDefault ["accentSoft", [0.84, 0.54, 0.1, 0.2]];
private _frames = [];

{
    _y params [["_sources", [], [[]]], ["_targets", [], [[]]]];

    {
        _x params ["_holder", "_key", ["_block", 0], ["_col", -1], ["_row", -1]];

        {
            private _grid = _x;

            if ((_holders select _forEachIndex) isNotEqualTo _holder || {(_grid getOrDefault ["block", 0]) != _block}) then {continue};

            {
                private _tile = _x;

                if ((_tile getOrDefault ["col", -2]) != _col || {(_tile getOrDefault ["row", -2]) != _row}) then {continue};

                private _tileKey = _tile getOrDefault ["key", ""];

                if (_tileKey isEqualTo "") then {
                    _tileKey = [_tile] call EFUNC(storage,entryKey);
                };

                if (_tileKey isEqualTo _key) then {
                    _tile set ["pending", true];

                    {
                        _x ctrlSetFade DRAG_SOURCE_FADE;
                        _x ctrlCommit 0;
                    } forEach (_tile getOrDefault ["controls", []]);
                };
            } forEach (_grid getOrDefault ["tiles", []]);
        } forEach _grids;
    } forEach _sources;

    {
        _x params ["_holder", ["_block", 0], ["_col", 0], ["_row", 0], ["_w", 1], ["_h", 1]];

        {
            private _grid = _x;

            if ((_holders select _forEachIndex) isNotEqualTo _holder || {(_grid getOrDefault ["block", 0]) != _block}) then {continue};

            // The cells of another page of a paged box are not on the window: no outline lies over what is there.
            if (_row + _h <= (_grid getOrDefault ["rowFrom", 0]) || {_row >= (_grid getOrDefault ["rowTo", 1e6])}) then {continue};

            // As a tile ends a pixel before the next cell, so does its outline, where the grid's columns and rows
            // lie (fnc_spanRect); round at the corner of the compartment's panel it touches (fnc_uiOutline).
            private _outlineRect = [_grid, _grid getOrDefault ["rel", [0, 0]], _col, _row, _w, _h] call FUNC(spanRect);

            _frames append ([
                _display, _grid getOrDefault ["parent", controlNull], _outlineRect, _color,
                [_grid, _outlineRect] call FUNC(cornerRadii), 1
            ] call FUNC(uiOutline));
        } forEach _grids;
    } forEach _targets;
} forEach GVAR(inFlight);

uiNamespace setVariable [QGVAR(pendingFrames), _frames];

[_display] call FUNC(drawQueue);
