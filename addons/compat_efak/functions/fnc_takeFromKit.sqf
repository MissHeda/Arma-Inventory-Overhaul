#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Takes what a tile of a kit stands for out of the kit and hands it on as a payload the storage puts
 * anywhere (fnc_payloadFor) - each magazine with the rounds the kit kept for it (fnc_takeRounds). Only
 * inside a kit op, on the machine where the kit's root is local (fnc_opKitTake, fnc_opKitMove): every
 * write of one kit through the window happens there, one after the other, so two players can never
 * both take the last one.
 *
 * The tile is looked for in the kit as it lies now (fnc_getEntries, laid out): the one with that key on
 * that cell, else the first with that key - identical items are the same item. It has to hold as many
 * as are asked for, and the kit as many with those rounds, else "Gone": all or nothing. Read and
 * written in the same frame. A whole tile's record leaves the kit's places, so nothing else in the kit
 * moves up into its cell (aio_storage_fnc_setPlace); the payload is noted in the phase's journal the
 * moment it left (aio_storage_fnc_journalNote). Whether an emptied kit goes is the op's business
 * (fnc_removeIfEmpty).
 *
 * Arguments:
 * 0: Kit class <STRING>
 * 1: Entry - the tile as the window saw it (aio_storage_fnc_entryFromArray) <HASHMAP>
 * 2: How many of it, -1 for the whole tile as it lies now <NUMBER> (default: -1)
 *
 * Return Value:
 * [status - "" when taken, else "Gone" or why not in words, payload - [] for none, its index in the
 *  journal] <ARRAY>
 *
 * Example:
 * ["efak_ifak_7", _entry, 1] call aio_compat_efak_fnc_takeFromKit;
 *
 * Public: No
 */

params [["_kit", "", [""]], ["_entry", createHashMap, [createHashMap]], ["_count", -1, [0]]];

private _class = _entry getOrDefault ["class", ""];

if (_kit isEqualTo "" || {_class isEqualTo ""}) exitWith {["Failed", [], -1]};

// Before that mod's table reached this machine every kit looks empty.
private _wait = call FUNC(notReady);

if (_wait isNotEqualTo "") exitWith {[_wait, [], -1]};

private _kitKey = "kit:" + toLowerANSI _kit;
private _key = _entry getOrDefault ["key", [_entry] call EFUNC(storage,entryKey)];
private _view = [_kit, true] call FUNC(getEntries);

private _fnc_same = {
    (_x getOrDefault ["key", ""]) isEqualTo _key && {(_x getOrDefault ["class", ""]) == _class}
};

// On its cell first, else the first of its kind anywhere in the kit.
private _index = _view findIf {
    call _fnc_same
    && {(_x getOrDefault ["block", -1]) == (_entry getOrDefault ["block", 0])}
    && {(_x getOrDefault ["col", -1]) == (_entry getOrDefault ["col", -1])}
    && {(_x getOrDefault ["row", -1]) == (_entry getOrDefault ["row", -1])}
};

if (_index < 0) then {
    _index = _view findIf _fnc_same;
};

if (_index < 0) exitWith {["Gone", [], -1]};

private _tile = _view select _index;
private _have = _tile getOrDefault ["count", 1];
private _n = [_count, _have] select (_count < 1);

if (_have < _n) exitWith {["Gone", [], -1]};

([_kit, _class, _n, _tile getOrDefault ["ammo", 0]] call FUNC(takeRounds)) params ["_ok", "_rounds"];

if (!_ok) exitWith {["Gone", [], -1]};

private _payload = [_class, _n, _rounds] call FUNC(payloadFor);

if !([_kit, _class, -_n, _rounds] call FUNC(changeKit)) exitWith {["Gone", [], -1]};

// Noted the moment it left: should anything after this stop the phase, the journal still hands it on
// (aio_storage_fnc_phaseFinalize).
private _note = ["out", +_payload] call EFUNC(storage,journalNote);

// Found by where the tile lies - which is where it lay until now.
if (_n >= _have) then {
    [_kitKey, _tile, []] call EFUNC(storage,setPlace);
};

// What this execution read of the kit is out of date now (aio_storage_fnc_findEntry).
EGVAR(storage,cache) deleteAt _kitKey;

["", _payload, _note]
