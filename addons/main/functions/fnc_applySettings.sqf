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
 * Before CBA's settings are ready - in Eden, which has no postInit, and while the mission starts - only the
 * variables are set, as CBA sets those of its own rows then: no script runs and CBA's event is not raised, and
 * the first call once they are ready still counts as the first (XEH_preInit calls it for a change of the text then).
 *
 * The values reach the variables the rest of the mod has always read (einv_gui_searchTime, einv_weight_enabled,
 * ...) under the same names and as the same kinds of value, so nothing that reads them knows the difference.
 * Missions that were set up before the settings moved keep working while the text is empty (fnc_readSettings).
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

private _values = [_text] call FUNC(readSettings);
private _ready = !isNil "cba_settings_ready";
private _first = _ready && {!GVAR(settingsApplied)};

if (_ready) then {
    GVAR(settingsApplied) = true;
};

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

if (_ready) then {
    {
        private _value = missionNamespace getVariable _x;

        _value call ((GVAR(serverSettings) get _x) get "script");

        // The same event CBA raises for its own settings (the hotbar listens to it).
        ["CBA_SettingChanged", [_x, _value]] call CBA_fnc_localEvent;
    } forEach _changed;
};

[QGVAR(settingsChanged), [_text]] call CBA_fnc_localEvent;
