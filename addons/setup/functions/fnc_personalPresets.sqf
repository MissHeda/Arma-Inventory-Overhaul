#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The player's own presets: setups kept under a name in their profile, for any mission and any server -
 * also for players who may not save the server's setup, so they can keep one they like or one they
 * worked out to hand to their admin. Kept as [name, rules text, date], newest saves replacing an older one
 * of the same name.
 *
 * Arguments:
 * 0: "list", "save" or "delete" <STRING> (default: "list")
 * 1: Name <STRING> (default: "")
 * 2: Rules text, to save <STRING> (default: "")
 *
 * Return Value:
 * The presets afterwards, [[name, rules text, date], ...] <ARRAY>
 *
 * Example:
 * ["save", "Milsim", einv_setup_draftText] call einv_setup_fnc_personalPresets;
 *
 * Public: No
 */

params [["_action", "list", [""]], ["_name", "", [""]], ["_text", "", [""]]];

private _presets = profileNamespace getVariable [QGVAR(presets), []];

// A profile carried over from elsewhere may hold anything under this name.
if !(_presets isEqualType []) then {
    _presets = [];
};

_presets = _presets select {_x isEqualTypeArray ["", "", ""]};
_name = trim _name;

if (_action isEqualTo "list" || {_name isEqualTo ""}) exitWith {_presets};

private _index = _presets findIf {(_x select 0) == _name};

switch (_action) do {
    case "save": {
        systemTime params ["_year", "_month", "_day"];

        private _date = format ["%1-%2-%3", _year, [str _month, "0" + str _month] select (_month < 10), [str _day, "0" + str _day] select (_day < 10)];
        private _entry = [_name, _text, _date];

        if (_index < 0) then {
            _presets pushBack _entry;
        } else {
            _presets set [_index, _entry];
        };
    };
    case "delete": {
        if (_index >= 0) then {
            _presets deleteAt _index;
        };
    };
};

profileNamespace setVariable [QGVAR(presets), _presets];
saveProfileNamespace;

_presets
