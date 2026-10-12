#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The first click of a two-click confirmation: with the setting on, the action it guards (throwing away
 * something this arsenal does not have, overwriting or deleting a loadout) only goes ahead on a second
 * click within ARM_TIME seconds, and the hint says so.
 *
 * Arguments:
 * 0: Key of the action <STRING>
 * 1: What the hint says <STRING>
 *
 * Return Value:
 * This is the second click - go ahead <BOOL>
 *
 * Example:
 * ["give|arifle_MX_F", "Again to throw it away"] call einv_arsenal_fnc_arm;
 *
 * Public: No
 */

params [["_key", "", [""]], ["_text", "", [""]]];

// The player turned the question off: every action goes ahead at once.
if !(missionNamespace getVariable [QGVAR(confirmUnique), true]) exitWith {true};

private _now = diag_tickTime;

GVAR(armed) params [["_armedKey", "", [""]], ["_until", -1, [0]]];

// The same action asked for again in time: this is the second click.
if (_armedKey isEqualTo _key && {_now <= _until}) exitWith {
    GVAR(armed) = ["", -1];
    true
};

GVAR(armed) = [_key, _now + ARM_TIME];

if (_text isNotEqualTo "") then {
    [_text, "loss"] call FUNC(message);
};

false
