#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether the source the wizard saves to holds no rules of its own, while the rules last loaded or saved
 * (GVAR(clean)) are not the default. In direct mode the wizard then starts from the rules in effect
 * (fnc_getActive) - in Eden the mission maker's own profile, for a server admin the mission's -, so nothing is
 * changed, yet the source still lacks them: Save stays possible, to put them there. Kept in GVAR(sourceEmpty)
 * whenever GVAR(clean) is set, and false once saved.
 *
 * Never in menu mode, where the wizard starts from what CBA's menu shows for that source, and never for
 * the default: saved where nothing is set, it would only be forced. Never for the server settings either: Save
 * writes each one that was changed, and only those - a value the mission sets is not copied into the server's
 * profile behind the admin's back.
 *
 * Arguments:
 * 0: The setting <STRING> (default: the rules, RULES_SETTING)
 *
 * Return Value:
 * The source holds none of its own <BOOL>
 *
 * Example:
 * GVAR(sourceEmpty) = call einv_setup_fnc_sourceEmpty;
 *
 * Public: No
 */

params [["_setting", RULES_SETTING, [""]]];

if (_setting isNotEqualTo RULES_SETTING) exitWith {false};

if (GVAR(mode) isEqualTo "menu") exitWith {false};

private _source = GVAR(target) getOrDefault ["source", ""];

if (_source isEqualTo "") exitWith {false};

private _namespace = missionNamespace getVariable [format ["cba_settings_%1", _source], objNull];

if (!isNil {_namespace getVariable _setting}) exitWith {false};

GVAR(clean) isNotEqualTo ([[RULES_DEFAULT] call EFUNC(items,parseRules)] call EFUNC(items,writeRules))
