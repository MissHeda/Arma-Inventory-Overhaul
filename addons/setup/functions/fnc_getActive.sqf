#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The rules text the wizard starts from - what is in use where it saves:
 *   - menu mode: what CBA's menu shows for the source picked there, a change not yet confirmed in the menu
 *     first (CBA keeps those in its temporary values until OK).
 *   - direct mode: the value of the source the wizard saves to, when that source has one of its own; the
 *     value in effect otherwise - what a player sees in the game, and what a mission maker starts from in
 *     Eden while the scenario has none yet.
 * The server settings are fnc_activeSettings'.
 *
 * Arguments:
 * 0: The setting <STRING> (default: the rules, RULES_SETTING)
 *
 * Return Value:
 * Text <STRING>
 *
 * Example:
 * call aio_setup_fnc_getActive;
 *
 * Public: No
 */

params [["_setting", RULES_SETTING, [""]]];

private _default = RULES_DEFAULT;

if (isNil "cba_settings_fnc_get") exitWith {
    private _value = missionNamespace getVariable [_setting, _default];

    [_default, _value] select (_value isEqualType "")
};

private _value = if ((missionNamespace getVariable [QGVAR(mode), "direct"]) isEqualTo "menu") then {
    private _source = uiNamespace getVariable ["cba_settings_source", "server"];
    private _temp = uiNamespace getVariable [format ["cba_settings_%1Temp", _source], controlNull];

    (_temp getVariable [_setting, []]) param [0, [_setting, _source] call cba_settings_fnc_get]
} else {
    private _source = (missionNamespace getVariable [QGVAR(target), createHashMap]) getOrDefault ["source", ""];
    private _namespace = missionNamespace getVariable [format ["cba_settings_%1", _source], objNull];

    if (_source isNotEqualTo "" && {!isNil {_namespace getVariable _setting}}) then {
        [_setting, _source] call cba_settings_fnc_get
    } else {
        [_setting] call cba_settings_fnc_get
    }
};

if (isNil "_value" || {!(_value isEqualType "")}) then {
    _value = _default;
};

_value
