#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Makes the selected loadout of Mine a default one of the mission, where the player may edit them.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Done <BOOL>
 *
 * Example:
 * call einv_arsenal_fnc_loadoutMakeDefault;
 *
 * Public: No
 */

// Only where the mission has defaults, and the player may change them.
if (
    GVAR(loadoutsTab) isNotEqualTo "mine" || {!(missionNamespace getVariable [QACEGVAR(arsenal,allowDefaultLoadouts), true])}
    || {!(call ACEFUNC(arsenal,canEditDefaultLoadout))}
) exitWith {false};

private _row = (["mine", false, GVAR(loadoutSelected)] call FUNC(loadoutsData)) param [0, []];

if (_row isEqualTo []) exitWith {false};

_row params ["_name", "_data"];

// Told to every machine and kept for those who join later; in the editor it is the mission's attribute.
[_name, +_data, !is3DEN] call ACEFUNC(arsenal,addDefaultLoadout);

["put"] call EFUNC(gui,playSound);
[format [LLSTRING(Loadouts_Saved), _name]] call FUNC(message);

GVAR(loadoutsDirty) = true;

true
