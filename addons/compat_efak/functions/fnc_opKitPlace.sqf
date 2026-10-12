#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Op "kitPlace": a tile moved within a kit's grid, at the kit's authority - only where it lies
 * changes, Enhanced First Aid Kits' contents stay as they are. The tile has to lie where the window saw
 * it (else "Gone"), the cell has to be free but for the tile itself in the kit as it lies now (else
 * "Taken" - somebody put something there meanwhile, and nothing moves). Upright or turned a quarter (R
 * while dragging).
 *
 * Arguments:
 * 0: Args, [kit holder "kit:" + lowercase class, entry array (einv_storage_fnc_entryToArray), cell
 *    [col, row, compartment, w, h]] <ARRAY>
 * 1: Context - "requester", "where", "txId", "root", "settlement" (einv_storage_fnc_execute) <HASHMAP>
 *
 * Return Value:
 * [status, produced, extra] <ARRAY>
 *   status   - "" moved; "Gone", "Taken", "Moved" (no longer under the root) or "Failed"
 *   produced - [] (nothing leaves the kit)
 *   extra    - [the cell [col, row, compartment, w, h] it lies on now] when moved, else []
 *
 * Example:
 * [["kit:efak_ifak_7", _entryArray, [2, 0, 0, 1, 1]], _context] call einv_compat_efak_fnc_opKitPlace;
 *
 * Public: No
 */

params [["_args", [], [[]]], ["_context", createHashMap, [createHashMap]]];
_args params [["_holder", "", [""]], ["_entryArray", [], [[]]], ["_cell", [], [[]]]];

if ((_holder select [0, 4]) isNotEqualTo "kit:" || {_entryArray isEqualTo []} || {_cell isEqualTo []}) exitWith {
    ["Failed", [], []]
};

// Only a kit that lies under this phase's root is this machine's to write - its places as well.
if !([_holder, _context getOrDefault ["root", objNull]] call FUNC(holderVerify)) exitWith {["Moved", [], []]};

private _kit = _holder select [4];
private _entry = [_entryArray] call EFUNC(storage,entryFromArray);
private _class = _entry getOrDefault ["class", ""];
private _key = _entry getOrDefault ["key", [_entry] call EFUNC(storage,entryKey)];
private _view = [_kit, true] call FUNC(getEntries);

// Exactly the tile the window moved, where it saw it.
private _index = _view findIf {
    (_x getOrDefault ["key", ""]) isEqualTo _key
    && {(_x getOrDefault ["class", ""]) == _class}
    && {(_x getOrDefault ["block", -1]) == (_entry getOrDefault ["block", 0])}
    && {(_x getOrDefault ["col", -1]) == (_entry getOrDefault ["col", -1])}
    && {(_x getOrDefault ["row", -1]) == (_entry getOrDefault ["row", -1])}
};

if (_index < 0) exitWith {["Gone", [], []]};

private _tile = _view select _index;

(([_class] call EFUNC(items,getInfo)) getOrDefault ["size", [1, 1]]) params [["_sizeW", 1], ["_sizeH", 1]];

_cell params [
    ["_col", -1, [0]], ["_row", -1, [0]], ["_block", 0, [0]],
    ["_w", _tile getOrDefault ["w", _sizeW], [0]], ["_h", _tile getOrDefault ["h", _sizeH], [0]]
];

// Upright or turned a quarter - never another size.
if !([_w, _h] in [[_sizeW, _sizeH], [_sizeH, _sizeW]]) then {
    _w = _sizeW;
    _h = _sizeH;
};

// A kit's grid is one open compartment, STORAGE_COLS wide and as long as it needs; the tile itself
// does not count against its new cell.
private _free = _block == 0 && {_col >= 0} && {_row >= 0} && {_col + _w <= STORAGE_COLS};

if (_free) then {
    {
        if (
            _forEachIndex != _index
            && {(_x getOrDefault ["block", -1]) == 0}
            && {(_x get "col") < _col + _w} && {_col < (_x get "col") + (_x get "w")}
            && {(_x get "row") < _row + _h} && {_row < (_x get "row") + (_x get "h")}
        ) exitWith {
            _free = false;
        };
    } forEach _view;
};

if (!_free) exitWith {["Taken", [], []]};

private _kitKey = "kit:" + toLowerANSI _kit;

[_kitKey, _tile, [_col, _row, 0, _w, _h]] call EFUNC(storage,setPlace);

// What this execution read of the kit is out of date now (einv_storage_fnc_findEntry).
EGVAR(storage,cache) deleteAt _kitKey;

["", [], [[_col, _row, 0, _w, _h]]]
