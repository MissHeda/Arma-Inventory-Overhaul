#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether an item is of the category a loot box shows (fnc_boxGroup, fnc_itemGroup). No category matches everything.
 * Whether the item was searched is not asked here.
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

_group isEqualTo "" || {([_class] call FUNC(itemGroup)) isEqualTo _group}
