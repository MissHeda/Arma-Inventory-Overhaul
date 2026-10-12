#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Shares the selected loadout with the other players or stops sharing it, in ACE's shared namespace.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Done <BOOL>
 *
 * Example:
 * call einv_arsenal_fnc_loadoutShare;
 *
 * Public: No
 */

// Only the player's own, in multiplayer, where the mission allows sharing.
if (GVAR(loadoutsTab) isNotEqualTo "mine" || {!isMultiplayer} || {!(missionNamespace getVariable [QACEGVAR(arsenal,allowSharedLoadouts), true])}) exitWith {false};

private _namespace = missionNamespace getVariable [QACEGVAR(arsenal,sharedLoadoutsNamespace), locationNull];

if (isNull _namespace) exitWith {false};

private _row = (["mine", false, GVAR(loadoutSelected)] call FUNC(loadoutsData)) param [0, []];

if (_row isEqualTo []) exitWith {false};

_row params ["_name", "_data", "", "_shared", "", "_check", ""];

// The player's profile name, not the unit's: the unit may be somebody else's (Zeus).
private _who = profileName;
private _var = _who + _name;
private _vars = +(_namespace getVariable [QACEGVAR(arsenal,sharedLoadoutsVars), []]);

if (_shared || {_var in _vars}) then {
    // Private again.
    _namespace setVariable [_var, nil, true];
    _namespace setVariable [QACEGVAR(arsenal,sharedLoadoutsVars), _vars - [_var], true];

    [QACEGVAR(arsenal,loadoutUnshared), [controlNull, _who, _name]] call CBA_fnc_remoteEvent;

    [format [LLSTRING(Loadouts_UnsharedHint), _name]] call FUNC(message);
} else {
    // What is shared is what ACE's list shares: the loadout as checked against the game.
    if (_check isEqualTo []) then {
        _check = [_row] call FUNC(verifyStep);
    };

    private _shown = [_who, _name, +(_check select 0)];

    _namespace setVariable [_var, _shown, true];
    _vars pushBackUnique _var;
    _namespace setVariable [QACEGVAR(arsenal,sharedLoadoutsVars), _vars, true];

    [QACEGVAR(arsenal,loadoutShared), [controlNull, _shown]] call CBA_fnc_remoteEvent;

    [format [LLSTRING(Loadouts_SharedHint), _name]] call FUNC(message);
};

["put"] call EFUNC(gui,playSound);

GVAR(loadoutsDirty) = true;

true
