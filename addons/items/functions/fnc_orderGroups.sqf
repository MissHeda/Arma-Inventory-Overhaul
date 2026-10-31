#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Puts a list of categories in the one order they are stored and written in: the eight built-in ones as ITEM_GROUPS lists
 * them, then the categories of the server's own by their ids, alphabetically, without doubles. The order does not depend on
 * which categories a setup defines, so a text reads and writes the same wherever it is looked at (fnc_parseGroups,
 * fnc_formatGroups, fnc_formatGrid). The order the window lists them in is another one: the order they were defined in
 * (fnc_categories).
 *
 * Arguments:
 * 0: The categories <ARRAY of STRING>
 *
 * Return Value:
 * The categories, in order <ARRAY of STRING>
 *
 * Example:
 * [["bandit", "misc", "ammo"]] call einv_items_fnc_orderGroups; // ["ammo", "misc", "bandit"]
 *
 * Public: No
 */

params [["_list", [], [[]]]];

private _unique = _list arrayIntersect _list;
private _others = _unique - ITEM_GROUPS;

_others sort true;

(ITEM_GROUPS select {_x in _unique}) + _others
