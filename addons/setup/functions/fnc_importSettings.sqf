#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Finds the server settings in a pasted text: the line einv_main_settings of a cba_settings.sqf or of CBA's Export
 * (read with CBA's own reader, cba_settings_fnc_parse). Its priority ("force") is not taken over: where and how
 * this machine saves is the wizard's own choice. A text that is no such file, or has no such line, has no
 * settings - a bare line of statements could as well be rules.
 *
 * The text is cleaned the way the setting's own box cleans it before it is read.
 *
 * Arguments:
 * 0: Pasted text <STRING>
 *
 * Return Value:
 * The server settings' text as the line holds it, "" when there is none <STRING>
 *
 * Example:
 * ["force einv_main_settings = ""einv1, gui_searchTime=0.8"";"] call einv_setup_fnc_importSettings;
 *
 * Public: No
 */

params [["_text", "", [""]]];

if ((toLower _text) find SETTINGS_SETTING < 0 || {isNil "cba_settings_fnc_parse"}) exitWith {""};

private _found = "";

{
    _x params ["_name", "_value"];

    if (toLower _name isEqualTo SETTINGS_SETTING && {_value isEqualType ""}) then {
        _found = _value;
    };
} forEach ([trim _text, false, "", false] call cba_settings_fnc_parse);

trim ([_found] call EFUNC(main,sanitizeSettings))
