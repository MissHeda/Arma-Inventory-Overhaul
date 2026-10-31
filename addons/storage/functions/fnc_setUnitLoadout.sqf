#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * setUnitLoadout that keeps the whole loadout. The engine stops filling a uniform, vest or backpack at its
 * maximumLoad, but the grid of this mod is not bound by that load, so a loadout with more in a container
 * than the config allows (saved from the inventory or an arsenal) would lose the surplus. This sets the
 * loadout and then adds what the engine left out (fnc_topUpLoadout), only the difference, and notes the unit
 * so what lies beyond the grid moves on to its next container (fnc_queueMigrate). Use it in missions in
 * place of setUnitLoadout wherever the loadout may hold more than the containers' config load.
 *
 * May be called on any machine: for a unit that is not local the call is sent to the machine where it is
 * (a CBA targeted event, no remoteExec whitelist needed) and runs there. The loadout is the array
 * getUnitLoadout gives, or [loadout, rearm] as setUnitLoadout takes it; a config class name is set as it
 * is, with nothing to top up.
 *
 * ACE Arsenal and CBA_fnc_setLoadout need nothing of this: Arma Inventory Overhaul tops up their loadouts by
 * itself (event CBA_loadoutSet).
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: The loadout, [loadout, rearm] or a config class <ARRAY or STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player, _savedLoadout] call aio_storage_fnc_setUnitLoadout;
 *
 * Public: Yes
 */

params [["_unit", objNull, [objNull]], ["_loadout", [], [[], ""]]];

if (isNull _unit) exitWith {};

if (!local _unit) exitWith {
    [QGVAR(setUnitLoadout), [_unit, _loadout], _unit] call CBA_fnc_targetEvent;
};

_unit setUnitLoadout _loadout;

if !(_loadout isEqualType []) exitWith {};

// [loadout, rearm] or the loadout itself.
private _data = if (count _loadout == 2 && {(_loadout select 0) isEqualType []} && {(_loadout select 1) isEqualType true}) then {
    _loadout select 0
} else {
    _loadout
};

[_unit, _data] call FUNC(topUpLoadout);

// The containers of a loadout set in this frame can still be arriving: once more a frame later, which adds
// nothing when the first pass found it whole.
[{
    params ["_unit", "_data"];

    if (!isNull _unit && {local _unit}) then {
        [_unit, _data] call FUNC(topUpLoadout);
    };
}, [_unit, _data]] call FUNC(nextFrame);

[_unit] call FUNC(queueMigrate);
