#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * For missions and other mods: adds new things to a unit through this mod's grid instead of the engine's
 * addItem, addMagazine, addWeapon and addBackpack. The engine refuses an add once a container's config
 * maximumLoad is reached - which this mod's grid does not care about - or puts a magazine straight into an
 * empty weapon; either way a script that asked canAdd or took the item from somewhere first can lose it.
 * Here the things go into the unit's worn containers - the uniform, vest and backpack the unit has, the first
 * with room in the order of fnc_unitTargets (a container with a slot for the item's category before one
 * with plain cells), with the cargo commands, which ignore maximumLoad - wherever the layout finds free
 * cells (fnc_addNew). Free cells are the only limit. Never into a weapon and never onto the ground: what has
 * no room is not added, and the caller hears how much that was.
 *
 * A weapon, a backpack, a uniform or a vest is one thing each (a weapon comes bare, a container empty); a
 * magazine is full unless its rounds are given; a class that stacks fills the stacks of its key before it
 * opens a new tile. A backpack goes into the uniform or vest if they have room, never into a backpack.
 *
 * May be called on any machine: for a unit that is not local the call is sent to the machine where it is
 * (a CBA targeted event, no remoteExec whitelist needed) and the add runs there, against the unit's own
 * cargo. The number returned is then what this machine's picture of the unit's grid says will fit - the
 * add itself has no answer to give back in the same frame - and it is exact whenever the unit's cargo and
 * places are as this machine sees them. For a local unit it is the number counted into the cargo.
 *
 * Arguments:
 * 0: Unit - a person (CAManBase) <OBJECT>
 * 1: Class - an item, magazine, weapon, backpack, uniform or vest <STRING>
 * 2: How many <NUMBER> (default: 1)
 * 3: Rounds in each magazine, -1 for full ones; not read for anything but a magazine <NUMBER> (default: -1)
 * 4: How many times the call was passed on to another machine already - for the event handler only <NUMBER> (default: 0)
 *
 * Return Value:
 * How many were put in <NUMBER>
 *
 * Example:
 * [player, "ACE_fieldDressing", 8] call aio_storage_fnc_addToUnit;
 * [player, "30Rnd_65x39_caseless_mag", 3, 12] call aio_storage_fnc_addToUnit;
 *
 * Public: Yes
 */

params [["_unit", objNull, [objNull]], ["_class", "", [""]], ["_count", 1, [0]], ["_rounds", -1, [0]], ["_hops", 0, [0]]];

if (isNull _unit || {_class isEqualTo ""} || {!(_unit isKindOf "CAManBase")}) exitWith {0};

_count = floor _count;

if (_count < 1) exitWith {0};

// Something the game has: a weapon, uniform, vest or item, a magazine, a backpack, glasses.
private _known = ["CfgWeapons", "CfgMagazines", "CfgVehicles", "CfgGlasses"] findIf {isClass (configFile >> _x >> _class)} >= 0;

if (!_known) exitWith {
    WARNING_1("%1 is no class of the game - nothing was added.",_class);
    0
};

private _plan = [_unit, _class, _count, _rounds] call FUNC(addFit);

// Elsewhere: the unit's machine adds it, against its own cargo and places (the handler in XEH_postInit comes
// back here, local). An event that finds the unit moved on again is sent after it, a few times.
if (!local _unit) exitWith {
    if (_hops < 3) then {
        [QGVAR(addToUnit), [_unit, _class, _count, _rounds, _hops + 1], _unit] call CBA_fnc_targetEvent;
    };

    private _fits = 0;

    {
        _fits = _fits + (_x select 1);
    } forEach _plan;

    _fits
};

private _placed = 0;

{
    _x params ["_box", "_fit"];

    private _before = [_box, _class] call FUNC(countClass);

    [_box, _class, _fit, [], _rounds] call FUNC(addNew);

    // Counted, not taken from the answer: what arrived stays even when the add says it fell short.
    _placed = _placed + ((([_box, _class] call FUNC(countClass)) - _before) max 0 min _fit);
} forEach _plan;

// The places catch up with the cargo; and should this machine have laid the unit out differently from what
// the cells really are, what lies beyond the grid moves on as any surplus does.
if (_placed > 0) then {
    [_unit] call FUNC(queueMigrate);
};

_placed
