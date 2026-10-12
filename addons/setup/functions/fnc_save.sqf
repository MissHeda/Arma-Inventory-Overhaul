#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Saves the draft where the wizard may save it (fnc_canEdit):
 *   - direct mode: straight into CBA's setting (CBA_settings_fnc_set), stored in the server's profile or,
 *     in Eden, the scenario - CBA hands it to every machine, players joining later included, and each one
 *     takes it in at once (einv_items_fnc_loadRules). From a logged-in admin's machine CBA sends it to the
 *     server, and it comes back the same way.
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

if (count _text > TEXT_MAX) exitWith {
    [format [LLSTRING(Warning_TooLong), count _text], "loss"] call FUNC(setHint);
};

private _source = GVAR(target) getOrDefault ["source", ""];
private _priority = [1, 2] select (_source isEqualTo "server" && {GVAR(override)} && {GVAR(target) getOrDefault ["override", false]});

if (!_force && {(call FUNC(targetValue)) isNotEqualTo GVAR(originSource)}) exitWith {
    [
        _display, LLSTRING(Conflict_Text), LLSTRING(Conflict_Overwrite), {[true] call FUNC(save)}, [],
        LLSTRING(Cancel), [[LLSTRING(Conflict_Replay), {call FUNC(replay)}]]
    ] call FUNC(confirm);
};

if (GVAR(mode) isEqualTo "menu") exitWith {
    if (isNil "cba_settings_fnc_import") exitWith {
        [LLSTRING(Save_Failed), "loss"] call FUNC(setHint);
    };

    // Exactly what a line of a cba_settings.sqf says - CBA's own Import box takes the same.
    private _line = format ["%1%2 = %3;", ["force ", "force force "] select (_priority >= 2), RULES_SETTING, str _text];

    [_line, _source] call cba_settings_fnc_import;

    GVAR(clean) = _text;
    GVAR(cleanOverride) = GVAR(override);

    _display closeDisplay 1;
};

private _done = [RULES_SETTING, _text, _priority, _source, true] call CBA_settings_fnc_set;

if (!_done) exitWith {
    // CBA says no when nothing would change, too.
    if ((call FUNC(targetValue)) isEqualTo [_text, _priority]) then {
        GVAR(clean) = _text;
        GVAR(sourceEmpty) = false;
        GVAR(cleanOverride) = GVAR(override);
        [GVAR(step)] call FUNC(showStep);
        [LLSTRING(Save_Unchanged), "text2"] call FUNC(setHint);
    } else {
        [LLSTRING(Save_Failed), "loss"] call FUNC(setHint);
    };
};

// Stored there now - from an admin's machine it comes back from the server a moment later, so the source
// is not asked again (fnc_sourceEmpty).
GVAR(clean) = _text;
GVAR(sourceEmpty) = false;
GVAR(cleanOverride) = GVAR(override);
GVAR(origin) = _text;
GVAR(originSource) = [_text, _priority];
GVAR(banner) = false;

[GVAR(step)] call FUNC(showStep);

// Saved, but a mission that sets its own setup still wins over a server value of priority 1.
private _message = switch (true) do {
    case (_source isEqualTo "mission"): {LLSTRING(Save_SavedMission)};
    case ((GVAR(target) getOrDefault ["missionWins", false]) && {_priority < 2}): {LLSTRING(Save_SavedMissionWins)};
    default {LLSTRING(Save_Saved)};
};

[_message, ["gain", "accent"] select (_message isEqualTo LLSTRING(Save_SavedMissionWins))] call FUNC(setHint);
