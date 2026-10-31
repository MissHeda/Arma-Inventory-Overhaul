#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Whether a tile waits in the hands' queue: one look at the index of its cell (fnc_queueIndex), however long the
 * queue is.
 *
 * Arguments:
 * 0: Source of the tile, [holder, key, block, col, row] as the moves in flight name it <ARRAY>
 *
 * Return Value:
 * It waits <BOOL>
 *
 * Example:
 * [[_crate, "arifle_MX_F", 0, 2, 3]] call einv_gui_fnc_queueWaits;
 *
 * Public: No
 */

params [["_source", [], [[]]]];

_source params ["_holder", "_key", ["_block", 0], ["_col", -1], ["_row", -1]];

(GVAR(handWaiting) getOrDefault [format ["%1_%2", _col, _row], []]) findIf {
    (_x select 0) isEqualTo _holder && {(_x select 1) isEqualTo _key} && {(_x select 2) isEqualTo _block}
} >= 0
