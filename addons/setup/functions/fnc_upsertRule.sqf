#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Writes what the Items or Containers step sets for one class into the draft, as that class's own rule
 * class=X > ... - or, for a tree, as the one rule class=X+ > ... that covers the class and every class built
 * on it. All of it is fnc_upsertRules, with the one class; see there for what happens to the rules already
 * written and where the new one goes.
 *
 * Ends in fnc_commit: an undo step, and the step drawn again.
 *
 * Arguments:
 * 0: Class, as config names it <STRING>
 * 1: Values to set: "footprint" ("2x3" or a mask), "stack" <NUMBER>, "grid" (as einv_items_fnc_formatGrid
 *    writes it), "like" (a class), "weight" (kg) <NUMBER>, "name" <STRING>, "icon" ([scale, across, down]
 *    <ARRAY>, einv_items_fnc_parseIcon) <HASHMAP> (default: none)
 * 2: Fields to take away <ARRAY of STRING> (default: [])
 * 3: For the class and every class built on it <BOOL> (default: false)
 *
 * Return Value:
 * Written - false for a class name the rules language cannot hold <BOOL>
 *
 * Example:
 * ["V_PlateCarrier1_rgr", createHashMapFromArray [["grid", "xxxx/x--x+2x3"]]] call einv_setup_fnc_upsertRule;
 *
 * Public: No
 */

params [["_class", "", [""]], ["_set", createHashMap, [createHashMap]], ["_remove", [], [[]]], ["_tree", false, [false]]];

[[[_class, _set, _remove, _tree]]] call FUNC(upsertRules)
