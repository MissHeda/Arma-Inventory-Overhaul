#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Registers a setting that is the same for everyone - what a server or a mission decides, not what a player
 * sets for themselves. It takes the place of CBA_fnc_addSetting with its isGlobal at 1, and is called with
 * the same arguments but the category and the scope: the setting's variable (einv_gui_searchTime) exists
 * at once, set to what the text holds for it or else the default, and every other part of the mod reads it
 * exactly as before. What changes is where the value comes from: not a row of CBA's menu of its own but the
 * text of one setting for them all (einv_main_settings), which the setup wizard's General page writes and
 * fnc_applySettings reads - it sets the variable, runs the setting's script and raises CBA's setting-changed
 * event, as CBA did for a row of its own.
 *
 * The wizard draws a control for it by its type: a switch, a stepper, a drop-down, a text field.
 *
 * Arguments:
 * 0: Setting's name, the variable it sets <STRING>
 * 1: "CHECKBOX", "SLIDER", "LIST" or "EDITBOX" <STRING>
 * 2: Title and tooltip, [title, tooltip] - the tooltip's lines are wrapped with \n as CBA's descriptions are <ARRAY>
 * 3: What CBA_fnc_addSetting takes for that type: CHECKBOX the default; SLIDER [min, max, default, trailing
 *    decimals]; LIST [values, labels, index of the default]; EDITBOX the default text <ANY>
 * 4: Code to run when it changes, with the new value as _this - and once when the settings are first read,
 *    as CBA does <CODE> (default: {})
 * 5: Hidden: no control in the wizard - the value can still be written into the text by hand <BOOL> (default: false)
 *
 * Return Value:
 * Registered <BOOL>
 *
 * Example:
 * [QGVAR(searchBodies), "CHECKBOX", [LLSTRING(Setting_SearchBodies), LLSTRING(Setting_SearchBodies_Desc)], true] call einv_main_fnc_addSetting;
 *
 * Public: Yes
 */

params [
    ["_name", "", [""]], ["_type", "", [""]], ["_title", [], ["", []]], "_valueInfo", ["_script", {}, [{}]], ["_hidden", false, [false]]
];

_type = toUpper _type;

if (_name isEqualTo "" || {!(_type in ["CHECKBOX", "SLIDER", "LIST", "EDITBOX"])}) exitWith {
    WARNING_2("Server setting %1: no such type '%2'.",_name,_type);
    false
};

// A stringtable key is shown as the text it stands for.
private _fnc_text = {
    params ["_text"];

    if (_text isEqualType "" && {isLocalized _text}) then {
        _text = localize _text;
    };

    _text
};

_title params [["_label", "", [""]], ["_tip", "", [""]]];

if (_title isEqualType "") then {
    _label = _title;
};

private _entry = createHashMapFromArray [
    ["name", _name],
    ["type", _type],
    ["label", [_label] call _fnc_text],
    ["tip", [_tip] call _fnc_text],
    ["script", _script],
    ["hidden", _hidden]
];

private _default = switch (_type) do {
    case "CHECKBOX": {
        _valueInfo isEqualTo true
    };
    case "SLIDER": {
        _valueInfo params [["_min", 0, [0]], ["_max", 1, [0]], ["_value", 0, [0]], ["_decimals", 2, [0]]];

        _entry set ["min", _min];
        _entry set ["max", _max];
        _entry set ["decimals", _decimals];

        _value
    };
    case "LIST": {
        _valueInfo params [["_values", [], [[]]], ["_labels", [], [[]]], ["_index", 0, [0]]];

        _entry set ["values", +_values];
        _entry set ["labels", _labels apply {[_x] call _fnc_text}];

        _values param [_index, ""]
    };
    default {
        _valueInfo param [0, "", [""]]
    };
};

// A text setting given as CBA takes it - [default, isPassword, sanitizer] - is its first part.
if (_type isEqualTo "EDITBOX" && {_valueInfo isEqualType []}) then {
    _default = _valueInfo param [0, "", [""]];
};

_entry set ["default", _default];

// The key in the text: the name without the mod's prefix, "einv_".
private _key = toLowerANSI (_name select [5]);

_entry set ["key", _key];

if (_name in GVAR(serverSettings)) then {
    GVAR(serverOrder) deleteAt (GVAR(serverOrder) find _name);
};

GVAR(serverSettings) set [_name, _entry];
GVAR(serverKeys) set [_key, _name];
GVAR(serverOrder) pushBack _name;

// What the mod reads from now on: what the text holds already - CBA has read it from the server, the mission and the
// profile by the time any addon registers its settings - else the default. As CBA does for a row of its own, the
// value is there at once and the script runs only once the settings are ready (fnc_applySettings).
private _value = ([missionNamespace getVariable [QGVAR(settings), ""], [_name]] call FUNC(readSettings)) get _name;

missionNamespace setVariable [_name, [_value, _default] select (isNil "_value")];

true
