#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Op "split": part of a stack of a class that stacks becomes a stack of its own, within one holder. The tile
 * the entry names gives up that many (its record's count goes down, fnc_setCount) and they are laid down as
 * a new tile - on the cell when it is free, else, and with no cell, on the free spot nearest to the source
 * tile (its compartment first, then the others; upright, then turned a quarter, fnc_findSpots). No free
 * spot: "NoRoom" and nothing changes. The cargo is not touched at all: it is a change of the records only,
 * written with the rest of the phase, and the execution's view follows.
 *
 * Only a tile that has a record and holds more than the count asked for: "Gone" when it is not there or
 * holds fewer, "Failed" for a tile that cannot be split (a class that does not stack, a tile of the hidden
 * holder, one in the overflow row, or the whole of it - that is a plain move).
 *
 * Extra: [landed cell [col, row, block, w, h, rot], elsewhere] - elsewhere: the cell asked for was not free
 * and the nearest one was taken.
 *
 * Arguments:
 * 0: Args, [holder, entry array (fnc_entryToArray) of the tile, how many to split off, cell (default: [])]
 *    <ARRAY>
 * 1: Context - "requester", "where", "txId", "root", "settlement" (einv_storage_fnc_execute) <HASHMAP>
 *
 * Return Value:
 * [status, produced, extra] <ARRAY>
 *   status - "" done, else why not ("Gone", "NoRoom", "Moved", "Failed", a guard's reason or a reason
 *     already in words)
 *   produced - always [], nothing leaves the holder
 *   extra - what else it tells, [] for nothing
 *
 * Example:
 * [[_crate, _entryArray, 5, []], _context] call einv_storage_fnc_opSplit;
 *
 * Public: No
 */

params [["_args", [], [[]]], ["_context", createHashMap, [createHashMap]]];

_args params [
    ["_holder", objNull, [objNull, ""]],
    ["_entryArray", [], [[]]],
    ["_count", 1, [0]],
    ["_cell", [], [[]]]
];

// A holder of another type has no stacks apart (GVAR(holderTypes) names no "split" for it).
if (_holder isEqualType "") exitWith {["Failed", [], []]};
if (isNull _holder) exitWith {["Moved", [], []]};

private _view = [_holder, []] call FUNC(findEntry);

if (count _view == 0) exitWith {["Moved", [], []]};

private _entry = [_holder, _entryArray] call FUNC(findEntry);

if (count _entry == 0) exitWith {["Gone", [], []]};

private _have = _entry getOrDefault ["count", 1];
private _class = _entry getOrDefault ["class", ""];

if (_count > _have) exitWith {["Gone", [], []]};

if (
    _count < 1 || {_count >= _have}
    || {(([_class] call EFUNC(items,getInfo)) getOrDefault ["stack", 1]) <= 1}
    || {_entry getOrDefault ["strict", false]} || {_entry getOrDefault ["overflow", false]}
    || {(_entry getOrDefault ["attachments", []]) isNotEqualTo []} || {!isNull (_entry getOrDefault ["container", objNull])}
) exitWith {["Failed", [], []]};

// Where it goes: the cell asked for, else the free spot nearest to the tile it comes from.
private _origin = [_entry getOrDefault ["col", 0], _entry getOrDefault ["row", 0], _entry getOrDefault ["block", 0]];

([_view, _class, _cell, 1, _origin] call FUNC(findSpots)) params ["_spots", "_elsewhere"];

private _spot = _spots param [0, []];

if (_spot isEqualTo []) exitWith {["NoRoom", [], []]};

// The source gives up its items, and the new tile has them - the record goes last of its key, so it is the
// last tile of the class. The record the tile is found by is the one it has now (fnc_setCount).
if !([_holder, _entry, _have - _count] call FUNC(setCount)) exitWith {["Failed", [], []]};

private _key = _entry getOrDefault ["key", ""];

[_holder, createHashMapFromArray [
    ["class", _class], ["key", _key], ["w", _spot select 3], ["h", _spot select 4], ["count", _count]
], _spot, true] call FUNC(setPlace);

_entry set ["count", _have - _count];

private _footprint = [_class, _spot select 5] call EFUNC(items,footprintAs);
private _spotHoles = _spot param [6, _footprint select 2];
private _spotSingle = (((_view getOrDefault ["blocks", []]) param [_spot select 2, []]) param [5, false]);

(_view getOrDefault ["entries", []]) pushBack createHashMapFromArray [
    ["class", _class],
    ["key", _key],
    ["count", _count],
    ["ammo", _entry getOrDefault ["ammo", 0]],
    ["capacity", _entry getOrDefault ["capacity", 0]],
    ["attachments", []],
    ["container", objNull],
    ["strict", false],
    ["block", _spot select 2],
    ["col", _spot select 0],
    ["row", _spot select 1],
    ["w", _spot select 3],
    ["h", _spot select 4],
    ["rotated", (_spot select 5) == 1],
    ["holes", _spotHoles],
    ["single", _spotSingle],
    ["overflow", false]
];

["", [], [_spot, _elsewhere]]
