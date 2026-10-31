#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What the source the wizard saves to holds for the rules (fnc_targetValue), by the setting's name: kept when
 * the wizard opens, to tell at Save whether someone else saved in between. The server settings need no such
 * check: each follows a change made elsewhere at once (fnc_onSettingChanged).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Setting's name -> [value, priority] <HASHMAP>
 *
 * Example:
 * GVAR(originSource) = call aio_setup_fnc_targetValues;
 *
 * Public: No
 */

createHashMapFromArray [[RULES_SETTING, [RULES_SETTING] call FUNC(targetValue)]]
