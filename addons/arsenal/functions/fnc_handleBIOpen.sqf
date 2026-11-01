#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The vanilla arsenal is asked to open (BIS_fnc_arsenal "Open", fnc_biArsenal.inc.sqf): by the setting,
 * ACE Arsenal opens with the same items (fnc_openBI), a red screen says it is not allowed, or the vanilla
 * one is left alone. Eden, BI's showcase, Warlords, missions that opt out, other units than the player's own on
 * foot, and a mission with handlers of its own always keep the vanilla one; Zeus is never blocked.
 *
 * Whenever the answer is false for one of those, the open is marked as meant for the vanilla window
 * (GVAR(biLetThrough)), so the safety net on its arsenalOpened (fnc_biSafetyNet) lets it be; the mark goes
 * when the vanilla window closes.
 *
 * Arguments:
 * 0: The arguments of the call: [full, box, unit] or a flag for the full arsenal <ARRAY or BOOL>
 *
 * Return Value:
 * This addon took it - the vanilla one must not open <BOOL>
 *
 * Example:
 * [[false, _box, player]] call aio_arsenal_fnc_handleBIOpen;
 *
 * Public: No
 */

params [["_args", [], [[], true]]];

private _mode = missionNamespace getVariable [QGVAR(biArsenal), "vanilla"];

// 1. Left alone, or kept with the grid panel beside its list (fnc_biOpened, from fnc_biSafetyNet): the vanilla arsenal opens (what
// does not fit is passed on and reported after it, fnc_biLeaveAlone). ACE Arsenal asked for where there is none: the same.
if (_mode in ["vanilla", "grid"] || {_mode isEqualTo "ace" && {!GVAR(ready)}}) exitWith {false};

// 2. What always keeps the vanilla arsenal.
private _passThrough = missionNamespace getVariable "aio_arsenal_biPassThrough";

if (
    !hasInterface || {_passThrough isEqualTo true}
    || {missionName isEqualTo "Arsenal" && {!isNil "arsenal_fnc_opened"}}
    || {!isNil "BIS_WL_arsenalEnabled"}
) exitWith {
    GVAR(biLetThrough) = true;

    false
};

// A mission that hooks the vanilla arsenal itself restricts it there: it keeps the one it was written for,
// unless it says ours is fine (aio_arsenal_biPassThrough set to false). Not under "not allowed": a server
// that forbids the vanilla arsenal forbids it for those missions too.
if (_mode isEqualTo "ace" && {isNil "_passThrough"} && {call FUNC(biMissionHooks)}) exitWith {
    GVAR(biLetThrough) = true;

    false
};

// 3. The arguments, as the vanilla function reads them: a flag alone is the full arsenal.
private _full = false;
private _cargo = objNull;
private _center = player;

if (_args isEqualType true) then {
    _full = _args;
} else {
    _args params [["_fullArg", false, [false]], ["_cargoArg", objNull, [objNull]], ["_centerArg", player, [objNull]]];

    _full = _fullArg;
    _cargo = _cargoArg;
    _center = _centerArg;
};

// 4. A unit that is not the vanilla arsenal's own business: it says what is wrong with its own error.
if (isNull _center || {!local _center} || {!(_center isKindOf "CAManBase")} || {!isNull objectParent _center}) exitWith {
    GVAR(biLetThrough) = true;

    false
};

// 5. One arsenal at a time, as the vanilla function's own "already running": ACE's camera is there while
// its window is open.
if (!isNil QACEGVAR(arsenal,camera) || {!isNull (findDisplay IDD_ARSENAL_BLOCKED)}) exitWith {true};

// 6. The rest on the frame's own time, as ACE's openBox does.
if (canSuspend) exitWith {
    [FUNC(handleBIOpen), _this] call CBA_fnc_directCall
};

// 7. Zeus is never stopped: with the curator's display open "not allowed" opens ACE's.
private _zeus = !isNull (findDisplay 312);

// 8. Not allowed.
if (_mode isEqualTo "block" && {!_zeus}) exitWith {
    call FUNC(showBlocked);

    true
};

// 9. ACE Arsenal, with the vanilla box's items.
([_cargo, _full, _center] call FUNC(biItems)) params ["_all", "_classes"];

if ([[_cargo, _center] select isNull _cargo, _center, _all, _classes] call FUNC(openBI)) exitWith {true};

// Could not: the vanilla one after all.
GVAR(biLetThrough) = true;

false
