#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Notes that the cargo of a unit local here changed, for fnc_tickMigrate to look at its surplus a moment
 * later. Nothing tells when a script adds an item (addItem and its relatives raise no event), so the
 * triggers are the ones that come close: the player's loadout event, the engine's Take / Put /
 * InventoryClosed, a loadout set (fnc_onLoadoutSet), a changed rule set, a unit taken over. They all end
 * here, and a unit already waiting keeps its earlier time - a burst of changes is one look MIGRATE_DELAY
 * after the first.
 *
 * Only units local here: the machine that owns a unit's cargo is the one that sees it change, and the
 * authority of its containers (fnc_rootOf) is where the moves run. Not in Eden, which runs no per-frame
 * handler and has nothing to move.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Wait before it is looked at, seconds <NUMBER> (default: MIGRATE_DELAY)
 * 2: Tries so far, for requests that were not carried out <NUMBER> (default: 0)
 * 3: Requester - whose reach counts <OBJECT> (default: the unit itself)
 *
 * Return Value:
 * None
 *
 * Example:
 * [player] call aio_storage_fnc_queueMigrate;
 *
 * Public: No
 */

params [
    ["_unit", objNull, [objNull]],
    ["_delay", MIGRATE_DELAY, [0]],
    ["_tries", 0, [0]],
    ["_requester", objNull, [objNull]]
];

if (is3DEN || {isNull _unit} || {!local _unit} || {!(_unit isKindOf "CAManBase")}) exitWith {};

private _at = diag_tickTime + _delay;
private _index = GVAR(migrateDue) findIf {(_x select 0) isEqualTo _unit};

// Already waiting: the earlier time stays.
if (_index >= 0) exitWith {
    private _entry = GVAR(migrateDue) select _index;

    _entry set [1, (_entry select 1) min _at];
};

GVAR(migrateDue) pushBack [_unit, _at, _tries, _requester];
