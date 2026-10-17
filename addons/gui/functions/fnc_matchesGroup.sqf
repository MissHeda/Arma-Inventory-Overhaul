#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether an item is of the category a loot box shows (fnc_boxGroup). An item in several categories (cats=, einv_cat,
 * einv_items_fnc_getInfo "groups") matches each of them. No category matches everything. Whether the item was searched is not
 * asked here.
 *
 * Arguments:
 * 0: Class <STRING>
 * 1: The category, "" for none <STRING>
 *
 * Return Value:
 * Matches <BOOL>
 *
 * Example:
 * ["FirstAidKit", "medical"] call einv_gui_fnc_matchesGroup;
 *
 * Public: No
 */

params [["_class", "", [""]], ["_group", "", [""]]];

_group isEqualTo "" || {_group in (([_class] call EFUNC(items,getInfo)) getOrDefault ["groups", ["misc"]])}
