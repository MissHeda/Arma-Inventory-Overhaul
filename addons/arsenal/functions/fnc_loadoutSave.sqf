#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Saves the soldier's loadout under a name, in ACE's lists: Mine, or the defaults where the player may edit
 * them. An existing name asks for the second click.
 *
 * Arguments:
 * 0: Name <STRING>
 *
 * Return Value:
 * Saved <BOOL>
 *
 * Example:
 * ["Rifleman"] call einv_arsenal_fnc_loadoutSave;
 *
 * Public: No
 */

params [["_name", "", [""]]];

private _unit = GVAR(center);

if (isNull _unit) exitWith {false};

if (_name isEqualTo "") exitWith {
    [LLSTRING(Loadouts_ErrNoName), "loss"] call FUNC(message);

    false
};

private _tab = GVAR(loadoutsTab);
private _editDefaults = call ACEFUNC(arsenal,canEditDefaultLoadout);

// On the tab of somebody else's loadout, or of defaults the player may not change, the selected loadout is
// what is kept - under the name in the field.
if (_tab isEqualTo "public" || {_tab isEqualTo "default" && {!_editDefaults}}) exitWith {
    call FUNC(loadoutCopy)
};

// A loadout that is shared is kept in the shared namespace under its name: saving over it would leave the
// share stale.
private _namespace = missionNamespace getVariable [QACEGVAR(arsenal,sharedLoadoutsNamespace), locationNull];
private _sharedVars = [];

if (!isNull _namespace) then {
    _sharedVars = _namespace getVariable [QACEGVAR(arsenal,sharedLoadoutsVars), []];
};

if ((profileName + _name) in _sharedVars) exitWith {
    [format [LLSTRING(Loadouts_ErrShared), _name], "loss"] call FUNC(message);

    false
};

// Where it goes: the player's own list, or the mission's defaults.
private _toDefaults = _tab isEqualTo "default";
private _kept = [
    profileNamespace getVariable [QACEGVAR(arsenal,saved_loadouts), []],
    missionNamespace getVariable [QACEGVAR(arsenal,defaultLoadoutsList), []]
] select _toDefaults;

private _exists = (_kept findIf {(_x param [0, ""]) isEqualTo _name}) >= 0;

if (_exists && {!(["save|" + _tab + "|" + _name, format [LLSTRING(Loadouts_ConfirmOverwrite), _name]] call FUNC(arm))}) exitWith {false};

// The soldier as CBA reads him - the places of his things in the extended info, put there by einv_storage.
private _extended = _unit call CBA_fnc_getLoadout;

private _index = -1;

if (_toDefaults) then {
    // The mission's list: ACE tells every machine, and keeps it for those who join later.
    [_name, _extended, !is3DEN] call ACEFUNC(arsenal,addDefaultLoadout);

    _index = (missionNamespace getVariable [QACEGVAR(arsenal,defaultLoadoutsList), []]) findIf {(_x param [0, ""]) isEqualTo _name};
} else {
    // What is unique goes in as the thing it stands for, weapons as their base: in place, as ACE does it.
    [_extended select 0] call ACEFUNC(arsenal,replaceUniqueItemsLoadout);

    _index = _kept findIf {(_x param [0, ""]) isEqualTo _name};

    if (_index < 0) then {
        _index = _kept pushBack [_name, _extended];
    } else {
        _kept set [_index, [_name, _extended]];
    };
};

GVAR(loadoutSelected) = _name;
GVAR(loadoutName) = _name;
GVAR(loadoutsDirty) = true;

["put"] call EFUNC(gui,playSound);
[format [LLSTRING(Loadouts_Saved), _name]] call FUNC(message);

[QACEGVAR(arsenal,onLoadoutSave), [_index, _extended select 0]] call CBA_fnc_localEvent;
[QACEGVAR(arsenal,onLoadoutSaveExtended), [_index, _extended]] call CBA_fnc_localEvent;

true
