#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Writes server settings as the text einv_main_settings holds (fnc_parseSettings reads it): the header einv1,
 * then every setting that is not at its default as key=value, in the order they were registered, one canonical
 * way - so two setups that mean the same compare as texts. Nothing at its default is written, and no setting
 * at all gives an empty text: the CBA setting stays what it is until someone changes something.
 *
 * Arguments:
 * 0: The settings, setting's name -> value <HASHMAP>
 *
 * Return Value:
 * The text <STRING>
 *
 * Example:
 * [createHashMapFromArray [["einv_gui_searchTime", 0.6]]] call einv_main_fnc_writeSettings;
 *
 * Public: Yes
 */

params [["_values", createHashMap, [createHashMap]]];

private _statements = [];

{
    private _entry = GVAR(serverSettings) get _x;
    private _value = _values get _x;

    if (isNil "_value") then {continue};

    private _default = _entry get "default";
    private _same = if (_value isEqualType 0 && {_default isEqualType 0}) then {abs (_value - _default) < 0.000001} else {_value isEqualTo _default};

    if (_same) then {continue};

    private _written = switch (_entry get "type") do {
        case "CHECKBOX": {["0", "1"] select _value};
        case "SLIDER": {str _value};
        case "LIST": {if (_value isEqualType "") then {_value} else {str _value}};
        default {[_value] call FUNC(encodeText)};
    };

    _statements pushBack format ["%1=%2", _entry get "key", _written];
} forEach (GVAR(serverOrder) select {_x in _values});

if (_statements isEqualTo []) exitWith {""};

(["einv1"] + _statements) joinString ", "
