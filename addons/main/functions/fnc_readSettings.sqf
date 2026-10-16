#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What the text of the server settings (einv_main_settings) says for the registered settings, as their
 * variables hold it (fnc_parseSettings) - and, while the text is empty, what a mission set up before the
 * settings moved says for them under their own names: the lines of its cba_settings.sqf, which CBA keeps in
 * cba_settings_missionConfig, else what was saved in Eden's mission attributes (cba_settings_hash) - the
 * order CBA itself reads a mission's values in. Those names are no rows of CBA's menu any more, so CBA
 * leaves them where it read them. Once the text holds anything, only it counts. What the server's own file
 * or profile said for them is not read: a client does not have it.
 *
 * Arguments:
 * 0: The text <STRING>
 * 1: Only these settings, by name - [] for every one registered <ARRAY> (default: [])
 *
 * Return Value:
 * The settings it names, setting's name -> value <HASHMAP>
 *
 * Example:
 * [einv_main_settings] call einv_main_fnc_readSettings;
 *
 * Public: No
 */

params [["_text", "", [""]], ["_only", [], [[]]]];

private _values = ([_text] call FUNC(parseSettings)) select 0;

if (_text isNotEqualTo "") exitWith {_values};

private _names = [_only, GVAR(serverOrder)] select (_only isEqualTo []);
private _file = missionNamespace getVariable ["cba_settings_missionConfig", objNull];
private _attributes = getMissionConfigValue ["cba_settings_hash", []];

if !(_attributes isEqualType []) then {
    _attributes = [];
};

{
    private _entry = GVAR(serverSettings) get _x;

    if (isNil "_entry") then {continue};

    // [value, priority], from the file first and the attributes after, as CBA reads them.
    private _old = nil;

    if (!isNull _file) then {
        _old = _file getVariable _x;
    };

    if (isNil "_old" && {_attributes isNotEqualTo []}) then {
        _old = [_attributes, toLower _x] call CBA_fnc_hashGet;
    };

    if (isNil "_old" || {!(_old isEqualType [])}) then {continue};

    private _raw = _old param [0];

    if (isNil "_raw") then {continue};

    // Written as the text would hold it, then read as the text is - the same checks, the same ranges.
    private _written = switch (true) do {
        case (_raw isEqualType true): {["0", "1"] select _raw};
        case (_raw isEqualType 0): {str _raw};
        case (_raw isEqualType ""): {
            [_raw, [_raw] call FUNC(encodeText)] select ((_entry get "type") isEqualTo "EDITBOX")
        };
        default {nil};
    };

    if (isNil "_written") then {continue};

    private _value = [_entry, _written] call FUNC(parseValue);

    if (!isNil "_value") then {
        _values set [_x, _value];
    };
} forEach _names;

_values
