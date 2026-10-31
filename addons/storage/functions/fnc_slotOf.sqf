#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The box a tile takes in a single slot (fnc_blockMode 1): the whole compartment. Its columns and rows, its holes, and
 * the cell 0, 0 - whatever size the item has upright or turned; an item moved out of the slot is its own size again.
 * What the layout writes as the place of such a tile, and what op put, place, split and the plan lay down.
 *
 * Arguments:
 * 0: The compartment <ARRAY>
 *
 * Return Value:
 * [col, row, w, h, holes], 0, 0, then the compartment's columns, rows and holes <ARRAY>
 *
 * Example:
 * [[2, 2, [3], [], ["tool"], true]] call einv_storage_fnc_slotOf; // [0, 0, 2, 2, [3]]
 *
 * Public: No
 */

params [["_block", [], [[]]]];

_block params [["_cols", 1, [0]], ["_rows", 1, [0]], ["_holes", [], [[]]]];

[0, 0, _cols, _rows, +_holes]
