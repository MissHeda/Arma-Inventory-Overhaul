#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Finds the server settings in a pasted text: the lines of a cba_settings.sqf or of CBA's Export that set one of
 * them (einv_gui_searchTime = 0.6;), read with CBA's own reader (cba_settings_fnc_parse) - and the one line of the
 * settings box of the test builds (einv_main_settings = "einv1, gui_searchTime=0.6";), whose values count where no
 * line of their own sets them. Each value is held to what its setting takes (einv_main_fnc_parseValue): a number cut to
 * its range, a choice by its value. Their priority ("force") is not taken over: where and how this machine saves
 * is the wizard's own choice. A text that is no such file has no settings - a bare line of statements could as
 * well be rules.
 *
 * Arguments:
 * 0: Pasted text <STRING>
 *
 * Return Value:
 * [values, warnings] - the settings it names, setting's name -> value as its variable holds it <HASHMAP>, and what
 * was left out <ARRAY of STRING>
 *
 * Example:
 * ["force einv_gui_searchTime = 0.8;"] call einv_setup_fnc_importSettings;
 *
 * Public: No
 */

params [["_text", "", [""]]];

private _values = createHashMap;
private _warnings = [];

if ((toLower _text) find "einv_" < 0 || {isNil "cba_settings_fnc_parse"}) exitWith {[_values, _warnings]};

private _registry = missionNamespace getVariable [QEGVAR(main,serverSettings), createHashMap];

// CBA's lines name a setting in any case; the registry by its name in lower case.
private _byLower = createHashMap;

{
    _byLower set [toLower _x, _x];
} forEach (missionNamespace getVariable [QEGVAR(main,serverOrder), []]);

private _box = "";
private _own = createHashMap;

{
    _x params [["_name", "", [""]], "_raw"];

    private _lower = toLower _name;

    if (_lower isEqualTo LEGACY_SETTINGS) then {
        if (!isNil "_raw" && {_raw isEqualType ""}) then {
            _box = _raw;
        };

        continue;
    };

    private _setting = _byLower getOrDefault [_lower, ""];

    if (_setting isEqualTo "") then {continue};

    private _entry = _registry get _setting;

    // Written as the wizard's text would hold it, then read as that text is - the same checks, the same ranges.
    private _written = "";

    if (!isNil "_raw") then {
        _written = switch (true) do {
            case (_raw isEqualType true): {["0", "1"] select _raw};
            case (_raw isEqualType 0): {str _raw};
            case (_raw isEqualType ""): {[_raw, [_raw] call EFUNC(main,encodeText)] select ((_entry get "type") isEqualTo "EDITBOX")};
            default {""};
        };
    };

    private _value = [_entry, _written] call EFUNC(main,parseValue);

    if (isNil "_value") then {
        _warnings pushBack format ["'%1': the value cannot be read - left out.", _name];
        continue;
    };

    _own set [_setting, _value];
} forEach ([trim _text, false, "", false] call cba_settings_fnc_parse);

// The box first, cleaned the way its own row in CBA's menu cleaned it; a line of its own wins over it.
if (_box isNotEqualTo "") then {
    ([trim (_box call EFUNC(main,sanitizeSettings))] call EFUNC(main,parseSettings)) params ["_named", "_boxWarnings"];

    _values = _named;
    _warnings = _boxWarnings + _warnings;
};

_values merge [_own, true];

[_values, _warnings]
