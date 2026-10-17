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
 * "weapon", "ammo", "grenade", "gear", "medical", "food", "tool" or "misc" (ITEM_GROUPS); "" when the box shows everything <STRING>
 *
 * Example:
 * [_crate] call einv_gui_fnc_boxGroup;
 *
 * Public: No
 */

params [["_holder", objNull, [objNull]]];

if (GVAR(groupFilters) isEqualTo [] || {isNull _holder}) exitWith {""};

private _index = GVAR(groupFilters) findIf {(_x select 0) isEqualTo _holder};

if (_index < 0) exitWith {""};

(GVAR(groupFilters) select _index) select 1
