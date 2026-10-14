#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Where something put on the ground goes (op putGround): the nearest pile within GROUND_RANGE of the
 * ground point that is not empty, belongs to this machine and can be seen from the eyes - the same floor,
 * nothing in the way (fnc_isNear) -, else a fresh one on the point. Never an empty pile: the engine
 * deletes an ordinary one it takes for empty, and a fresh one is a GroundWeaponHolder_Scripted, which the
 * engine leaves alone (fnc_pruneScriptedPile removes it once it is emptied).
 *
 * The ground point is the surface under the feet taken when the move was asked for ("where",
 * fnc_groundPos); without one - settlement for a requester who sat in a vehicle that is gone, swam or
 * fell - the terrain under where they were.
 *
 * In multiplayer only the server picks a pile: the piles it reuses are its own, the hub routes ground
 * work there, and the window no longer asks for one (an RPT error and objNull elsewhere). Asked for a
 * fresh one it works anywhere.
 *
 * Arguments:
 * 0: Where, [groundASL, eyeASL, vehicle, positionASL] - or a unit, for where it stands now <ARRAY or
 *    OBJECT>
 * 1: What the line of sight ignores - the requester <OBJECT> (default: objNull - the unit given as 0)
 * 2: A fresh pile, whatever lies there <BOOL> (default: false)
 * 3: Only a pile of ours may be joined - a GroundWeaponHolder_Scripted -, else a fresh one <BOOL>
 *    (default: false). For a backpack: the engine keeps a backpack just taken off in a plain holder of
 *    its own for the rest of the frame and deletes both at its end - joined, a dropped backpack went
 *    with them (0.4.1).
 *
 * Return Value:
 * Weapon holder, objNull when there is no point to put it at <OBJECT>
 *
 * Example:
 * [_where, player] call einv_storage_fnc_getGroundHolder;
 *
 * Public: No
 */

params [["_where", [], [[], objNull]], ["_ignore", objNull, [objNull]], ["_fresh", false, [false]], ["_ownOnly", false, [false]]];

// Older callers hand a unit: where it stands now.
if (_where isEqualType objNull) then {
    private _unit = _where;

    if (isNull _ignore) then {
        _ignore = _unit;
    };

    _where = if (isNull _unit) then {[]} else {
        [[_unit] call FUNC(groundPos), eyePos _unit, objectParent _unit, getPosASL _unit]
    };
};

if (isMultiplayer && {!isServer} && {!_fresh}) exitWith {
    ERROR("Ground piles are picked on the server - nothing was put down here.");
    objNull
};

_where params [["_ground", [], [[]]], ["_eye", [], [[]]], "", ["_position", [], [[]]]];

private _point = _ground;

if (count _point < 3 && {count _position >= 2}) then {
    _point = ATLToASL [_position select 0, _position select 1, 0];
};

if (count _point < 3) exitWith {objNull};

private _pile = objNull;

if (!_fresh) then {
    private _eyes = if (count _eye >= 3) then {_eye} else {_point vectorAdd [0, 0, 1.6]};

    _pile = ((nearestObjects [ASLToAGL _point, ["GroundWeaponHolder"], GROUND_RANGE, true]) select {
        local _x
        && {!isObjectHidden _x}
        && {isNull attachedTo _x}
        && {!_ownOnly || {typeOf _x == "GroundWeaponHolder_Scripted"}}
        && {(everyBackpack _x) findIf {_x getVariable [QGVAR(takenOff), false]} < 0}
        && {([_x] call FUNC(getContents)) isNotEqualTo []}
        && {[_eyes, _point, _x, GROUND_RANGE, _ignore] call FUNC(isNear)}
    }) param [0, objNull];
};

if (!isNull _pile) exitWith {_pile};

// A scripted holder: an ordinary GroundWeaponHolder holding only a backpack - an object of its own, no cargo
// the engine counts - is taken for empty and deleted with the backpack in it (0.4.0). The search above
// still finds it, it is a GroundWeaponHolder as well; the empty ones are ours to delete
// (fnc_pruneScriptedPile).
_pile = createVehicle ["GroundWeaponHolder_Scripted", [0, 0, 0], [], 0, "CAN_COLLIDE"];
_pile setPosASL _point;

_pile
