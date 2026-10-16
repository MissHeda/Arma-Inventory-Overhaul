#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Saves the draft where the wizard may save it (fnc_canEdit): the rules and the server settings, two CBA
 * settings, each written when it changed (or when the source it goes to holds none of its own yet):
 *   - direct mode: straight into CBA's setting (CBA_settings_fnc_set), stored in the server's profile or,
 *     in Eden, the scenario - CBA hands it to every machine, players joining later included, and each one
 *     takes it in at once (einv_items_fnc_loadRules, einv_main_fnc_applySettings). From a logged-in admin's
 *     machine CBA sends it to the server, and it comes back the same way.
 *   - menu mode: into CBA's menu as a change still to be confirmed (cba_settings_fnc_import, the way CBA's
 *     own Import box does it), and the wizard closes: the setting's row turns yellow, CBA's OK keeps it,
 *     Cancel throws it away - with the player's other changes in that menu, which the wizard never
 *     confirms behind their back.
 * The mission's source is always forced (priority 1) - unforced, any server value would win over it. The
 * server's is forced over the mission (priority 2) when the switch says so.
 *
 * Should the source hold something else than when the wizard opened, someone else saved in between: the
 * player picks - their edits on top of the new setup (fnc_replay), overwrite, or cancel.
 *
 * Arguments:
 * 0: Overwrite whatever someone else saved meanwhile <BOOL> (default: false)
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call einv_setup_fnc_save;
 *
 * Public: No
 */

params [["_force", false, [false]]];

private _display = uiNamespace getVariable [QGVAR(display), displayNull];

if (isNull _display) exitWith {};

if (GVAR(readOnly)) exitWith {
    [format [LLSTRING(Save_ReadOnly), GVAR(target) getOrDefault ["reason", ""]], "loss"] call FUNC(setHint);
};

private _text = GVAR(draftText);
private _settings = GVAR(draftSettingsText);

// The server settings' text too: a long text box value is written five characters for each special one.
if (count _text > TEXT_MAX || {count _settings > TEXT_MAX}) exitWith {
    [format [LLSTRING(Warning_TooLong), (count _text) max (count _settings)], "loss"] call FUNC(setHint);
};

private _source = GVAR(target) getOrDefault ["source", ""];
private _priority = [1, 2] select (_source isEqualTo "server" && {GVAR(override)} && {GVAR(target) getOrDefault ["override", false]});

// Someone else saved while the wizard was open, in either setting.
private _conflict = ([RULES_SETTING, SETTINGS_SETTING] findIf {
    ([_x] call FUNC(targetValue)) isNotEqualTo (GVAR(originSource) getOrDefault [_x, []])
}) >= 0;

if (!_force && {_conflict}) exitWith {
    [
        _display, LLSTRING(Conflict_Text), LLSTRING(Conflict_Overwrite), {[true] call FUNC(save)}, [],
        LLSTRING(Cancel), [[LLSTRING(Conflict_Replay), {call FUNC(replay)}]]
    ] call FUNC(confirm);
};

// What goes where: each setting that changed - or that its source lacks, or whose force switch was turned,
// which changes how firmly it is stored. With nothing of that, the rules are written again all the same.
private _overrideChanged = GVAR(override) isNotEqualTo GVAR(cleanOverride);
private _jobs = [];

if (_text isNotEqualTo GVAR(clean) || {_overrideChanged} || {[RULES_SETTING] call FUNC(sourceEmpty)}) then {
    _jobs pushBack [RULES_SETTING, _text];
};

if (_settings isNotEqualTo GVAR(cleanSettings) || {_overrideChanged} || {[SETTINGS_SETTING] call FUNC(sourceEmpty)}) then {
    _jobs pushBack [SETTINGS_SETTING, _settings];
};

if (_jobs isEqualTo []) then {
    _jobs pushBack [RULES_SETTING, _text];
};

if (GVAR(mode) isEqualTo "menu") exitWith {
    if (isNil "cba_settings_fnc_import") exitWith {
        [LLSTRING(Save_Failed), "loss"] call FUNC(setHint);
    };

    // Exactly what a line of a cba_settings.sqf says - CBA's own Import box takes the same.
    {
        _x params ["_setting", "_value"];

        private _line = format ["%1%2 = %3;", ["force ", "force force "] select (_priority >= 2), _setting, str _value];

        [_line, _source] call cba_settings_fnc_import;
    } forEach _jobs;

    GVAR(clean) = _text;
    GVAR(cleanSettings) = _settings;
    GVAR(cleanOverride) = GVAR(override);

    _display closeDisplay 1;
};

// Into CBA's setting. CBA says no when nothing would change, too: then the source holds that value already,
// or it really failed.
private _written = 0;
private _failed = false;

{
    _x params ["_setting", "_value"];

    private _done = [_setting, _value, _priority, _source, true] call CBA_settings_fnc_set;

    if (_done) then {
        _written = _written + 1;
        GVAR(originSource) set [_setting, [_value, _priority]];
    } else {
        if (([_setting] call FUNC(targetValue)) isEqualTo [_value, _priority]) then {
            GVAR(originSource) set [_setting, [_value, _priority]];
        } else {
            _failed = true;
        };
    };
} forEach _jobs;

if (_failed) exitWith {
    [LLSTRING(Save_Failed), "loss"] call FUNC(setHint);
};

// Stored there now - from an admin's machine it comes back from the server a moment later, so the source
// is not asked again (fnc_sourceEmpty).
GVAR(clean) = _text;
GVAR(cleanSettings) = _settings;
GVAR(sourceEmpty) = false;
GVAR(cleanOverride) = GVAR(override);
GVAR(origin) = _text;
GVAR(originSettings) = _settings;
GVAR(banner) = false;

[GVAR(step)] call FUNC(showStep);

if (_written == 0) exitWith {
    [LLSTRING(Save_Unchanged), "text2"] call FUNC(setHint);
};

// Saved, but a mission that sets its own setup still wins over a server value of priority 1.
private _message = switch (true) do {
    case (_source isEqualTo "mission"): {LLSTRING(Save_SavedMission)};
    case ((GVAR(target) getOrDefault ["missionWins", false]) && {_priority < 2}): {LLSTRING(Save_SavedMissionWins)};
    default {LLSTRING(Save_Saved)};
};

[_message, ["gain", "accent"] select (_message isEqualTo LLSTRING(Save_SavedMissionWins))] call FUNC(setHint);
