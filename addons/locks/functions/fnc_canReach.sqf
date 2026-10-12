#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether a unit may open a container and move things in and out of it - what every gate asks: the
 * window, the vanilla inventory's gate, the client's check before a move and the guard on every op.
 *
 * The lock that counts is the container's own, or that of the locked object it lies in or is attached to
 * (fnc_lockHolder), or - for a uniform, vest or backpack opened from inside a container - of the root the
 * window passes. Then a lock the mission set with lockInventory on this machine (not the one
 * fnc_refresh set for the player), then other mods' providers (fnc_addProvider), which are asked about
 * the container at the top of the chain.
 *
 * Arguments:
 * 0: Unit asking <OBJECT>
 * 1: Container <OBJECT>
 * 2: Container at the top of the chain it was opened from, objNull when it was opened itself <OBJECT> (default: objNull)
 *
 * Return Value:
 * [may it be opened, why not - a text for the notice or the hint, "" when it may; a tip for the window
 * when it is open to the unit only because of who they are - member, admin, Zeus] <ARRAY>
 *
 * Example:
 * [player, _crate] call einv_locks_fnc_canReach;
 *
 * Public: Yes
 */

params [
    ["_unit", objNull, [objNull]],
    ["_container", objNull, [objNull]],
    ["_root", objNull, [objNull]]
];

if (isNull _container) exitWith {[true, "", ""]};

// Ours: the container itself, the locked object it lies in, or - for a uniform, vest or backpack opened
// from inside a container - the one at the top of that chain (the window passes it).
private _holder = [_container] call FUNC(lockHolder);

if (isNull _holder && {!isNull _root}) then {
    _holder = [_root] call FUNC(lockHolder);
};

private _lock = [_holder] call FUNC(getLock);
([_unit, _lock] call FUNC(isAllowed)) params ["_allowed", "_how"];

if (!_allowed) exitWith {[false, format [LLSTRING(Notice), [_lock] call FUNC(describe)], ""]};

private _top = _container;

if (!isNull _root) then {
    _top = _root;
};

// The engine's own lock a mission set on this machine - not the one fnc_refresh set for us. Only asked for
// the player sitting here: on a hosting server it would answer for the host, not for a client asking.
// People are left out: lockInventory on a unit locks the backpack they wear, which is the window's own
// rule for persons.
private _player = missionNamespace getVariable ["ACE_player", objNull];

if (
    hasInterface
    && {_unit isEqualTo _player}
    && {!(_top isKindOf "CAManBase")}
    && {lockedInventory _top}
    && {!(_top getVariable [QGVAR(engineMine), false])}
) exitWith {[false, LLSTRING(Mission), ""]};

// Other mods' locks (einv_compat_ace_vehiclelock).
private _refusal = "";

{
    private _said = [_unit, _top] call _x;

    if (!isNil "_said" && {_said isEqualType ""} && {_said isNotEqualTo ""}) exitWith {
        _refusal = _said;
    };
} forEach GVAR(providers);

if (_refusal isNotEqualTo "") exitWith {[false, _refusal, ""]};

private _tip = switch (_how) do {
    case "member": {format [LLSTRING(Tip_Member), [_lock] call FUNC(describe)]};
    case "admin": {format [LLSTRING(Tip_Admin), [_lock] call FUNC(describe)]};
    case "zeus": {format [LLSTRING(Tip_Zeus), [_lock] call FUNC(describe)]};
    default {""};
};

[true, "", _tip]
