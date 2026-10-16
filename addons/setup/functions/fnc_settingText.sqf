#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * A value of a server setting as players read it: on or off for a switch, the number, the label of the choice a
 * list has, the text itself - or "empty" for none. For the General step's change list.
 *
 * Arguments:
 * 0: The setting's name <STRING>
 * 1: Its value; nothing for the default <ANY>
 *
 * Return Value:
 * The value in words <STRING>
 *
 * Example:
 * ["einv_gui_searchTime", 0.8] call einv_setup_fnc_settingText;
 *
 * Public: No
 */

params [["_name", "", [""]], "_value"];

private _entry = (missionNamespace getVariable [QEGVAR(main,serverSettings), createHashMap]) getOrDefault [_name, createHashMap];

if (isNil "_value") then {
    _value = _entry getOrDefault ["default", ""];
};

switch (_entry getOrDefault ["type", ""]) do {
    case "CHECKBOX": {[LLSTRING(Value_Off), LLSTRING(Value_On)] select (_value isEqualTo true)};
    case "SLIDER": {str _value};
    case "LIST": {
        private _index = (_entry getOrDefault ["values", []]) find _value;

        if (_index < 0) then {str _value} else {(_entry get "labels") param [_index, str _value]}
    };
    default {[_value, LLSTRING(Value_Empty)] select (_value isEqualTo "")};
}
