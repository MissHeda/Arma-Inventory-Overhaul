#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The ids of every category there is, in the order the window lists them: the eight built-in ones (ITEM_GROUPS), then those the
 * setup defines (category=... in the rules text) in the order they were defined. What the rules in effect define, or - with a
 * compiled setup given - what that one does (the wizard's draft).
 *
 * Arguments:
 * 0: Compiled rules, fnc_compileRules gives them <HASHMAP> (default: the rules in effect)
 *
 * Return Value:
 * The ids - not to be changed <ARRAY of STRING>
 *
 * Example:
 * [] call aio_items_fnc_categories; // ["weapon", "ammo", "grenade", "gear", "medical", "food", "tool", "misc", "bandit"]
 *
 * Public: Yes
 */

params [["_compiled", createHashMap, [createHashMap]]];

if (count _compiled == 0) then {
    _compiled = [] call FUNC(currentRules);
};

_compiled getOrDefault ["categoryIds", ITEM_GROUPS]
