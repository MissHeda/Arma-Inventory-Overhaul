#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Antistasi Ultimate's SCRT_fnc_loot_gatherLoot ("Loot around", run on the server), with the piles of this mod
 * taken in: that mod's own file, read from its addon and compiled once with GroundWeaponHolder_Scripted added to
 * the classes it loots - the piles everything this mod puts on the ground lies in (aio_storage_fnc_getGroundHolder).
 * The rest is that mod's, as it ships; should its line ever read differently, it runs unchanged and the RPT says so.
 *
 * Arguments:
 * As SCRT_fnc_loot_gatherLoot: [vehicle, radius, override position]
 *
 * Return Value:
 * As SCRT_fnc_loot_gatherLoot
 *
 * Public: No
 */

if (isNil QGVAR(gather)) then {
    private _source = preprocessFileLineNumbers "\x\A3A\addons\scrt\Loot\fn_loot_gatherLoot.sqf";
    private _classes = """WeaponHolderSimulated"", ""GroundWeaponHolder"", ""WeaponHolder""";
    private _at = _source find _classes;

    if (_at < 0) then {
        WARNING("Antistasi's Loot around reads differently - it runs as it ships and passes over this mod's piles.");
    } else {
        _source = (_source select [0, _at]) + _classes + ", ""GroundWeaponHolder_Scripted""" + (_source select [_at + count _classes]);
    };

    GVAR(gather) = compile _source;
};

_this call GVAR(gather)
