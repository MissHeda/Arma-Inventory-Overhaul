#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Copies the selected default or public loadout into Mine, under the name in the field or its own.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Copied <BOOL>
 *
 * Example:
 * call einv_arsenal_fnc_loadoutCopy;
 *
 * Public: No
 */

private _tab = GVAR(loadoutsTab);

if (_tab isEqualTo "mine") exitWith {false};

private _row = ([_tab, false, GVAR(loadoutSelected)] call FUNC(loadoutsData)) param [0, []];

if (_row isEqualTo []) exitWith {false};

_row params ["_name", "_data"];

// Under the name in the field, else under its own.
private _typed = trim GVAR(loadoutName);
private _target = [_typed, _name] select (_typed isEqualTo "");

private _namespace = missionNamespace getVariable [QACEGVAR(arsenal,sharedLoadoutsNamespace), locationNull];
private _sharedVars = [];

if (!isNull _namespace) then {
    _sharedVars = _namespace getVariable [QACEGVAR(arsenal,sharedLoadoutsVars), []];
};

// One of the player's loadouts that is shared is not written over.
if ((profileName + _target) in _sharedVars) exitWith {
    [format [LLSTRING(Loadouts_ErrShared), _target], "loss"] call FUNC(message);

    false
};

private _kept = profileNamespace getVariable [QACEGVAR(arsenal,saved_loadouts), []];
private _index = _kept findIf {(_x param [0, ""]) isEqualTo _target};

if (_index >= 0 && {!(["save|mine|" + _target, format [LLSTRING(Loadouts_ConfirmOverwrite), _target]] call FUNC(arm))}) exitWith {false};

// The loadout as it is kept, whatever this game or arsenal lacks: it stays in the copy for a game that has it.
private _copy = +_data;

if (count _copy == 10) then {
    _copy = [_copy, createHashMap];
};

if (_index < 0) then {
    _index = _kept pushBack [_target, _copy];
} else {
    _kept set [_index, [_target, _copy]];
};

GVAR(loadoutsDirty) = true;

["put"] call EFUNC(gui,playSound);
[format [LLSTRING(Loadouts_Saved), _target]] call FUNC(message);

[QACEGVAR(arsenal,onLoadoutSave), [_index, _copy select 0]] call CBA_fnc_localEvent;
[QACEGVAR(arsenal,onLoadoutSaveExtended), [_index, _copy]] call CBA_fnc_localEvent;

true
