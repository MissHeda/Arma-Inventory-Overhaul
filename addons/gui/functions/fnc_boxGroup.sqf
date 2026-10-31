#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The category chosen at the side of a loot box (fnc_drawGroupStrip, fnc_setGroup): what fnc_applyFilter and
 * fnc_pageCounts fade the tiles of that box by.
 *
 * Arguments:
 * 0: The box's container <OBJECT>
 *
 * Return Value:
 * the id of a category - "weapon", "ammo", "grenade", "gear", "medical", "food", "tool", "misc" (ITEM_GROUPS) or one the setup defines; "" when the box shows everything <STRING>
 *
 * Example:
 * [_crate] call aio_gui_fnc_boxGroup;
 *
 * Public: No
 */

// A holder is an object, or a string for the holders that are none (a kit's holder id, the arsenal's staging).
params [["_holder", objNull, [objNull, ""]]];

if (GVAR(groupFilters) isEqualTo [] || {_holder isEqualTo objNull} || {_holder isEqualTo ""}) exitWith {""};

private _index = GVAR(groupFilters) findIf {(_x select 0) isEqualTo _holder};

if (_index < 0) exitWith {""};

(GVAR(groupFilters) select _index) select 1
