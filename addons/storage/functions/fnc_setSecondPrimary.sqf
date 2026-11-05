#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Puts a weapon on a unit's back as its second primary, or takes the one there away - the way WebKnight's or KJW's
 * Two Primary Weapons does it itself (GVAR(secondPrimaryMod), the compat addon of the mod that is loaded): that
 * mod's variables, the holder it hangs on the soldier, and with KJW's the weight it adds to ACE's load. That mod's
 * own key then switches to it as to one it put there.
 *
 * Whatever was on the back before is gone afterwards: a caller that wants it takes it off first
 * (fnc_takeOff). Checked afterwards: the answer says whether the back now holds what was asked.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Weapon, [class, muzzle, rail, optic, [magazine, rounds] or [], [second magazine, rounds] or [], bipod], or []
 *    to leave the back empty <ARRAY>
 *
 * Return Value:
 * The back holds it now - or is empty, for [] <BOOL>
 *
 * Example:
 * [player, ["arifle_MX_F", "", "", "optic_Aco", ["30Rnd_65x39_caseless_mag", 30], [], ""]] call aio_storage_fnc_setSecondPrimary;
 *
 * Public: Yes
 */

params [["_unit", objNull, [objNull]], ["_weapon", [], [[]]]];

private _set = GVAR(secondPrimaryMod) getOrDefault ["set", {}];

if (isNull _unit || {_set isEqualTo {}} || {!(([_unit] call FUNC(secondPrimary)) select 0)}) exitWith {false};

if (_weapon isNotEqualTo []) then {
    _weapon = [_weapon] call FUNC(normalizeWeapon);
};

[_unit, +_weapon] call _set;

private _now = ([_unit] call FUNC(secondPrimary)) select 1;

if (_weapon isEqualTo []) exitWith {_now isEqualTo []};

toLowerANSI (_now param [0, ""]) isEqualTo toLowerANSI (_weapon select 0)
