#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether the window may open on a vehicle for a player on foot, without the engine naming it: ACE's
 * interaction "Inventory" on a vehicle (einv_compat_ace_interaction), and an opening that named nothing to
 * loot while the player looks at a vehicle (fnc_onInventoryOpened, fnc_guardVanilla).
 *
 * A vehicle - not a person, a crate or a pile, which open by the engine's own actions - that is alive, has
 * an inventory (no disableInventory) and cells to show: a cargo space by its load, or a grid of its own
 * (einv_grid, a rule; einv_storage_fnc_getBlocks). The player is on foot, within the window's reach of it
 * (einv_storage_fnc_inReach: the reach setting plus half the vehicle's size - a truck is reached at its
 * side), and it is not locked to him (einv_locks_fnc_canReach: a lock of ours, a mission's lockInventory,
 * ACE's vehicle lock). The engine's own Gear action opens a locked vehicle as a locked section; this one,
 * which the player did not aim at the engine, opens nothing locked.
 *
 * Arguments:
 * 0: Player <OBJECT>
 * 1: Vehicle <OBJECT>
 *
 * Return Value:
 * May open <BOOL>
 *
 * Example:
 * [ACE_player, cursorObject] call einv_gui_fnc_canOpenVehicle;
 *
 * Public: Yes
 */

params [["_unit", objNull, [objNull]], ["_vehicle", objNull, [objNull]]];

if (isNull _unit || {isNull _vehicle} || {!alive _vehicle} || {!isNull objectParent _unit}) exitWith {false};
if (!(_vehicle isKindOf "AllVehicles") || {_vehicle isKindOf "CAManBase"}) exitWith {false};
if (getNumber (configOf _vehicle >> "disableInventory") == 1) exitWith {false};

// Cells to show, as the window lays it out: a vehicle with no cargo space and no grid of its own has none.
private _cells = 0;

{
    _x params ["_cols", "_rows", ["_holes", []]];

    _cells = _cells + _cols * _rows - count _holes;
} forEach ([_vehicle] call EFUNC(storage,getBlocks));

if (_cells <= 0) exitWith {false};

[_unit, _vehicle] call EFUNC(storage,inReach) && {([_unit, _vehicle] call EFUNC(locks,canReach)) select 0}
