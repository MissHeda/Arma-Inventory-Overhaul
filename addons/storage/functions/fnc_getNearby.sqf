#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What lies around a unit that is worth a box of its own in the loot column: every pile on the ground that
 * holds something and every crate, within the reach (einv_storage_nearbyRange), on the same floor and in
 * sight from the eyes - nothing through walls or floors (fnc_isNear). Nearest first, at most `max`.
 *
 * Not vehicles and bodies - they show when they are opened, a convoy would flood the column with big grids
 * and dolls -, nor living persons (their own action opens them). Not what a mission marks with the public
 * variable einv_nearby = false, what is locked (lockInventory), hidden, carried (ACE) or loaded somewhere.
 * An empty crate shows - it is a place to put things -, an empty pile does not: the engine deletes it.
 *
 * Seated in a vehicle nothing lies "around" the seat: the engine shows the vehicle's cargo.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Reach in metres, measured flat from the feet <NUMBER> (default: 3)
 * 2: Most boxes <NUMBER> (default: NEARBY_MAX)
 *
 * Return Value:
 * Piles and crates, nearest first <ARRAY of OBJECTs>
 *
 * Example:
 * [player, 3] call einv_storage_fnc_getNearby;
 *
 * Public: Yes
 */

params [["_unit", objNull, [objNull]], ["_range", 3, [0]], ["_max", NEARBY_MAX, [0]]];

if (isNull _unit || {!isNull objectParent _unit}) exitWith {[]};

private _eye = eyePos _unit;
private _feet = getPosASL _unit;

// Ground piles and crates. The piles fnc_getGroundHolder makes (GroundWeaponHolder_Scripted) are a kind of
// WeaponHolder and so found here with the others. A uniform's or vest's container is a WeaponHolder as well
// (ContainerSupply), and a backpack's is a crate - neither is wanted, the first is left out by name and the
// second is not a ReammoBox_F.
private _found = (nearestObjects [_unit, ["WeaponHolder", "WeaponHolderSimulated", "ReammoBox_F"], _range + 1, true]) select {
    !(_x isKindOf "ContainerSupply")
    && {alive _x}
    && {!isObjectHidden _x}
    && {isNull attachedTo _x}
    && {isNull objectParent _x}
    && {!lockedInventory _x}
    && {(_x getVariable ["einv_nearby", true]) isNotEqualTo false}
    && {!([_x] call FUNC(isGroundHolder)) || {([_x] call FUNC(getContents)) isNotEqualTo []}}
    && {[_eye, _feet, _x, _range, _unit] call FUNC(isNear)}
};

_found select [0, _max]
