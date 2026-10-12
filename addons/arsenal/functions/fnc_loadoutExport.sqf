#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Ctrl+C: copies the soldier's loadout to the clipboard in ACE's form - or, with Shift, the list of default
 * loadouts.
 *
 * Arguments:
 * 0: The list of defaults, not the soldier's loadout <BOOL> (default: false)
 *
 * Return Value:
 * Exported <BOOL>
 *
 * Example:
 * [false] call einv_arsenal_fnc_loadoutExport;
 *
 * Public: No
 */

params [["_lists", false, [false]]];

private _unit = GVAR(center);
private _display = uiNamespace getVariable [QEGVAR(gui,display), displayNull];

if (isNull _unit) exitWith {false};

private _defaults = missionNamespace getVariable [QACEGVAR(arsenal,defaultLoadoutsList), []];

if (_lists && {_defaults isEqualTo []}) exitWith {
    [LLSTRING(Loadouts_ErrNoDefaults), "loss"] call FUNC(message);

    false
};

private _text = "";

if (_lists) then {
    // ACE's own form: a list, one entry to a line.
    private _lines = [];
    private _last = count _defaults - 1;

    {
        _lines pushBack (format ["    %1%2", str _x, [",", ""] select (_forEachIndex == _last)]);
    } forEach _defaults;

    _text = "[" + endl + (_lines joinString endl) + endl + "];";
} else {
    _text = str (_unit call CBA_fnc_getLoadout);
};

if !([_text] call FUNC(clipboardWrite)) exitWith {
    [LLSTRING(Loadouts_ErrClipboard), "loss"] call FUNC(message);

    false
};

["put"] call EFUNC(gui,playSound);
[[LLSTRING(Loadouts_Exported), LLSTRING(Loadouts_ExportedDefaults)] select _lists] call FUNC(message);

[QACEGVAR(arsenal,loadoutExported), [_display, _lists]] call CBA_fnc_localEvent;

true
