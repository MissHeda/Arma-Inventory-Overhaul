#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Which of a unit's three containers a container object is: "uniform", "vest" or "backpack"; "" for any
 * other (a crate, the ground, a body's, another unit's). Only the own gear is ever used from, so the
 * window and the hotbar ask this before they ask fnc_useState.
 *
 * Arguments:
 * 0: Container <OBJECT>
 * 1: Unit whose container it should be - the player by default <OBJECT> (default: ACE_player)
 *
 * Return Value:
 * "uniform", "vest", "backpack" or "" <STRING>
 *
 * Example:
 * [backpackContainer player] call aio_storage_fnc_useKind;
 *
 * Public: Yes
 */

params [["_container", objNull, [objNull]], ["_unit", objNull, [objNull]]];

if (isNull _unit) then {
    _unit = missionNamespace getVariable ["ACE_player", player];
};

if (isNull _container || {isNull _unit}) exitWith {""};

private _at = [uniformContainer _unit, vestContainer _unit, backpackContainer _unit] find _container;

if (_at < 0) exitWith {""};

USE_KINDS select _at
