#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * A hidden holder's entry as a payload fnc_addPayload puts into a container: ["magazine", class, [rounds,
 * ...]] for a magazine or grenade - one rounds number per piece -, ["item", class, count, []] for anything
 * else (rounds -1, fnc_hiddenAmmo).
 *
 * Arguments:
 * 0: Class <STRING>
 * 1: Count <NUMBER> (default: 1)
 * 2: Rounds, -1 for an item <NUMBER> (default: -1)
 *
 * Return Value:
 * Payload <ARRAY>
 *
 * Example:
 * ["HandGrenade", 2, 1] call einv_storage_fnc_hiddenPayload;
 *
 * Public: No
 */

params [["_class", "", [""]], ["_count", 1, [0]], ["_ammo", -1, [0]]];

_count = _count max 1;

if (_ammo < 0) exitWith {["item", _class, _count, []]};

private _rounds = [];

for "_i" from 1 to _count do {
    _rounds pushBack _ammo;
};

["magazine", _class, _rounds]
