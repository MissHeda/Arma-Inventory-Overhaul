#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Takes the whole setup back to the default: the rules to RULES_DEFAULT, and every server setting to its
 * default. One undo step (fnc_commitSetup); nothing is saved before Save.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call einv_setup_fnc_resetAll;
 *
 * Public: No
 */

[[RULES_DEFAULT] call EFUNC(items,parseRules), createHashMap] call FUNC(commitSetup);
