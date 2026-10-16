#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether the source the wizard saves to holds no setup of its own for a setting, while the setup last loaded or
 * saved (GVAR(clean), GVAR(cleanSettings)) is not the default. In direct mode the wizard then starts from the
 * setup in effect (fnc_getActive) - in Eden the mission maker's own profile, for a server admin the mission's -,
 * so nothing is changed, yet the source still lacks it: Save stays possible, to put it there. Kept in
 * GVAR(sourceEmpty) whenever GVAR(clean) is set (either of the two settings), and false once saved.
 *
 * Never in menu mode, where the wizard starts from what CBA's menu shows for that source, and never for
 * the default: saved where nothing is set, it would only be forced.
 *
 * Arguments:
 * 0: The setting, RULES_SETTING or SETTINGS_SETTING; none for either of them <STRING> (default: either)
 *
 * Return Value:
 * The source holds none of its own <BOOL>
 *
 * Example:
 * GVAR(sourceEmpty) = call einv_setup_fnc_sourceEmpty;
 *
 * Public: No
 */

params [["_setting", "", [""]]];

if (_setting isEqualTo "") exitWith {
    ([RULES_SETTING] call FUNC(sourceEmpty)) || {[SETTINGS_SETTING] call FUNC(sourceEmpty)}
};

if (GVAR(mode) isEqualTo "menu") exitWith {false};

private _source = GVAR(target) getOrDefault ["source", ""];

if (_source isEqualTo "") exitWith {false};

private _namespace = missionNamespace getVariable [format ["cba_settings_%1", _source], objNull];

if (!isNil {_namespace getVariable _setting}) exitWith {false};

if (_setting isEqualTo SETTINGS_SETTING) exitWith {GVAR(cleanSettings) isNotEqualTo ""};

GVAR(clean) isNotEqualTo ([[RULES_DEFAULT] call EFUNC(items,parseRules)] call EFUNC(items,writeRules))
