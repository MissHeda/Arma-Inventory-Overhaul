#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Draws the repack in progress on the window that was just built (the end of einv_gui_fnc_build): its
 * tiles are found again by where each magazine lies (container, cell, class and rounds), and each one gets
 * a film in the accent colour, a bar of its own over the tile's fill bar that grows and shrinks with every
 * round (where the tile has a fill bar), and its rounds text counts live. The ring that fills on the
 * magazine being filled is made by fnc_showProgress. Every control lives in a tile's group, so the next
 * build deletes them and this draws them anew on the new tiles.
 *
 * A tile that cannot be found - somebody took the magazine, the window shows something else - interrupts
 * the repack, a frame later: this runs inside the build, and stopping builds the window again.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display] call einv_magazines_fnc_drawJob;
 *
 * Public: No
 */

disableSerialization;

params [["_display", displayNull, [displayNull]]];

// The last overlay is gone with its groups after a build; whatever is left is deleted.
{
    ctrlDelete _x;
} forEach ((uiNamespace getVariable [QGVAR(fx), createHashMap]) getOrDefault ["controls", []]);

private _fx = createHashMapFromArray [
    ["controls", []], ["parts", []], ["tiles", []], ["ring", []], ["ringOn", -1], ["step", 0]
];

uiNamespace setVariable [QGVAR(fx), _fx];

private _job = GVAR(job);

if (count _job == 0 || {isNull _display}) exitWith {};

private _grids = uiNamespace getVariable [QEGVAR(gui,grids), []];
private _key = toLowerANSI (_job get "class");
private _parts = _job get "parts";
private _theme = EGVAR(gui,theme);

// Which tile each part is: at its cell first, else any tile of the container with that class and rounds
// that no other part took. Pile parts share a tile.
private _taken = [];
private _tiles = [];
private _missing = false;

{
    _x params ["_container", "_cell", "_rounds", "_count"];
    _cell params ["_col", "_row", "_block"];

    private _found = [];

    // [grid index, tile index] of the first tile that matches; "exact" asks for the very cell as well.
    private _fnc_find = {
        params ["_exact"];

        private _result = [];

        {
            private _gridIndex = _forEachIndex;
            private _grid = _x;

            if (
                (_grid getOrDefault ["container", objNull]) isEqualTo _container
                && {!(_grid getOrDefault ["virtual", true])}
                && {!(_grid getOrDefault ["overflow", false])}
            ) then {
                {
                    private _tileIndex = _forEachIndex;

                    if (
                        toLowerANSI (_x getOrDefault ["class", ""]) isEqualTo _key
                        && {(_x getOrDefault ["ammo", -1]) == _rounds}
                        && {!(_x getOrDefault ["hidden", false])} && {!(_x getOrDefault ["strict", false])}
                        && {_count > 1 || {!([_gridIndex, _tileIndex] in _taken)}}
                        && {!_exact || {(_x get "col") == _col && {(_x get "row") == _row} && {(_x getOrDefault ["block", 0]) == _block}}}
                    ) exitWith {
                        _result = [_gridIndex, _tileIndex];
                    };
                } forEach (_grid getOrDefault ["tiles", []]);
            };

            if (_result isNotEqualTo []) exitWith {};
        } forEach _grids;

        _result
    };

    _found = [true] call _fnc_find;

    if (_found isEqualTo []) then {
        _found = [false] call _fnc_find;
    };

    if (_found isEqualTo []) exitWith {
        _missing = true;
    };

    // Found elsewhere in the container: the commit follows the tile.
    private _tile = ((_grids select (_found select 0)) get "tiles") select (_found select 1);

    _x set [1, [_tile get "col", _tile get "row", _tile getOrDefault ["block", 0], _tile get "w", _tile get "h"]];

    if (_count <= 1) then {
        _taken pushBack _found;
    };

    _tiles pushBack _found;
} forEach _parts;

if (_missing) exitWith {
    // A frame later: this runs inside the build, and the stop builds the window again.
    [{["Interrupted"] call FUNC(stop)}] call CBA_fnc_execNextFrame;
};

private _controls = _fx get "controls";

// Where each tile drawn on lies, by "grid|tile": [its group, its rectangle in it] - a pile shared by several
// parts is drawn once.
private _drawn = createHashMap;

{
    private _tile = ((_grids select (_x select 0)) get "tiles") select (_x select 1);
    private _background = _tile getOrDefault ["background", controlNull];

    private _at = format ["%1|%2", _x select 0, _x select 1];

    // The first part on a tile draws on it; the others sharing it only know where it is.
    if (isNull _background || {_at in _drawn}) then {
        (_fx get "parts") pushBack [controlNull, 0, controlNull, false];
        (_fx get "tiles") pushBack (_drawn getOrDefault [_at, []]);
        continue;
    };

    private _parent = ctrlParentControlsGroup _background;
    // Its box: a shaped tile's first surface is only its top row's first run (einv_gui_fnc_createTile).
    private _rect = _tile getOrDefault ["rect", ctrlPosition _background];

    _drawn set [_at, [_parent, _rect]];

    // The film: the tile in the accent colour.
    private _film = [_display, "EINV_PanelRect", _parent, _rect] call EFUNC(gui,uiCreate);
    _film ctrlSetBackgroundColor (_theme getOrDefault ["accentSoft", [0.84, 0.54, 0.1, 0.2]]);
    _controls pushBack _film;

    // The tile's own fill bar goes under a bar of ours, which moves with the rounds.
    private _fill = controlNull;
    private _barW = 0;
    private _barRect = _tile getOrDefault ["barRect", []];

    if ((_tile getOrDefault ["bar", []]) isNotEqualTo [] && {_barRect isNotEqualTo []}) then {
        {
            _x ctrlShow false;
        } forEach (_tile get "bar");

        _barW = _barRect select 2;

        private _bar = [
            _display, _parent, _barRect, 1,
            _theme getOrDefault ["barTrack", [1, 1, 1, 0.06]], _theme getOrDefault ["barFill", [0.84, 0.54, 0.1, 1]], 0
        ] call EFUNC(gui,uiBar);

        _controls append _bar;
        _fill = _bar select -1;
    };

    (_fx get "parts") pushBack [_fill, _barW, _tile getOrDefault ["amount", controlNull], _tile getOrDefault ["amountShort", false]];
    (_fx get "tiles") pushBack [_parent, _rect];
} forEach _tiles;

_fx set ["ringOn", -1];
_job set ["hintLeft", -1];

[] call FUNC(showProgress);
