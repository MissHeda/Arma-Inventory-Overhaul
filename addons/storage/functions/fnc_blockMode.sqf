#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What a compartment makes of an item: whether it takes it at all, and whether it takes it as a single slot. The one
 * test every place that looks for a spot asks (the layout, op put, move, place, split, the plan, the window's drag), so
 * that an item never lands in a compartment that refuses it, on any machine.
 *
 * A compartment is [cols, rows, holes, pos] and, when it has attributes (grid=2x2:ammo|grenade, grid=1x1:grenade:one,
 * aio_items_fnc_parseGrid), a fifth element, the categories it accepts - [] takes everything - and a sixth, true for a
 * single slot. The item's categories are the "groups" of aio_items_fnc_getInfo: it is accepted when any of them is one
 * the compartment accepts.
 *
 * A single slot holds one tile, whatever its size, and the tile takes the whole slot: its box is the compartment's
 * (cols x rows, holes and all), its cell is 0, 0, and its own size counts for nothing there. See fnc_slotOf.
 *
 * Arguments:
 * 0: The compartment <ARRAY>
 * 1: The item's categories, "groups" of aio_items_fnc_getInfo <ARRAY of STRING>
 *
 * Return Value:
 * -1 it is refused, 0 it is taken like by any compartment, 1 it is taken as a single slot <NUMBER>
 *
 * Example:
 * [[1, 1, [], [], ["grenade"], true], ["grenade"]] call aio_storage_fnc_blockMode; // 1
 *
 * Public: No
 */

params [["_block", [], [[]]], ["_groups", [], [[]]]];

private _accepts = _block param [4, []];

if (_accepts isNotEqualTo [] && {_groups findIf {_x in _accepts} < 0}) exitWith {-1};

parseNumber (_block param [5, false])
