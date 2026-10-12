#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The armor an item gives to one hitpoint, as ACE's damage handling counts it - the number a comparison of
 * two vests should show, not the config's raw armor (a vest's armor above a limit is scaled down by how much
 * it lets through, so an explosive-resistant plate does not read as invincible).
 *
 * With ACE Medical's engine loaded, ACE answers (ace_medical_engine_fnc_getItemArmor, with its own cache).
 * Without it the same formula, copied: a uniform gives its unit's armor times the hitpoint's own, never
 * scaled; anything else gives the armor of the HitpointsProtectionInfo entry for the hitpoint, and above
 * 24 (headgear: 12) it is log (armor / pass-through) x 10 - for vests the pass-through counts at a power of
 * 0.6.
 *
 * Arguments:
 * 0: Item class <STRING>
 * 1: Hitpoint, "HitChest" and so on <STRING>
 *
 * Return Value:
 * Armor, 0 where the item does not cover the hitpoint <NUMBER>
 *
 * Example:
 * ["V_PlateCarrier1_rgr", "HitChest"] call einv_items_fnc_getArmor;
 *
 * Public: No
 */

params [["_item", "", [""]], ["_hitpoint", "", [""]]];

if (_item isEqualTo "" || {_hitpoint isEqualTo ""}) exitWith {0};

if (!isNil QACEFUNC(medical_engine,getItemArmor) && {!isNil QACEGVAR(medical_engine,armorCache)}) exitWith {
    [_item, _hitpoint] call ACEFUNC(medical_engine,getItemArmor)
};

private _info = configFile >> "CfgWeapons" >> _item >> "ItemInfo";
private _type = getNumber (_info >> "type");
private _armor = 0;
private _passThrough = 1;

if (_type == TYPE_UNIFORM) then {
    private _unit = configFile >> "CfgVehicles" >> getText (_info >> "uniformClass");
    private _entry = _unit >> "HitPoints" >> _hitpoint;

    _armor = getNumber (_unit >> "armor") * (1 max getNumber (_entry >> "armor"));
} else {
    private _entry = configProperties [_info >> "HitpointsProtectionInfo", "getText (_x >> 'hitpointName') == _hitpoint"] param [0, configNull];

    if (!isNull _entry) then {
        _armor = getNumber (_entry >> "armor");
        _passThrough = (0.1 max getNumber (_entry >> "passThrough")) min 1;
    };
};

// Armor over the limit is scaled by what gets through (ACE: fix for explosive-resistant plates).
private _step = [4, 2] select (_type == TYPE_HEADGEAR);

if (_type != TYPE_UNIFORM && {_armor > _step * 6}) then {
    private _effect = [1, 0.6] select (_type == TYPE_VEST);

    _armor = (log (_armor / (_passThrough ^ _effect))) * 10;
};

_armor
