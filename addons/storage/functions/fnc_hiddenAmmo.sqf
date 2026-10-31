#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The rounds a hidden holder's entry keeps for a class (fnc_hiddenLists): the rounds given for a magazine
 * or grenade (never below 0), -1 for anything else - an item has no rounds, and its entries are told apart
 * by class alone.
 *
 * Arguments:
 * 0: Class <STRING>
 * 1: Rounds, as a tile or payload has them <NUMBER> (default: 0)
 *
 * Return Value:
 * Rounds, or -1 <NUMBER>
 *
 * Example:
 * ["30Rnd_65x39_caseless_mag", 17] call aio_storage_fnc_hiddenAmmo;
 *
 * Public: No
 */

params [["_class", "", [""]], ["_ammo", 0, [0]]];

if (_class isEqualTo "" || {!isClass (configFile >> "CfgMagazines" >> _class)}) exitWith {-1};

_ammo max 0
