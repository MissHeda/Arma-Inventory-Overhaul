#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether a container is the uniform, vest or backpack a living player wears - his own unit, or the
 * one he controls through Zeus (the mark BIS's remote control leaves on it). By Mia's rule the kits in
 * it are his, unconscious or not: he may wake up any moment and pack into one, and Enhanced First Aid
 * Kits writes them on his machine as well (its medical use, its kit window). So no other player's
 * window opens one, packs into one, takes out of one or moves one away (fnc_mayReach, fnc_checkTile). A
 * dead player's body is open to everyone again.
 *
 * Arguments:
 * 0: Container <OBJECT>
 *
 * Return Value:
 * Worn by a living player <BOOL>
 *
 * Example:
 * [backpackContainer player] call aio_compat_efak_fnc_isPlayerGear;
 *
 * Public: No
 */

params [["_container", objNull, [objNull]]];

if (!isMultiplayer || {isNull _container}) exitWith {false};

// allUnits holds the living only.
(allUnits findIf {
    (isPlayer _x || {!isNull (_x getVariable ["bis_fnc_moduleRemoteControl_owner", objNull])})
    && {_container in [uniformContainer _x, vestContainer _x, backpackContainer _x]}
}) >= 0
