#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Empties a container by taking out what is in it, one kind after another, with negative counts - the
 * way ACE does it (its arsenal and magazine functions), which works on a unit's uniform, vest and
 * backpack as on any crate. The clear*CargoGlobal commands did not hold on a unit's containers in the
 * game: what was cleared came back (2026-10-08).
 *
 * What it takes out is gone, not handed on and not noted in any journal: it empties a uniform, vest or
 * backpack that was just added (fnc_restore), whose default contents must not stay beside what it is
 * filled with.
 *
 * Arguments:
 * 0: Container <OBJECT>
 *
 * Return Value:
 * It is empty now <BOOL>
 *
 * Example:
 * [backpackContainer player] call aio_storage_fnc_clearCargo;
 *
 * Public: No
 */

params [["_container", objNull, [objNull]]];

if (isNull _container) exitWith {false};

(getItemCargo _container) params ["_itemClasses", "_itemCounts"];

{
    _container addItemCargoGlobal [_x, -(_itemCounts select _forEachIndex)];
} forEach _itemClasses;

{
    _x params ["_class", "_ammo"];
    _container addMagazineAmmoCargo [_class, -1, _ammo];
} forEach (magazinesAmmoCargo _container);

(getWeaponCargo _container) params ["_weaponClasses", "_weaponCounts"];

{
    _container addWeaponCargoGlobal [_x, -(_weaponCounts select _forEachIndex)];
} forEach _weaponClasses;

(getBackpackCargo _container) params ["_backpackClasses", "_backpackCounts"];

{
    _container addBackpackCargoGlobal [_x, -(_backpackCounts select _forEachIndex)];
} forEach _backpackClasses;

((getItemCargo _container) select 0) isEqualTo []
&& {(magazinesAmmoCargo _container) isEqualTo []}
&& {((getWeaponCargo _container) select 0) isEqualTo []}
&& {((getBackpackCargo _container) select 0) isEqualTo []}
