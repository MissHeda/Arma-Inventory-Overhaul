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
 *    [col, row, compartment, w, h, rot] - rot 1 turned a quarter clockwise, left out as the tile lies]
 *    <ARRAY>
 * 1: Context - "requester", "where", "txId", "root", "settlement" (einv_storage_fnc_execute) <HASHMAP>
 *
 * Return Value:
 * [status, produced, extra] <ARRAY>
 *   status   - "" moved; "Gone", "Taken", "Moved" (no longer under the root) or "Failed"
 *   produced - [] (nothing leaves the kit)
 *   extra    - [the cell [col, row, compartment, w, h, rot] it lies on now] when moved, else []
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
    ["_w", _tile getOrDefault ["w", _sizeW], [0]], ["_h", _tile getOrDefault ["h", _sizeH], [0]], ["_rot", -1, [0]]
];

// Upright or turned a quarter clockwise (rot 1; without it as the tile lies while it keeps its size, else
// by the size) - never another size.
if !(_rot in [0, 1]) then {
    _rot = if ([_w, _h] isEqualTo [_tile getOrDefault ["w", _sizeW], _tile getOrDefault ["h", _sizeH]]) then {
        parseNumber (_tile getOrDefault ["rotated", false])
    } else {
        parseNumber (_w != _sizeW)
    };
};

if (([[_sizeW, _sizeH], [_sizeH, _sizeW]] select (_rot == 1)) isNotEqualTo [_w, _h]) then {
    _w = _sizeW;
    _h = _sizeH;
    _rot = 0;
};

// Inside the compartment it names - the kit's own grid's (a rule or its config gives it one), or its one
// open compartment, STORAGE_COLS wide and as long as it needs - and free; the tile itself does not count
// against its new cell. A shaped item takes only its own cells, as it lies (fnc_cellFree).
if !([_kit, _view, [_col, _row, _block, _w, _h], ([_class, _rot] call EFUNC(items,footprintAs)) select 2, _index] call FUNC(cellFree)) exitWith {
    ["Taken", [], []]
};

private _kitKey = "kit:" + toLowerANSI _kit;

[_kitKey, _tile, [_col, _row, _block, _w, _h, _rot]] call EFUNC(storage,setPlace);

// What this execution read of the kit is out of date now (einv_storage_fnc_findEntry).
EGVAR(storage,cache) deleteAt _kitKey;

["", [], [[_col, _row, _block, _w, _h, _rot]]]
