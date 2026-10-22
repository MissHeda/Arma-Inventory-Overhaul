#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether this machine may save the setup, and where to: the CBA source the wizard writes to.
 *
 * What the wizard edits - the rules and the server settings - is the same for everyone (global), so a client's
 * own value never counts - only the server's and the mission's do:
 *   - direct mode: in Eden the mission (it goes into the scenario), everywhere else the server - as the
 *     server itself, single player included, or as a logged-in admin or whitelisted player (CBA's
 *     cba_settings_whitelist); everyone else may only look and copy.
 *   - menu mode: the source picked at the top of CBA's menu - its Client tab only to look at.
 * A value set in a cba_settings.sqf (the server's or the mission's) locks it: CBA would still take a new one for
 * this session, but lose it on the next restart. For the rules that locks the whole wizard; a server setting set
 * there is only locked itself - its control is greyed and Save leaves it out (lockedSettings).
 *
 * Forcing over the mission's own setup (priority 2) is offered for the server in multiplayer only. In
 * single player "server" is the player's own profile: forced there, it would stay so for every mission
 * after, the multiplayer ones they host included.
 *
 * Arguments:
 * 0: Mode, "menu" or "direct" <STRING> (default: "direct")
 *
 * Return Value:
 * HashMap <HASHMAP>
 *   canSave        - may save <BOOL>
 *   source         - "server", "mission", or "" when it may not <STRING>
 *   override       - may force over the mission's setup (priority 2) <BOOL>
 *   locked         - the rules are set in a cba_settings.sqf <BOOL>
 *   lockedSettings - the server settings set in that source's cba_settings.sqf, by name <ARRAY of STRING>
 *   reason         - why it may not save, "" when it may <STRING>
 *   priority       - the rules' priority there now, pending changes in CBA's menu included <NUMBER>
 *   missionWins    - the mission sets its own rules or server settings, which win over a server value of
 *                    priority 1 <BOOL>
 *
 * Example:
 * (["direct"] call einv_setup_fnc_canEdit) get "canSave";
 *
 * Public: Yes
 */

params [["_mode", "direct", [""]]];

private _setting = RULES_SETTING;
private _settings = missionNamespace getVariable [QEGVAR(main,serverOrder), []];
private _result = createHashMapFromArray [
    ["canSave", false],
    ["source", ""],
    ["override", false],
    ["locked", false],
    ["lockedSettings", []],
    ["reason", ""],
    ["priority", 0],
    ["missionWins", false]
];

// CBA's settings are required, but the functions used here are CBA's internals: should they ever be gone,
// the wizard can still show and copy the setup.
if (isNil "cba_settings_fnc_set" || {isNil "cba_settings_fnc_get"} || {isNil "cba_settings_fnc_priority"}) exitWith {
    _result set ["reason", LLSTRING(Reason_NoCba)];
    _result
};

private _server = missionNamespace getVariable ["cba_settings_server", objNull];
private _canServer = (isServer || {!isNil "cba_settings_fnc_whitelisted" && {call cba_settings_fnc_whitelisted}}) && {!isNull _server};
private _source = if (_mode isEqualTo "menu") then {
    uiNamespace getVariable ["cba_settings_source", "client"]
} else {
    ["server", "mission"] select is3DEN
};

// What the source's cba_settings.sqf sets: the server's file (its names, shared with every machine), or the mission's.
private _config = missionNamespace getVariable [["cba_settings_serverConfig", "cba_settings_missionConfig"] select (_source isEqualTo "mission"), objNull];
private _fnc_inFile = {
    !isNull _config && {!isNil {_config getVariable _this}}
};

switch (_source) do {
    case "server": {
        if (!_canServer) then {
            _result set ["reason", LLSTRING(Reason_NoAdmin)];
        } else {
            if (_setting call _fnc_inFile) then {
                _result set ["locked", true];
                _result set ["reason", LLSTRING(Reason_LockedServer)];
            } else {
                _result set ["canSave", true];
                _result set ["source", "server"];
                _result set ["override", isMultiplayer];
            };
        };
    };
    case "mission": {
        if (!is3DEN) then {
            _result set ["reason", LLSTRING(Reason_NoMission)];
        } else {
            if (_setting call _fnc_inFile) then {
                _result set ["locked", true];
                _result set ["reason", LLSTRING(Reason_LockedMission)];
            } else {
                _result set ["canSave", true];
                _result set ["source", "mission"];
            };
        };
    };
    default {
        _result set ["reason", LLSTRING(Reason_Client)];
    };
};

private _target = _result get "source";

if (_target isNotEqualTo "") then {
    _result set ["lockedSettings", _settings select {_x call _fnc_inFile}];

    private _priority = [_setting, _target] call cba_settings_fnc_priority;

    // In CBA's menu a change not yet confirmed there counts: it is what the menu shows.
    if (_mode isEqualTo "menu") then {
        private _temp = uiNamespace getVariable [format ["cba_settings_%1Temp", _target], controlNull];
        _priority = (_temp getVariable [_setting, []]) param [1, _priority];
    };

    if (_priority isEqualType true) then {
        _priority = parseNumber _priority;
    };

    _result set ["priority", _priority];
};

// A server value of priority 1 ties with a mission's forced one, and CBA lets the mission win a tie.
private _mission = missionNamespace getVariable ["cba_settings_mission", objNull];
private _missionSets = (([_setting] + _settings) findIf {!isNil {_mission getVariable _x} && {([_x, "mission"] call cba_settings_fnc_priority) >= 1}}) >= 0;

_result set ["missionWins", _target isEqualTo "server" && {_missionSets}];

_result
