#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What the source the wizard saves to holds right now for one of its settings: its own value and priority -
 * not the value in effect, which may come from another source. Kept when the wizard opens
 * (GVAR(originSource), fnc_targetValues); when it differs at Save, someone else saved in between (fnc_save).
 * In Eden the value in effect is the mission maker's own profile, and a server admin's could be the
 * mission's: neither says whether the source itself changed.
 *
 * In menu mode the source picked in CBA's menu, a change not yet confirmed there first. Where the wizard
 * may not save, the text in use.
 *
 * Arguments:
 * 0: The setting <STRING> (default: the rules, RULES_SETTING)
 *
 * Return Value:
 * [value, priority] <ARRAY>
 *
 * Example:
 * call einv_setup_fnc_targetValue;
 *
 * Public: No
 */

params [["_setting", RULES_SETTING, [""]]];

if (isNil "cba_settings_fnc_get" || {isNil "cba_settings_fnc_priority"}) exitWith {[[_setting] call FUNC(getActive), 0]};

if (GVAR(mode) isEqualTo "menu") exitWith {
    private _source = uiNamespace getVariable ["cba_settings_source", "client"];
    private _pending = (uiNamespace getVariable [format ["cba_settings_%1Temp", _source], controlNull]) getVariable [_setting, []];

    [
        _pending param [0, [_setting, _source] call cba_settings_fnc_get],
        _pending param [1, [_setting, _source] call cba_settings_fnc_priority]
    ]
};

private _source = GVAR(target) getOrDefault ["source", ""];

if (_source isEqualTo "") exitWith {[[_setting] call FUNC(getActive), 0]};

[[_setting, _source] call cba_settings_fnc_get, [_setting, _source] call cba_settings_fnc_priority]
