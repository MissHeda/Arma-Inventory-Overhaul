#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What the source the wizard saves to holds for both of its settings (fnc_targetValue), by the setting's name:
 * kept when the wizard opens, to tell at Save whether someone else saved in between.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Setting's name -> [value, priority] <HASHMAP>
 *
 * Example:
 * GVAR(originSource) = call einv_setup_fnc_targetValues;
 *
 * Public: No
 */

createHashMapFromArray ([RULES_SETTING, SETTINGS_SETTING] apply {[_x, [_x] call FUNC(targetValue)]})
