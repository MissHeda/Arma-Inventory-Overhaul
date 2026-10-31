#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The first category of an item, one of the strip at the side of a loot box (fnc_drawGroupStrip). An item may be in several
 * (fnc_matchesGroup asks them all); this is the one it is listed under first. The categories are the item's "groups"
 * (aio_items_fnc_getInfo): what the rules or the item's config say (cats=, aio_cat), else the built-in mapping
 * (aio_items_fnc_defaultGroup) - weapon, ammo, grenade, gear, medical, food, tool or misc. Not kept here: the rules can move
 * an item, and getInfo answers from its own store until they change.
 *
 * Arguments:
 * 0: Item class <STRING>
 *
 * Return Value:
 * the id of a category: "weapon", "ammo", "grenade", "gear", "medical", "food", "tool", "misc" or one the setup defines <STRING>
 *
 * Example:
 * ["arifle_MX_F"] call aio_gui_fnc_itemGroup;
 *
 * Public: No
 */

params [["_class", "", [""]]];

(([_class] call EFUNC(items,getInfo)) getOrDefault ["groups", ["misc"]]) param [0, "misc"]
