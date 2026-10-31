#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Notes that a magazine is being put into a weapon by hand - the window's drag onto the weapon or its magazine
 * slot, "Load into", the direct load of fnc_loadMagazine (all through fnc_weaponPart). It is a chosen
 * magazine: the "Use items from ..." settings are about using items in the field (R, the hotbar, ACE's
 * actions), not about handling the gear on purpose, so a "Reloaded" event the command may raise is no reload to
 * take back (fnc_onReloaded asks). The note runs out after HAND_LOAD_WINDOW seconds, is cleared by the first
 * event it answers and by anything that empties a magazine slot (fnc_takeOff), so none is left behind.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Weapon <STRING> (default: "" - clears the note)
 * 2: Magazine class <STRING> (default: "")
 *
 * Return Value:
 * None
 *
 * Example:
 * [player, primaryWeapon player, "30Rnd_65x39_caseless_mag"] call aio_storage_fnc_noteHandLoad;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_weapon", "", [""]], ["_class", "", [""]]];

if (_weapon isEqualTo "" || {_class isEqualTo ""} || {isNull _unit}) exitWith {
    GVAR(handLoad) = [];
};

GVAR(handLoad) = [_unit, toLowerANSI _weapon, toLowerANSI _class, diag_tickTime + HAND_LOAD_WINDOW];
