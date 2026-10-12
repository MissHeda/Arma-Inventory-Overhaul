#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The rules in effect, compiled (fnc_compileRules) - compiled again first when the settings they come
 * from changed since. In a running mission a setting script does that on every change (fnc_loadRules);
 * this catches what no script reaches: Eden, where CBA runs no setting scripts at all, and the start
 * of a mission before CBA's settings are ready. Asking only here, every machine still ends up with
 * the rules its settings say, not the shipped default.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Compiled rules, shared - do not change them <HASHMAP>
 *
 * Example:
 * (call einv_items_fnc_currentRules) get "cell";
 *
 * Public: Yes
 */

if (isNil QGVAR(ruleset) || {(call FUNC(rulesInputs)) isNotEqualTo GVAR(rulesInputs)}) then {
    [] call FUNC(loadRules);
};

GVAR(ruleset)
