#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether the draft is the default as a whole: the default rules, and no server setting off its default. What
 * Reset to default has nothing to do for.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * The draft is the default <BOOL>
 *
 * Example:
 * call einv_setup_fnc_atDefault;
 *
 * Public: No
 */

GVAR(draftSettingsText) isEqualTo "" && {GVAR(draftText) isEqualTo ([[RULES_DEFAULT] call EFUNC(items,parseRules)] call EFUNC(items,writeRules))}
