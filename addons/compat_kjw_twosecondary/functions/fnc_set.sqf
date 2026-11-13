#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Holsters a handgun as KJW's Two Secondary Weapons' second one, or takes the one there away - the way that mod's
 * own fnc_addSecondWeapon does it: the variable of the handgun not in the hands, then its holders hung on the player
 * again (its fnc_updateShownWeapon). The player alone - that mod works for no one else.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Weapon as weaponsItems gives it, or [] <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player, ["hgun_P07_F", "", "", "", ["16Rnd_9x21_Mag", 16], [], ""]] call aio_compat_kjw_twosecondary_fnc_set;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_weapon", [], [[]]]];

if (isNull _unit || {_unit isNotEqualTo player}) exitWith {};

private _equipped = _unit getVariable ["KJW_TwoSecondaryWeapons_secondSecondaryEquipped", false];

_unit setVariable [
    ["KJW_TwoSecondaryWeapons_secondSecondaryInfo", "KJW_TwoSecondaryWeapons_primarySecondaryInfo"] select (_equipped isEqualTo true),
    _weapon,
    true
];

if (isNil "KJW_TwoSecondaryWeapons_fnc_updateShownWeapon") exitWith {
    WARNING("KJW_TwoSecondaryWeapons_fnc_updateShownWeapon is missing - the second handgun is not shown.");
};

// Hung on only outside a vehicle, as that mod does it (its GetOutMan handler hangs it on again).
if (isNull objectParent _unit) then {
    call KJW_TwoSecondaryWeapons_fnc_updateShownWeapon;
};
