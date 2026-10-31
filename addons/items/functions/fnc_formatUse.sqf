#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Writes the value of use= (a rule) or einv_use (an item's config) from the containers, the way
 * fnc_parseUse reads it back: the words in the order uniform, vest, backpack joined with "+" (a comma
 * would end a statement of a rules text) or with the separator given - config uses a comma. No container is
 * "none".
 *
 * Arguments:
 * 0: The containers, any of "uniform", "vest", "backpack" <ARRAY of STRING>
 * 1: What joins the words: "+" for a rules text, "," for config <STRING> (default: "+")
 *
 * Return Value:
 * The value <STRING>
 *
 * Example:
 * [["backpack", "vest"]] call einv_items_fnc_formatUse;
 * // "vest+backpack"
 *
 * Public: No
 */

params [["_kinds", [], [[]]], ["_separator", "+", [""]]];

private _ordered = USE_KINDS select {_x in _kinds};

if (_ordered isEqualTo []) exitWith {"none"};

_ordered joinString _separator
