#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The last step of a pile's watch (fnc_watchPile): the pile is filled, and the window shows it - already, because
 * Ravage's own asking opened it; or now, opened on it here. A window open on something else (a guess on the
 * player's own gear) gives way to it. A pile that is gone or empty (taken from meanwhile) opens nothing.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Pile <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player, _pile] call aio_compat_ravage_fnc_watchOpen;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_pile", objNull, [objNull]]];

if (isNull _pile || {!alive _unit} || {_unit isNotEqualTo (missionNamespace getVariable ["ACE_player", player])}) exitWith {};

_pile setVariable [QGVAR(watched), nil];

if ((_unit distance _pile) > 5) exitWith {};

private _has = (itemCargo _pile) isNotEqualTo [] || {(magazineCargo _pile) isNotEqualTo []}
    || {(weaponCargo _pile) isNotEqualTo []} || {(backpackCargo _pile) isNotEqualTo []};

if (!_has) exitWith {};

private _window = uiNamespace getVariable [QEGVAR(gui,display), displayNull];

if (!isNull _window) then {
    if (_pile in [EGVAR(gui,container), EGVAR(gui,secondary)]) exitWith {};

    INFO("The window is open without Ravage's find - opened again on it.");
    ["Ravage's find opens instead (aio_compat_ravage_fnc_watchOpen)"] call EFUNC(gui,closeDisplay);
};

if (_pile in [EGVAR(gui,container), EGVAR(gui,secondary)] && {!isNull _window}) exitWith {};

// A frame later, once a closed window is gone.
[{
    params ["_unit", "_pile"];

    if (isNull _pile || {!isNull (uiNamespace getVariable [QEGVAR(gui,display), displayNull])}) exitWith {};

    [_unit, _pile, objNull] call EFUNC(gui,open);
}, [_unit, _pile]] call CBA_fnc_execNextFrame;
