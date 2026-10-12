#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Deletes the selected loadout after a second click. A shared one is unshared first; a public one is only
 * stopped being shared.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Deleted <BOOL>
 *
 * Example:
 * call einv_arsenal_fnc_loadoutDelete;
 *
 * Public: No
 */

private _row = ([GVAR(loadoutsTab), false, GVAR(loadoutSelected)] call FUNC(loadoutsData)) param [0, []];

if (_row isEqualTo []) exitWith {false};

_row params ["_name", "", "_author", "_shared", "_tab", "", "_id"];

private _namespace = missionNamespace getVariable [QACEGVAR(arsenal,sharedLoadoutsNamespace), locationNull];

// Somebody else's shared loadout is theirs to stop sharing - and the server admin's.
if (_tab isEqualTo "public" && {_author isNotEqualTo profileName} && {!(serverCommandAvailable "#logout")}) exitWith {false};

// Default loadouts are the mission's, and the editor's or the Zeus's to change.
if (_tab isEqualTo "default" && {!(call ACEFUNC(arsenal,canEditDefaultLoadout))}) exitWith {false};

if !(["delete|" + _tab + "|" + _id, format [LLSTRING(Loadouts_ConfirmDelete), _name]] call FUNC(arm)) exitWith {false};

// Stops sharing: the loadout leaves the shared namespace and every other player's list.
private _fnc_unshare = {
    params ["_who", "_what"];

    if (isNull _namespace) exitWith {};

    private _var = _who + _what;

    _namespace setVariable [_var, nil, true];
    _namespace setVariable [QACEGVAR(arsenal,sharedLoadoutsVars), (_namespace getVariable [QACEGVAR(arsenal,sharedLoadoutsVars), []]) - [_var], true];

    [QACEGVAR(arsenal,loadoutUnshared), [controlNull, _who, _what]] call CBA_fnc_remoteEvent;
};

switch (_tab) do {
    case "public": {
        [_author, _name] call _fnc_unshare;
    };
    case "default": {
        // Every machine drops it, and a player who joins later is not told of it any more.
        [_name, !is3DEN] call ACEFUNC(arsenal,removeDefaultLoadout);
    };
    default {
        if (_shared) then {
            [profileName, _name] call _fnc_unshare;
        };

        private _kept = profileNamespace getVariable [QACEGVAR(arsenal,saved_loadouts), []];

        private _index = _kept findIf {(_x param [0, ""]) isEqualTo _name};

        // Not found is not "the last one": deleteAt counts a negative index from the end.
        if (_index >= 0) then {
            _kept deleteAt _index;
        };
    };
};

GVAR(verified) deleteAt (_tab + "|" + _id);
GVAR(loadoutSelected) = "";
GVAR(loadoutName) = "";
GVAR(loadoutsDirty) = true;

["put"] call EFUNC(gui,playSound);
[format [LLSTRING(Loadouts_Deleted), _name]] call FUNC(message);

if (_tab isNotEqualTo "public") then {
    [QACEGVAR(arsenal,onLoadoutDelete), [_name]] call CBA_fnc_localEvent;
};

true
