#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The server settings the wizard starts from, as its short text of them (aio_main_fnc_writeSettings: only what
 * is off its default). Each is a CBA setting of its own (aio_main_fnc_addSetting):
 *   - direct mode: the values in effect - the variables the mod reads (aio_gui_searchTime, ...), which CBA
 *     has set from the server, the mission and their files. CBA's menu shows the same.
 *   - menu mode: what CBA's menu shows for the source picked there - a change not yet confirmed in the menu
 *     first (CBA keeps those in its temporary values until OK), else that source's own value, else the default.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Text <STRING>
 *
 * Example:
 * [] call aio_setup_fnc_activeSettings;
 *
 * Public: No
 */

private _registry = missionNamespace getVariable [QEGVAR(main,serverSettings), createHashMap];
private _menu = (missionNamespace getVariable [QGVAR(mode), "direct"]) isEqualTo "menu" && {!isNil "cba_settings_fnc_get"};
private _source = uiNamespace getVariable ["cba_settings_source", "server"];
private _temp = uiNamespace getVariable [format ["cba_settings_%1Temp", _source], controlNull];
private _values = createHashMap;

{
    private _value = if (_menu) then {
        (_temp getVariable [_x, []]) param [0, [_x, _source] call cba_settings_fnc_get]
    } else {
        missionNamespace getVariable [_x, (_registry get _x) get "default"]
    };

    if (!isNil "_value") then {
        _values set [_x, _value];
    };
} forEach (missionNamespace getVariable [QEGVAR(main,serverOrder), []]);

[_values] call EFUNC(main,writeSettings)
