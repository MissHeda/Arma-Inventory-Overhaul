#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Writes the value of cats= (a rule) or einv_cat (an item's config) from the categories, the way
 * fnc_parseGroups reads it back: the words in the order of ITEM_GROUPS joined with "+" (a comma would end a
 * statement of a rules text) or with the separator given - config uses a comma. A grid's "accepts" is
 * written with a bar (fnc_formatGrid). No category at all is "".
 *
 * Arguments:
 * 0: The categories, any of ITEM_GROUPS <ARRAY of STRING>
 * 1: What joins the words: "+" for a rules text, "," for config <STRING> (default: "+")
 *
 * Return Value:
 * The value <STRING>
 *
 * Example:
 * [["misc", "medical"]] call einv_items_fnc_formatGroups;
 * // "medical+misc"
 *
 * Public: No
 */

params [["_groups", [], [[]]], ["_separator", "+", [""]]];

(ITEM_GROUPS select {_x in _groups}) joinString _separator
