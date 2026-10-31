#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Server settings changed while the wizard is open - in CBA's Addon Options, by the wizard's own Save, by an admin
 * on another machine, by a mission script. CBA raises CBA_SettingChanged for each (before its settings are ready,
 * as in Eden, its own refresh event), and XEH_preInit gathers their names in GVAR(settingsQueue) - a dozen
 * confirmed at once in CBA's menu are one redraw. Each row follows at once: what Save compares with
 * (GVAR(cleanSettings)) takes the new value, and so does the draft wherever the player has not changed that
 * setting here. One changed here as well keeps the change made here - Save writes it, over the other one; with
 * the same value on both sides it is no change any more. Then the page is drawn again.
 *
 * Not in menu mode: there the wizard shows what CBA's menu holds for its source, which nothing outside it changes.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call aio_setup_fnc_onSettingChanged;
 *
 * Public: No
 */

private _names = GVAR(settingsQueue);

GVAR(settingsQueue) = [];

if (isNull (uiNamespace getVariable [QGVAR(display), displayNull]) || {_names isEqualTo []}) exitWith {};
if (GVAR(mode) isEqualTo "menu") exitWith {};

private _registry = missionNamespace getVariable [QEGVAR(main,serverSettings), createHashMap];
private _clean = ([GVAR(cleanSettings)] call EFUNC(main,parseSettings)) select 0;
private _draft = +GVAR(draftSettings);
private _changed = false;

{
    private _name = _x;
    private _entry = _registry get _name;

    if (isNil "_entry") then {continue};

    private _default = _entry get "default";

    // The value in effect as the wizard's text holds it - a number rounded to its decimals -, so it compares with
    // the draft's.
    private _live = missionNamespace getVariable [_name, _default];
    private _text = [createHashMapFromArray [[_name, _live]]] call EFUNC(main,writeSettings);
    private _now = (([_text] call EFUNC(main,parseSettings)) select 0) getOrDefault [_name, _default];
    private _was = _clean getOrDefault [_name, _default];

    if (_now isEqualTo _was) then {continue};

    if ((_draft getOrDefault [_name, _default]) isEqualTo _was) then {
        _draft set [_name, _now];
    };

    _clean set [_name, _now];
    _changed = true;
} forEach _names;

if (!_changed) exitWith {};

GVAR(cleanSettings) = [_clean] call EFUNC(main,writeSettings);

[[_draft] call EFUNC(main,writeSettings)] call FUNC(setSettingsDraft);

[GVAR(step)] call FUNC(showStep);
