#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Turns a paged compartment one page on or back: a half of its bar, a dragged item held over its outer
 * parts. Stops at the first and the last page.
 *
 * Arguments:
 * 0: The grid of a paged compartment <HASHMAP>
 * 1: -1 back, 1 on <NUMBER>
 *
 * Return Value:
 * It turned <BOOL>
 *
 * Example:
 * [_grid, 1] call einv_gui_fnc_turnPage;
 *
 * Public: No
 */

params [["_grid", createHashMap, [createHashMap]], ["_step", 1, [0]]];

[_grid, (_grid getOrDefault ["page", 0]) + _step] call FUNC(setPage)
