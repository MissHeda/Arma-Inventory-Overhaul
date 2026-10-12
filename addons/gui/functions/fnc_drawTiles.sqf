#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Puts the tiles on one grid: a tile (fnc_createTile) for every entry of the layout that lies in the
 * grid's compartment, or - for the grid of an entry with no room anywhere (overflow) - for that entry.
 * Split out of fnc_drawCompartments so the loot column can draw the tiles of one section anew without
 * building the window again (fnc_redrawTiles).
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Grid, see fnc_createGrid and fnc_drawCompartments <HASHMAP>
 * 2: Layout, see einv_storage_fnc_getLayout <HASHMAP>
 * 3: Theme <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, _grid, _layout, _theme] call einv_gui_fnc_drawTiles;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_grid", "_layout", "_theme"];

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

{
    [_display, _grid, _x, _theme] call FUNC(createTile);
} forEach _entries;
