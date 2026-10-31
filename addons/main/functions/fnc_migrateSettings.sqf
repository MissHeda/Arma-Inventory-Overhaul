#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Moves what the settings box of the test builds 0.4.27 to 0.5.42 still holds into the server settings of their
 * own. That box, aio_main_settings, held every server setting as one text (fnc_parseSettings reads it); it is no
 * CBA setting any more, but CBA still keeps what was saved for it where it was saved. Each value the text names is
 * set through CBA into the same source, at the priority the box had there - only where that source still has the
 * setting at its default, so a value set on its own since then wins:
 *   - the server's profile (on the server, single player included): set and stored, then the box is taken out of
 *     the profile - once, and for good;
 *   - the server's own cba_settings.sqf: set for this session, with a line in the RPT - the file is the admin's;
 *   - the mission's cba_settings.sqf, else what Eden saved in the mission (on every machine, each has the mission):
 *     set for this session - a mission file cannot be written;
 *   - in Eden, the scenario's attributes: set and stored there, then the box is taken out of them - kept once the
 *     scenario is saved -, and the scenario's cba_settings.sqf as above.
 * Called by CBA's event before it puts the settings into effect (XEH_preInit), so every script runs once with the
 * values in place, and in Eden as the setup wizard or CBA's menu opens. Run again, it finds nothing more to do.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * How many values were set <NUMBER>
 *
 * Example:
 * [] call aio_main_fnc_migrateSettings;
 *
 * Public: No
 */

if (isNil "cba_settings_fnc_set" || {isNil "cba_settings_fnc_get"}) exitWith {0};

private _box = QGVAR(settings);
private _count = 0;

// What the box held in one source, [text, priority], put into the settings of that source.
private _fnc_apply = {
    params ["_saved", "_source", "_store"];

    _saved params [["_text", ""], ["_priority", 0]];

    if !(_text isEqualType "") exitWith {};

    if (_priority isEqualType true) then {
        _priority = parseNumber _priority;
    };

    if !(_priority isEqualType 0) then {
        _priority = 0;
    };

    // HashMap forEach: the setting's name is _x, its value _y.
    {
        private _default = (GVAR(serverSettings) get _x) get "default";

        if (([_x, _source] call cba_settings_fnc_get) isNotEqualTo _default) then {continue};

        if ([_x, _y, _priority, _source, _store] call cba_settings_fnc_set) then {
            _count = _count + 1;
        };
    } forEach (([_text] call FUNC(parseSettings)) select 0);
};

// What a CBA hash holds for the box, nil for nothing.
private _fnc_fromHash = {
    params ["_hash"];

    if (isNil "_hash" || {!(_hash isEqualType [])} || {_hash isEqualTo []}) exitWith {nil};

    [_hash, _box] call CBA_fnc_hashGet
};

// The mission's cba_settings.sqf: read by CBA on every machine, in Eden too.
private _missionFile = missionNamespace getVariable ["cba_settings_missionConfig", objNull];
private _fromFile = nil;

if (!isNull _missionFile) then {
    _fromFile = _missionFile getVariable _box;
};

if (!isNil "_fromFile") then {
    [_fromFile, "mission", false] call _fnc_apply;
};

if (is3DEN) exitWith {
    private _saved = ["Scenario" get3DENMissionAttribute "cba_settings_hash"] call _fnc_fromHash;

    if (!isNil "_saved") then {
        [_saved, "mission", true] call _fnc_apply;

        // CBA wrote the attribute again for every value it stored: read once more, without the box.
        private _hash = "Scenario" get3DENMissionAttribute "cba_settings_hash";

        [_hash, _box] call CBA_fnc_hashRem;
        set3DENMissionAttributes [["Scenario", "cba_settings_hash", _hash]];
        findDisplay 313 setVariable ["cba_settings_hash", _hash];

        INFO_1("The scenario's settings box %1 was moved into the server settings of their own - save the scenario to keep it so.",_box);
    };

    _count
};

// What Eden saved in the mission, where its cba_settings.sqf does not set the box.
if (isNil "_fromFile") then {
    private _saved = [getMissionConfigValue ["cba_settings_hash", []]] call _fnc_fromHash;

    if (!isNil "_saved") then {
        [_saved, "mission", false] call _fnc_apply;
    };
};

if (isServer) then {
    private _userconfig = missionNamespace getVariable ["cba_settings_userconfig", objNull];
    private _fromUser = nil;

    if (!isNull _userconfig) then {
        _fromUser = _userconfig getVariable _box;
    };

    if (!isNil "_fromUser") then {
        [_fromUser, "server", false] call _fnc_apply;

        WARNING_1("The server's cba_settings.sqf still sets %1 - no setting any more. Its values count for now: replace the line with one line per setting (the setup wizard's Export).",_box);
    };

    // The server's profile - or, on a dedicated server whose settings are not kept, CBA's place for them instead.
    private _local = [profileNamespace, uiNamespace] select (isDedicated && {missionNamespace getVariable ["cba_settings_volatile", false]});
    private _saved = [_local getVariable "cba_settings_hash"] call _fnc_fromHash;

    if (!isNil "_saved") then {
        [_saved, "server", true] call _fnc_apply;

        private _hash = _local getVariable "cba_settings_hash";

        [_hash, _box] call CBA_fnc_hashRem;
        _local setVariable ["cba_settings_hash", _hash];
        saveProfileNamespace;

        INFO_1("The server's settings box %1 was moved into the server settings of their own.",_box);
    };
};

_count
