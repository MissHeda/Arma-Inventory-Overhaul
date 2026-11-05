#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The least a column can be made in the edit mode (fnc_openLayoutEditor, fnc_columnRects). A grid column cannot be narrower than its
 * grid, ten cells wide at the tile scale (COLUMN_W): the tile scale is what makes it narrower. Its height is free, it scrolls.
 *
 * Arguments:
 * 0: The column: "equipment", "storage" or "loot" <STRING>
 * 1: A grid column's width <NUMBER>
 *
 * Return Value:
 * [width, height] <ARRAY>
 *
 * Example:
 * ["storage", 0.4] call aio_gui_fnc_columnMinimum;
 *
 * Public: No
 */

params ["_id", "_columnW"];

[[_columnW, UNIT * 8], [SQUARE(UNIT * 12), UNIT * 16]] select (_id isEqualTo "equipment")
