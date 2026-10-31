#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Saves the draft where the wizard may save it (fnc_canEdit), each CBA setting on its own: the rules when they
 * changed (or when the source holds none of its own yet), and every server setting whose draft differs from the
 * value in effect - only those, so a value the mission sets is never copied into the server's profile:
 *   - direct mode: straight into CBA's setting (CBA_settings_fnc_set), into the same place CBA's own Server tab
 *     (or in Eden its Mission tab) writes to - stored in the server's profile or, in Eden, the scenario. CBA hands
 *     it to every machine, players joining later included, runs the setting's script there and raises its
 *     setting-changed event, and its menu shows the new value. From a logged-in admin's machine CBA sends it to
 *     the server, and it comes back the same way. In single player "server" is the player's own profile, as on
 *     CBA's Server tab.
 *   - menu mode: into CBA's menu as a change still to be confirmed - what CBA's own Import box does with a line
 *     (cba_settings_fnc_import): the value and priority into the menu's temporary values for its source, then
 *     its rows refreshed -, and the wizard closes: the rows turn yellow, CBA's OK keeps them, Cancel throws them
 *     away - with the player's other changes in that menu, which the wizard never confirms behind their back.
 * The mission's source is always forced (priority 1) - unforced, any server value would win over it. The
 * server's is forced over the mission (priority 2) when the switch says so; turning the switch writes again what
 * the source holds of its own, at the new priority. A server setting set in the source's cba_settings.sqf is left
 * out (canEdit's lockedSettings): its control is greyed.
 *
 * Should the source hold other rules than when the wizard opened, someone else saved in between: the player
 * picks - their edits on top of the new rules (fnc_replay), overwrite, or cancel. The server settings need no
 * such question: each one changed elsewhere was taken in at once (fnc_onSettingChanged).
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

if (count _text > TEXT_MAX) exitWith {
    [format [LLSTRING(Warning_TooLong), count _text], "loss"] call FUNC(setHint);
};

private _source = GVAR(target) getOrDefault ["source", ""];
private _priority = [1, 2] select (_source isEqualTo "server" && {GVAR(override)} && {GVAR(target) getOrDefault ["override", false]});

// Someone else saved the rules while the wizard was open.
private _conflict = ([RULES_SETTING] call FUNC(targetValue)) isNotEqualTo (GVAR(originSource) getOrDefault [RULES_SETTING, []]);

if (!_force && {_conflict}) exitWith {
    [
        _display, LLSTRING(Conflict_Text), LLSTRING(Conflict_Overwrite), {[true] call FUNC(save)}, [],
        LLSTRING(Cancel), [[LLSTRING(Conflict_Replay), {call FUNC(replay)}]]
    ] call FUNC(confirm);
};

// What goes where. The rules: when they changed, when the source lacks them, or when the force switch was turned,
// which changes how firmly they are stored.
private _overrideChanged = GVAR(override) isNotEqualTo GVAR(cleanOverride);
private _jobs = [];

if (_text isNotEqualTo GVAR(clean) || {_overrideChanged} || {[RULES_SETTING] call FUNC(sourceEmpty)}) then {
    _jobs pushBack [RULES_SETTING, _text];
};

// The server settings: each whose draft differs from the value in effect, and with the force switch turned each
// the source holds of its own as well.
private _registry = missionNamespace getVariable [QEGVAR(main,serverSettings), createHashMap];
private _locked = GVAR(target) getOrDefault ["lockedSettings", []];
private _clean = ([GVAR(cleanSettings)] call EFUNC(main,parseSettings)) select 0;
private _namespace = missionNamespace getVariable [format ["cba_settings_%1", _source], objNull];

{
    private _default = (_registry get _x) get "default";
    private _value = GVAR(draftSettings) getOrDefault [_x, _default];
    private _changed = _value isNotEqualTo (_clean getOrDefault [_x, _default]);
    private _held = _overrideChanged && {!isNull _namespace} && {!isNil {_namespace getVariable _x}};

    if ((_changed || {_held}) && {!(_x in _locked)}) then {
        _jobs pushBack [_x, _value];
    };
} forEach (missionNamespace getVariable [QEGVAR(main,serverOrder), []]);

// With nothing of that, the rules are written again all the same.
if (_jobs isEqualTo []) then {
    _jobs pushBack [RULES_SETTING, _text];
};

// What is in effect once they are written: the old values with the new ones on top. A locked setting the draft
// changed anyway - an import, Reset to default - goes back to its value.
private _fnc_settled = {
    {
        _x params ["_setting", "_value"];

        if (_setting isNotEqualTo RULES_SETTING) then {
            _clean set [_setting, _value];
        };
    } forEach _jobs;

    GVAR(cleanSettings) = [_clean] call EFUNC(main,writeSettings);

    [GVAR(cleanSettings)] call FUNC(setSettingsDraft);
};

if (GVAR(mode) isEqualTo "menu") exitWith {
    private _temp = uiNamespace getVariable [format ["cba_settings_%1Temp", _source], controlNull];

    if (isNull _temp || {isNil "cba_settings_fnc_gui_refresh"}) exitWith {
        [LLSTRING(Save_Failed), "loss"] call FUNC(setHint);
    };

    // What a line of a cba_settings.sqf in CBA's Import box comes to, without the line: a free text may hold a ";",
    // at which a line would be cut.
    {
        _x params ["_setting", "_value"];

        _temp setVariable [_setting, [_value, _priority]];
    } forEach _jobs;

    call cba_settings_fnc_gui_refresh;

    GVAR(clean) = _text;
    GVAR(cleanOverride) = GVAR(override);

    call _fnc_settled;

    _display closeDisplay 1;
};

// Into CBA's settings. CBA says no when nothing would change, too: then the source holds that value already,
// or it really failed.
private _written = 0;
private _failed = false;

{
    _x params ["_setting", "_value"];

    private _done = [_setting, _value, _priority, _source, true] call CBA_settings_fnc_set;
    private _there = _done || {[[_setting, _source] call cba_settings_fnc_get, [_setting, _source] call cba_settings_fnc_priority] isEqualTo [_value, _priority]};

    if (_done) then {
        _written = _written + 1;
    };

    if (_there) then {
        if (_setting isEqualTo RULES_SETTING) then {
            GVAR(originSource) set [_setting, [_value, _priority]];
        };
    } else {
        _failed = true;
    };
} forEach _jobs;

if (_failed) exitWith {
    [LLSTRING(Save_Failed), "loss"] call FUNC(setHint);
};

// Stored there now - from an admin's machine it comes back from the server a moment later, so the source
// is not asked again (fnc_sourceEmpty).
GVAR(clean) = _text;
GVAR(sourceEmpty) = false;
GVAR(cleanOverride) = GVAR(override);
GVAR(origin) = _text;
GVAR(banner) = false;

call _fnc_settled;

[GVAR(step)] call FUNC(showStep);

if (_written == 0) exitWith {
    [LLSTRING(Save_Unchanged), "text2"] call FUNC(setHint);
};

// Saved, but a mission that sets its own still wins over a server value of priority 1.
private _message = switch (true) do {
    case (_source isEqualTo "mission"): {LLSTRING(Save_SavedMission)};
    case ((GVAR(target) getOrDefault ["missionWins", false]) && {_priority < 2}): {LLSTRING(Save_SavedMissionWins)};
    default {LLSTRING(Save_Saved)};
};

[_message, ["gain", "accent"] select (_message isEqualTo LLSTRING(Save_SavedMissionWins))] call FUNC(setHint);
