#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Renames the selected loadout. Not one that is shared: the share is kept under its old name.
 *
 * Arguments:
 * 0: New name <STRING>
 *
 * Return Value:
 * Renamed <BOOL>
 *
 * Example:
 * ["Medic"] call einv_arsenal_fnc_loadoutRename;
 *
 * Public: No
 */

params [["_newName", "", [""]]];

private _tab = GVAR(loadoutsTab);

// Somebody else's loadout is not the player's to name.
if (_tab isEqualTo "public") exitWith {false};

private _row = ([_tab, false, GVAR(loadoutSelected)] call FUNC(loadoutsData)) param [0, []];

if (_row isEqualTo []) exitWith {false};

_row params ["_name", "_data", "", "_shared", "", "", ""];

if (_newName isEqualTo "") exitWith {
    [LLSTRING(Loadouts_ErrNoName), "loss"] call FUNC(message);

    false
};

if (_newName isEqualTo _name) exitWith {false};

private _editDefaults = call ACEFUNC(arsenal,canEditDefaultLoadout);

if (_tab isEqualTo "default" && {!_editDefaults}) exitWith {false};

// A share is kept under the old name: renaming would leave it standing for a loadout that is gone.
if (_shared) exitWith {
    [format [LLSTRING(Loadouts_ErrShared), _name], "loss"] call FUNC(message);

    false
};

private _kept = if (_tab isEqualTo "default") then {
    missionNamespace getVariable [QACEGVAR(arsenal,defaultLoadoutsList), []]
} else {
    profileNamespace getVariable [QACEGVAR(arsenal,saved_loadouts), []]
};

if ((_kept findIf {(_x param [0, ""]) isEqualTo _newName}) >= 0) exitWith {
    [format [LLSTRING(Loadouts_ErrExists), _newName], "loss"] call FUNC(message);

    false
};

if (_tab isEqualTo "default") then {
    if (is3DEN) then {
        // The editor keeps the list in the mission's attributes.
        [_name, _newName] call ACEFUNC(arsenal,renameDefaultLoadout);

        set3DENMissionAttributes [[QACEGVAR(arsenal,DummyCategory), QACEGVAR(arsenal,DefaultLoadoutsListAttribute), missionNamespace getVariable [QACEGVAR(arsenal,defaultLoadoutsList), []]]];
    } else {
        // In a mission the new one is told to everyone and the old one dropped, so a player who joins later
        // is told the new name only (a local rename would not reach them).
        [_newName, +_data, true] call ACEFUNC(arsenal,addDefaultLoadout);
        [_name, true] call ACEFUNC(arsenal,removeDefaultLoadout);
    };
} else {
    private _index = _kept findIf {(_x param [0, ""]) isEqualTo _name};

    if (_index >= 0) then {
        (_kept select _index) set [0, _newName];
    };
};

GVAR(verified) = createHashMap;
GVAR(loadoutSelected) = _newName;
GVAR(loadoutName) = _newName;
GVAR(loadoutsDirty) = true;

["put"] call EFUNC(gui,playSound);
[format [LLSTRING(Loadouts_Renamed), _name, _newName]] call FUNC(message);

true
