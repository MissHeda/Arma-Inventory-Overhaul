#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Op "kitMove": what a tile of one kit stands for into another kit, both under the phase's root, at
 * their authority - both written in the same frame, on one machine. The target is asked first, against
 * what it holds now (fnc_canPack): turned down, nothing moves and the op says why in that mod's words.
 * Then out of the first kit, all or nothing (fnc_takeFromKit, else "Gone"), into the second
 * (fnc_putIntoKit) - turned down after all (the tile held more than the window saw), it goes back into
 * the first; should that fail too, it is handed on, "Bounced", and settled. Magazines keep their
 * rounds. An emptied first kit goes when its type says so (fnc_removeIfEmpty).
 *
 * Arguments:
 * 0: Args, [kit holder it comes from, kit holder it goes to (each "kit:" + lowercase class), entry
 *    array (aio_storage_fnc_entryToArray), how many - -1 for the whole tile, cell [col, row,
 *    compartment, w, h] in the second kit - [] for the first free one] <ARRAY>
 * 1: Context - "requester", "where", "txId", "root", "settlement" (aio_storage_fnc_execute) <HASHMAP>
 *
 * Return Value:
 * [status, produced, extra] <ARRAY>
 *   status   - "" moved; "Gone", "Moved" (a kit no longer under the root), "Failed", "Bounced", or
 *              why the target turned it down in words
 *   produced - [payload] when it bounced, else []
 *   extra    - [landed cell [col, row, compartment, w, h] or [], put elsewhere than asked BOOL, why the
 *              target turned it down - "" when it did not]
 *
 * Example:
 * [["kit:efak_ifak_7", "kit:efak_mfak_2", _entryArray, -1, []], _context] call aio_compat_efak_fnc_opKitMove;
 *
 * Public: No
 */

params [["_args", [], [[]]], ["_context", createHashMap, [createHashMap]]];

_args params [
    ["_fromHolder", "", [""]], ["_toHolder", "", [""]], ["_entryArray", [], [[]]], ["_count", -1, [0]],
    ["_cell", [], [[]]]
];

if (
    (_fromHolder select [0, 4]) isNotEqualTo "kit:" || {(_toHolder select [0, 4]) isNotEqualTo "kit:"}
    || {_fromHolder isEqualTo _toHolder} || {_entryArray isEqualTo []}
) exitWith {["Failed", [], []]};

// That mod's contents are one table for every machine, tied to no place: only kits that lie under this
// phase's root are this machine's to write.
private _root = _context getOrDefault ["root", objNull];

if (!([_fromHolder, _root] call FUNC(holderVerify)) || {!([_toHolder, _root] call FUNC(holderVerify))}) exitWith {
    ["Moved", [], []]
};

private _fromKit = _fromHolder select [4];
private _toKit = _toHolder select [4];
private _entry = [_entryArray] call EFUNC(storage,entryFromArray);

// Asked before anything leaves: a refusal changes nothing, not even where the tile lay.
private _n = [_count, _entry getOrDefault ["count", 1]] select (_count < 1);

([_toKit, _entry getOrDefault ["class", ""], _n, _entry getOrDefault ["ammo", -1]] call FUNC(canPack)) params ["_ok", "_why"];

if (!_ok) exitWith {[_why, [], [[], false, _why]]};

([_fromKit, _entry, _count] call FUNC(takeFromKit)) params ["_status", "_payload", "_note"];

if (_status isNotEqualTo "") exitWith {[_status, [], []]};

([_toKit, _payload, _cell] call FUNC(putIntoKit)) params ["_refused", "_landed", "_elsewhere"];

if (_refused isEqualTo "") exitWith {
    ["in", _note] call EFUNC(storage,journalNote);
    [_fromKit, _context getOrDefault ["root", objNull]] call FUNC(removeIfEmpty);

    ["", [], [_landed, _elsewhere, ""]]
};

// Turned down after all: back where it came from, on the first free cell there.
if ((([_fromKit, _payload, []] call FUNC(putIntoKit)) select 0) isEqualTo "") exitWith {
    ["in", _note] call EFUNC(storage,journalNote);

    [_refused, [], [[], false, _refused]]
};

["Bounced", [+_payload], [[], false, _refused]]
