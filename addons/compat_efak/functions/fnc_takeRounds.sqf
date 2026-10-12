#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The rounds of each magazine that would leave a kit for a tile of it: for a magazine of several
 * rounds what the kit keeps for it (efak_core_fnc_pickCharges) - full ones for a full tile, those of
 * the tile's fill for an opened one; a magazine of one round - a grenade - carries that round; anything
 * else has none.
 *
 * Arguments:
 * 0: Kit class <STRING>
 * 1: Item class <STRING>
 * 2: How many <NUMBER>
 * 3: The tile's rounds <NUMBER> (default: 0)
 *
 * Return Value:
 * [the kit holds them all, rounds of each] <ARRAY>
 *
 * Example:
 * ["efak_IFAK_7", "ACE_painkillers", 1, 7] call einv_compat_efak_fnc_takeRounds;
 *
 * Public: No
 */

params [["_kit", "", [""]], ["_class", "", [""]], ["_count", 1, [0]], ["_ammo", 0, [0]]];

private _size = [_class] call EFAKFUNC(core,getMagazineSize);

if (_size > 1) exitWith {
    // That mod's "which": 0 full ones only, more than 0 only opened ones of that fill.
    private _which = [_ammo, 0] select (_ammo <= 0 || {_ammo >= _size});
    private _rounds = [_kit, _class, _count, _which] call EFAKFUNC(core,pickCharges);

    [count _rounds == _count, _rounds]
};

if (isClass (configFile >> "CfgMagazines" >> _class)) exitWith {
    private _rounds = [];

    for "_i" from 1 to _count do {
        _rounds pushBack (_size max 1);
    };

    [true, _rounds]
};

[true, []]
