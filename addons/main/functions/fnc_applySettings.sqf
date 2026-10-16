#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Puts the text of the server settings (einv_main_settings) into effect on this machine: every registered
 * setting's variable is set to what the text says - or to its default, where it says nothing - and, the way
 * CBA does for a row of its own, its script runs with the value and CBA's setting-changed event is raised. Called
 * by CBA when the settings are first read and whenever the text changes, on every machine, so what the server or the
 * mission decides reaches everyone and a client joining later alike. A setting whose value did not change is left
 * alone - but for the first time, when all of them count as changed, as CBA runs every setting's script once.
 *
 * The values reach the variables the rest of the mod has always read (einv_gui_searchTime, einv_weight_enabled,
 * ...) under the same names and as the same kinds of value, so nothing that reads them knows the difference.
 *
 * Missions that were set up before the settings moved - lines in a cba_settings.sqf for einv_gui_searchTime
 * and the like, which CBA no longer knows - keep working while the text is empty: whatever the mission's file
 * says for a registered setting is taken, as if the text said it. Once the text holds anything, only it counts.
 * What the server's own file or profile said for them is not carried over; the wizard writes it again.
 *
 * Arguments:
 * 0: The text <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["einv1, weight_enabled=0"] call einv_main_fnc_applySettings;
 *
 * Public: No
 */

params [["_text", "", [""]]];

private _values = ([_text] call FUNC(parseSettings)) select 0;

// A mission's own cba_settings.sqf lines for the old rows of CBA's menu - [value, priority] by name in CBA's
// namespace of the mission's file. Only while nothing was ever written to the text.
if (_text isEqualTo "") then {
    private _legacy = missionNamespace getVariable ["cba_settings_missionConfig", objNull];

    if (!isNull _legacy) then {
        {
            private _old = _legacy getVariable _x;

            if (isNil "_old" || {!(_old isEqualType [])}) then {continue};

            private _raw = _old param [0];

            if (isNil "_raw") then {continue};

            private _written = switch (true) do {
                case (_raw isEqualType true): {["0", "1"] select _raw};
                case (_raw isEqualType 0): {str _raw};
                case (_raw isEqualType ""): {
                    [_raw, [_raw] call FUNC(encodeText)] select (((GVAR(serverSettings) get _x) get "type") isEqualTo "EDITBOX")
                };
                default {nil};
            };

            if (isNil "_written") then {continue};

            private _value = [GVAR(serverSettings) get _x, _written] call FUNC(parseValue);

            if (!isNil "_value") then {
                _values set [_x, _value];
            };
        } forEach GVAR(serverOrder);
    };
};

private _first = !GVAR(settingsApplied);

GVAR(settingsApplied) = true;

// All the variables first, then the scripts: a script that reads several settings (the use-from-containers
// ones read all three) sees them all as the text says, not some of them as they were.
private _changed = [];

{
    private _entry = GVAR(serverSettings) get _x;
    private _value = _values getOrDefault [_x, _entry get "default"];
    private _before = missionNamespace getVariable [_x, _entry get "default"];

    missionNamespace setVariable [_x, _value];

    if (_first || {_before isNotEqualTo _value}) then {
        _changed pushBack _x;
    };
} forEach GVAR(serverOrder);

{
    private _value = missionNamespace getVariable _x;

    _value call ((GVAR(serverSettings) get _x) get "script");

    // The same event CBA raises for its own settings, once it is ready (the hotbar listens to it).
    if (!isNil "cba_settings_ready") then {
        ["CBA_SettingChanged", [_x, _value]] call CBA_fnc_localEvent;
    };
} forEach _changed;

[QGVAR(settingsChanged), [_text]] call CBA_fnc_localEvent;
