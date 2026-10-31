#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether an object is a pile of things on the ground rather than a crate or a vehicle. Such a pile has
 * no capacity of its own, and it is deleted once it is empty - by the engine, or for a scripted one by
 * fnc_pruneScriptedPile.
 *
 * Arguments:
 * 0: Object <OBJECT>
 *
 * Return Value:
 * Is a weapon holder <BOOL>
 *
 * Example:
 * [cursorObject] call aio_storage_fnc_isGroundHolder;
 *
 * Public: No
 */

params [["_object", objNull, [objNull]]];

// Dropped things lie in a GroundWeaponHolder, a dead soldier's weapon in a WeaponHolderSimulated, and
// older missions still place plain WeaponHolders. A unit's uniform and vest are containers of a class
// the engine derives from WeaponHolder as well (ContainerSupply) - they are no pile: taken for one, a
// uniform had no pockets, no limit, and showed up a second time as the ground after a move into it.
!isNull _object && {!(_object isKindOf "ContainerSupply")} && {
    _object isKindOf "GroundWeaponHolder"
    || {_object isKindOf "WeaponHolder"}
    || {_object isKindOf "WeaponHolderSimulated"}
}
