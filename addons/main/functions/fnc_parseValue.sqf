#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Reads one value of the text of the server settings (fnc_parseSettings) the way its setting's type wants
 * it, and holds it to what CBA would take for such a setting: a switch is 1, 0, on, off, true or false; a
 * number is cut to the slider's range and rounded to its decimals; a list takes the value of one of its
 * choices; a text is read as fnc_decodeText does.
 *
 * Arguments:
 * 0: The setting's definition (fnc_addSetting) <HASHMAP>
 * 1: The value as it is written <STRING>
 *
 * Return Value:
 * The value as the setting's variable holds it - nil when it cannot be read as one <ANY>
 *
 * Example:
 * [aio_main_serverSettings get "aio_gui_searchTime", "0.6"] call aio_main_fnc_parseValue;
 *
 * Public: No
 */

params [["_entry", createHashMap, [createHashMap]], ["_text", "", [""]]];

private _result = nil;

switch (_entry getOrDefault ["type", ""]) do {
    case "CHECKBOX": {
        private _lower = toLowerANSI _text;

        if (_lower in ["1", "true", "on", "yes"]) then {
            _result = true;
        };

        if (_lower in ["0", "false", "off", "no"]) then {
            _result = false;
        };
    };
    case "SLIDER": {
        if (_text regexMatch "^-?([0-9]+([.][0-9]*)?|[.][0-9]+)$") then {
            private _factor = 10 ^ ((_entry getOrDefault ["decimals", 0]) max 0);
            private _value = (((parseNumber _text) max (_entry get "min")) min (_entry get "max"));

            _result = (round (_value * _factor)) / _factor;
        };
    };
    case "LIST": {
        private _lower = toLowerANSI _text;
        private _index = (_entry get "values") findIf {
            private _shown = if (_x isEqualType "") then {toLowerANSI _x} else {str _x};

            _shown isEqualTo _lower
        };

        if (_index >= 0) then {
            _result = (_entry get "values") select _index;
        };
    };
    default {
        _result = [_text] call FUNC(decodeText);
    };
};

if (isNil "_result") exitWith {nil};

_result
