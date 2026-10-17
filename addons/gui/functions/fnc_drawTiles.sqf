#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Puts the tiles on one grid: a tile (fnc_createTile) for every entry of the layout that lies in the
 * grid's compartment, or - for the grid of an entry with no room anywhere (overflow) - for that entry.
 * Split out of fnc_drawCompartments so the loot column can draw the tiles of one section anew without
 * building the window again (fnc_redrawTiles).
 *
 * A redraw hands in the tiles the grid had (argument 4): a tile that would look exactly as one of them -
 * the same item on the same cells, turned the same, the same count, rounds, attachments and "?" - is that
 * old tile again, its controls left as they are, with what the new entry says about it taken over (the new
 * entry's keys replace the old ones, those it no longer has go, the controls and marks stay). One item
 * taken from a pile of ninety then makes no ninety tiles again but none, and the circles of the hands'
 * queue on the tiles that stayed stay with them (fnc_drawQueue). A kept tile is made as fresh as a new one:
 * the light of the mouse off it, and faded in again when it was under way and does not wait in the
 * hands' queue (fnc_drawPending fades again what is still under way, as after any redraw). The tiles go on
 * the grid in the layout's order either way, so a tile's number in the grid is what a fresh draw gives.
 * The squares of the cells are the caller's (fnc_drawCells), after this.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Grid, see fnc_createGrid and fnc_drawCompartments <HASHMAP>
 * 2: Layout, see einv_storage_fnc_getLayout <HASHMAP>
 * 3: Theme <HASHMAP>
 * 4: The grid's tiles before a redraw, to keep what did not change <ARRAY> (default: [])
 *
 * Return Value:
 * The tiles of argument 4 not kept - their controls are still there, for the caller to delete <ARRAY>
 *
 * Example:
 * [_display, _grid, _layout, _theme] call einv_gui_fnc_drawTiles;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_grid", "_layout", "_theme", ["_before", [], [[]]]];

private _entries = if (_grid getOrDefault ["overflow", false]) then {
    // One overflow grid per entry, in the order the layout lists them.
    private _entry = (_layout getOrDefault ["overflow", []]) param [_grid getOrDefault ["overflowIndex", 0], createHashMap];

    [[_entry], []] select (count _entry == 0)
} else {
    private _block = _grid getOrDefault ["block", 0];

    (_layout getOrDefault ["entries", []]) select {
        !(_x getOrDefault ["overflow", false]) && {(_x getOrDefault ["block", -2]) == _block}
    }
};

if (_before isEqualTo []) exitWith {
    {
        [_display, _grid, _x, _theme] call FUNC(createTile);
    } forEach _entries;

    []
};

// What a tile looks like: everything fnc_createTile draws it from that can differ between two entries of one grid.
private _fnc_look = {
    params ["_tile"];

    str [
        _tile getOrDefault ["class", ""], _tile getOrDefault ["hidden", false], _tile getOrDefault ["block", 0],
        _tile getOrDefault ["col", 0], _tile getOrDefault ["row", 0], _tile getOrDefault ["w", -1], _tile getOrDefault ["h", -1],
        _tile getOrDefault ["rotated", false], _tile getOrDefault ["holes", []], _tile getOrDefault ["count", 1],
        _tile getOrDefault ["ammo", 0], _tile getOrDefault ["capacity", -1], _tile getOrDefault ["attachments", []],
        _tile getOrDefault ["picture", ""], _tile getOrDefault ["icon", []], _tile getOrDefault ["overflow", false]
    ]
};

// The old tiles' numbers by their look; two alike lie on different cells, so each look has one at most - a list
// all the same.
private _byLook = createHashMap;

{
    private _look = [_x] call _fnc_look;
    private _list = _byLook getOrDefault [_look, []];

    if (_list isEqualTo []) then {
        _byLook set [_look, _list];
    };

    _list pushBack _forEachIndex;
} forEach _before;

// What a tile is drawn as and what marks it on the window: kept from the old tile.
private _drawn = ["controls", "background", "backgrounds", "rect", "color", "mark", "bar", "barRect", "amount", "amountShort", "pending", "queued"];
private _kept = createHashMap;
private _tiles = _grid get "tiles";

{
    private _entry = _x;
    private _list = _byLook getOrDefault [[_entry] call _fnc_look, []];
    private _index = if (_list isEqualTo []) then {-1} else {_list deleteAt 0};
    private _old = _before param [_index, createHashMap];

    if (_index < 0 || {(_old getOrDefault ["controls", []]) findIf {isNull _x} >= 0}) then {
        [_display, _grid, _entry, _theme] call FUNC(createTile);
        continue;
    };

    // The old tile, with what the new entry says (the same HashMap stays: the hands' queue holds it).
    {
        if (!(_x in _entry) && {!(_x in _drawn)}) then {
            _old deleteAt _x;
        };
    } forEach (keys _old);

    _old merge [_entry, true];

    // As fresh as a new tile: unlit, and no longer faded for a move that was answered meanwhile.
    private _color = _old getOrDefault ["color", []];

    if (_color isNotEqualTo []) then {
        {
            _x ctrlSetBackgroundColor _color;
        } forEach (_old getOrDefault ["backgrounds", []]);
    };

    if (_old getOrDefault ["pending", false] && {(_old getOrDefault ["queued", 0]) == 0}) then {
        _old set ["pending", false];

        {
            _x ctrlSetFade 0;
            _x ctrlCommit 0;
        } forEach (_old getOrDefault ["controls", []]);
    };

    _kept set [_index, true];
    _tiles pushBack _old;
} forEach _entries;

private _left = [];

{
    if !(_forEachIndex in _kept) then {
        _left pushBack _x;
    };
} forEach _before;

_left
