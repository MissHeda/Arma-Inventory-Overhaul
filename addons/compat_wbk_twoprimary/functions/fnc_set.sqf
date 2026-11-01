#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Puts a weapon on a unit's back the way WebKnight's Two Primary Weapons does (its WBK_CreateWeaponSecond, without
 * the animation and the weapon taken from the hands): a box of its own (DummyWeapon_Wbk) holding the weapon, hung on
 * the soldier where that mod's setting says (WBK_AdjustGunPos), and the variable WBK_SecondWeapon, [box, weapon],
 * for everyone. The box there before goes. [] leaves the back empty, the variable gone, as that mod's switch
 * leaves it.
 *
 * Seated in a vehicle, that mod keeps the weapon without a box - it hangs one on again when the soldier gets out
 * (its "GetOutMan" handler) -, and so is it done here.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Weapon as weaponsItems gives it, or [] <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player, ["arifle_MX_F", "", "", "", ["30Rnd_65x39_caseless_mag", 30], [], ""]] call aio_compat_wbk_twoprimary_fnc_set;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_weapon", [], [[]]]];

if (isNull _unit) exitWith {};

private _old = _unit getVariable "WBK_SecondWeapon";

if (!isNil "_old" && {_old isEqualType []}) then {
    private _box = _old param [0, objNull];

    if (_box isEqualType objNull && {!isNull _box}) then {
        deleteVehicle _box;
    };
};

if (_weapon isEqualTo []) exitWith {
    _unit setVariable ["WBK_SecondWeapon", nil, true];
};

if (!isNull objectParent _unit) exitWith {
    _unit setVariable ["WBK_SecondWeapon", [objNull, _weapon], true];
};

private _box = createVehicle ["DummyWeapon_Wbk", getPosATL _unit, [], 0, "CAN_COLLIDE"];

_box addWeaponWithAttachmentsCargoGlobal [_weapon, 1];
_unit setVariable ["WBK_SecondWeapon", [_box, _weapon], true];

// Where that mod's own setting hangs it: low at the pelvis, or high across the back ("Spine_normal", as its
// own key does it).
private _where = missionNamespace getVariable ["WBK_LocalParamWhereWeaponIs", "Pelvis"];

if (isNil "WBK_AdjustGunPos") exitWith {
    WARNING("WBK_AdjustGunPos is missing - the weapon on the back hangs where it was made.");
    _box attachTo [_unit, [-0.19, -0.17, -0.17], "Pelvis", true];
};

[_unit, _box, ["Spine_normal", "Pelvis"] select (_where == "Pelvis")] call WBK_AdjustGunPos;
