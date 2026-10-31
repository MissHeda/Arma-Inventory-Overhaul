#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The condition of "Change Ammo Type" in ACE's self interaction, the one this addon puts in place of AIME's:
 * what AIME asked (its own setting "Enable ammo switch menu" on, no UAV being flown, on foot or in a seat the
 * soldier shoots from) and a rifle, pistol or launcher in the hands - a binocular has no magazine to change.
 *
 * ACE asks it while its menu is open.
 *
 * Arguments:
 * 0: Target - the player <OBJECT>
 * 1: Player <OBJECT>
 *
 * Return Value:
 * Shown <BOOL>
 *
 * Example:
 * [ACE_player, ACE_player] call aio_compat_aime_fnc_ammoCondition;
 *
 * Public: No
 */

params [["_target", objNull, [objNull]], ["_player", objNull, [objNull]]];

// AIME's own setting, read as it left it: it is the player's choice and stays theirs.
if (!(missionNamespace getVariable [AIME_AMMO_SETTING, true])) exitWith {false};

// Flying a UAV: the gun in the hands is not the soldier's.
if (((UAVControl getConnectedUAV _player) param [1, ""]) isNotEqualTo "") exitWith {false};

private _weapon = currentWeapon _player;

if (_weapon isEqualTo "" || {([primaryWeapon _player, handgunWeapon _player, secondaryWeapon _player] find _weapon) < 0}) exitWith {false};

// On foot, or in a seat he can shoot from (AIME's own test, when its function is there).
vehicle _player isEqualTo _player
|| {!isNil "UPSL_aime_change_ammo_fnc_is_ffv" && {[_player, vehicle _player] call UPSL_aime_change_ammo_fnc_is_ffv}}
