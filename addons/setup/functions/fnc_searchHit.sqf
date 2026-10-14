#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether a class is what a search looks for (fnc_searchFilter). A plain text is found anywhere in the
 * class and the name; a wildcard must fit the class or the name as a whole.
 *
 * Arguments:
 * 0: The filter fnc_searchFilter gave <ARRAY>
 * 1: What a plain text looks through: the class, a space and the name, lowercase <STRING>
 * 2: The class, lowercase <STRING>
 * 3: The name, as shown <STRING>
 *
 * Return Value:
 * Found <BOOL>
 *
 * Example:
 * [["b_bergen*", "^b_bergen.*$", "b_bergen"], "b_bergen_mcamo_f bergen", "b_bergen_mcamo_f", "Bergen"] call einv_setup_fnc_searchHit;
 *
 * Public: No
 */

params [["_filter", [], [[]]], ["_search", "", [""]], ["_lc", "", [""]], ["_name", "", [""]]];

_filter params [["_needle", "", [""]], ["_expression", "", [""]], ["_literal", "", [""]]];

if (_needle isEqualTo "") exitWith {true};

if (_expression isEqualTo "") exitWith {(_search find _needle) >= 0};

// The longest run of plain characters has to be somewhere in it, whatever else the wildcard asks.
if (_literal isNotEqualTo "" && {(_search find _literal) < 0}) exitWith {false};

_lc regexMatch _expression || {(toLower _name) regexMatch _expression}
