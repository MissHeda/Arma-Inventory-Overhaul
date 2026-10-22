#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Registers a setting that is the same for everyone - what a server or a mission decides, not what a player
 * sets for themselves - in two places at once, which share one value:
 *   - CBA: a setting of its own (CBA_fnc_addSetting with isGlobal 1), a row in CBA's Addon Options, category
 *     "Arma Inventory Overhaul - Server", sub-category its topic's (GVAR(topics)). CBA reads its value from the
 *     server, the mission and a cba_settings.sqf, sets the variable (einv_gui_searchTime) at once, runs the
 *     script once the settings are ready and again on every change, on every machine, and raises its
 *     setting-changed event - exactly as for any other CBA setting, so nothing that reads it knows the difference.
 *   - The setup wizard's General page: a control by its type - a switch, a stepper, a drop-down, a text field.
 *     The wizard shows the value in effect and saves a change through CBA (CBA_settings_fnc_set), into the
 *     same place CBA's own Server or Mission tab writes to.
 * Called with the arguments of CBA_fnc_addSetting less the category and the scope.
 *
 * Arguments:
 * 0: Setting's name, the variable it sets <STRING>
 * 1: "CHECKBOX", "SLIDER", "LIST" or "EDITBOX" <STRING>
 * 2: Title and tooltip, [title, tooltip] - the tooltip's lines are wrapped with \n as CBA's descriptions are <ARRAY>
 * 3: What CBA_fnc_addSetting takes for that type: CHECKBOX the default; SLIDER [min, max, default, trailing
 *    decimals]; LIST [values, labels, index of the default]; EDITBOX the default text, or [default, isPassword,
 *    sanitizer] <ANY>
 * 4: Code to run when it changes, with the new value as _this - and once when the settings are first read,
 *    as CBA does <CODE> (default: {})
 * 5: Hidden: no control in the wizard - it is still a row of CBA's menu <BOOL> (default: false)
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

// The topic it is shown under, in the wizard and as CBA's sub-category: the one that names it, else "Other".
private _topicIndex = GVAR(topics) findIf {_name in (_x select 2)};
private _topic = ["other", ELSTRING(setup,Topic_other), []];

if (_topicIndex >= 0) then {
    _topic = GVAR(topics) select _topicIndex;
};

private _entry = createHashMapFromArray [
    ["name", _name],
    ["type", _type],
    ["label", [_label] call _fnc_text],
    ["tip", [_tip] call _fnc_text],
    ["script", _script],
    ["hidden", _hidden],
    ["topic", _topic select 0],
    ["subCategory", [_topic select 1] call _fnc_text]
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

// The key in the wizard's text: the name without the mod's prefix, "einv_".
private _key = toLowerANSI (_name select [5]);

_entry set ["key", _key];

if (_name in GVAR(serverSettings)) then {
    GVAR(serverOrder) deleteAt (GVAR(serverOrder) find _name);
};

GVAR(serverSettings) set [_name, _entry];
GVAR(serverKeys) set [_key, _name];
GVAR(serverOrder) pushBack _name;

// The CBA setting itself: global, the same for everyone, the server or the mission decides.
[
    _name, _type, [_entry get "label", _entry get "tip"], [CBA_SETTINGS_EINV_SERVER, _entry get "subCategory"], _valueInfo, 1, _script
] call CBA_fnc_addSetting;

// CBA has set the variable by now. Should its settings not be loaded yet, the default stands in until they are.
if (isNil _name) then {
    missionNamespace setVariable [_name, _default];
};

true
