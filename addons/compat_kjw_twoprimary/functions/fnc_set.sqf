#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Puts a weapon on the player's back the way KJW's Two Primary Weapons does (its fnc_addSecondWeapon): into that
 * mod's variable of the weapon not in the hands (see fnc_get), for everyone, and its holders on the back made anew
 * by that mod's own fnc_updateShownWeapon - which also moves the weight it adds to ACE's load. [] leaves the back
 * empty: the variable [], no holder.
 *
 * Seated in a vehicle, that mod shows no holders and makes them when the player gets out (its "GetOutMan"
 * handler); so does its function here.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Weapon as weaponsItems gives it, or [] <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player, ["arifle_MX_F", "", "", "", ["30Rnd_65x39_caseless_mag", 30], [], ""]] call aio_compat_kjw_twoprimary_fnc_set;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_weapon", [], [[]]]];

if (isNull _unit || {_unit isNotEqualTo player}) exitWith {};

private _equipped = _unit getVariable ["KJW_TwoPrimaryWeapons_secondPrimaryEquipped", false];

_unit setVariable [
    ["KJW_TwoPrimaryWeapons_secondPrimaryInfo", "KJW_TwoPrimaryWeapons_primaryPrimaryInfo"] select (_equipped isEqualTo true),
    _weapon,
    true
];

if (isNil "KJW_TwoPrimaryWeapons_fnc_updateShownWeapon") exitWith {
    WARNING("KJW_TwoPrimaryWeapons_fnc_updateShownWeapon is missing - the weapon on the back is not shown.");
};

call KJW_TwoPrimaryWeapons_fnc_updateShownWeapon;
