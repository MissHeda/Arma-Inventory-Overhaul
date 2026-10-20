#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Writes a payload into a kit once it has left wherever it was - out of a container, off a slot, out of
 * another kit. Only inside a kit op, on the machine where the kit's root is local (fnc_opKitPut,
 * fnc_opKitMove, and settlement putting a payload back into the kit it came out of): every write of one
 * kit through the window happens there, one after the other.
 *
 * The kit is asked against what it holds now (fnc_canPack: that mod's capacity, or the free cells of a
 * grid a rule or its config gives the kit, fnc_roomMode). A weapon goes into no kit, a uniform, vest
 * or backpack only empty - the kit keeps only its class -, a magazine only with rounds left
 * (fnc_changeKit). What it turns away has left its place already: the op hands it on ("Bounced") and
 * the storage settles it - back where it came from, else into the vehicle or onto the ground.
 *
 * Where it lands: on the cell asked for when that is free in the kit as it lies now; taken, the kit's
 * layout gives it the first free spot - "put elsewhere". Its record goes there at once
 * (einv_storage_fnc_setPlace), so the phase writes the kit's places with the kit. Put onto a pile of its
 * kind that takes it, it joins that pile where it lies: only a tile the kit did not have before gets a
 * record of its own, so nothing else in the kit moves.
 *
 * Arguments:
 * 0: Kit class <STRING>
 * 1: Payload, see einv_storage_fnc_removeEntry <ARRAY>
 * 2: Cell [col, row, compartment, w, h, rot] in the kit's grid (rot 1 turned a quarter clockwise; left
 *    out, by its size), [] to let its layout find one <ARRAY>
 *    (default: [])
 *
 * Return Value:
 * [why not - "" when written, else "Failed" or a reason in words, the cell it landed on [col, row,
 *  compartment, w, h, rot] - [] when unknown, put elsewhere than asked] <ARRAY>
 *
 * Example:
 * ["efak_ifak_7", ["item", "ACE_fieldDressing", 3, []], [2, 0, 0, 1, 1]] call einv_compat_efak_fnc_putIntoKit;
 *
 * Public: No
 */

params [["_kit", "", [""]], ["_payload", [], [[]]], ["_cell", [], [[]]]];

// A weapon goes into no kit.
if (_kit isEqualTo "" || {_payload isEqualTo []} || {!((_payload select 0) in ["item", "magazine", "backpack"])}) exitWith {
    ["Failed", [], false]
};

_payload params ["_kind", ["_class", "", [""]]];

private _rounds = [[], _payload param [2, []]] select (_kind isEqualTo "magazine");

private _n = switch (_kind) do {
    case "magazine": {count _rounds};
    case "item": {_payload param [2, 0]};
    default {1};
};

// What a uniform, vest or backpack held - [] or an empty one's snapshot when nothing. Only its first
// five parts are cargo (einv_storage_fnc_snapshot): what follows - its places, its tag - goes with it.
private _inner = switch (_kind) do {
    case "item": {_payload param [3, []]};
    case "backpack": {_payload param [2, []]};
    default {[]};
};

if (_inner isNotEqualTo [] && {(_inner select [0, 5]) isNotEqualTo [[[], []], [], [], [[], []], []]}) exitWith {
    [LLSTRING(EmptyFirst), [], false]
};

if (_class isEqualTo "" || {_n < 1}) exitWith {["Failed", [], false]};

([_kit, _class, _n, _rounds] call FUNC(canPack)) params ["_ok", "_why"];

if (!_ok) exitWith {[_why, [], false]};

// The kit as it lies before: is the cell asked for free, and how many tiles of its kind there are.
private _kitKey = "kit:" + toLowerANSI _kit;

// The key its tiles have in the kit (fnc_getEntries): an empty uniform, vest or backpack lies there as its class
// alone - the payload's key would carry the id of a container the kit does not keep, match no tile, and the
// cell asked for would be lost.
private _key = [createHashMapFromArray [
    ["class", _class], ["ammo", _rounds param [0, 0]], ["capacity", ([_class] call EFUNC(items,getInfo)) getOrDefault ["capacity", 0]]
]] call EFUNC(storage,entryKey);
private _view = [_kit, true] call FUNC(getEntries);
private _before = {(_x getOrDefault ["key", ""]) isEqualTo _key} count _view;
private _spot = [];
private _elsewhere = false;

if (_cell isNotEqualTo []) then {
    (([_class] call EFUNC(items,getInfo)) getOrDefault ["size", [1, 1]]) params [["_sizeW", 1], ["_sizeH", 1]];
    _cell params [["_col", -1, [0]], ["_row", -1, [0]], ["_block", 0, [0]], ["_w", _sizeW, [0]], ["_h", _sizeH, [0]], ["_rot", -1, [0]]];

    // Upright or turned a quarter clockwise (R while dragging; rot 1, else by its size) - never another
    // size.
    if !(_rot in [0, 1]) then {
        _rot = parseNumber (_w != _sizeW);
    };

    if (([[_sizeW, _sizeH], [_sizeH, _sizeW]] select (_rot == 1)) isNotEqualTo [_w, _h]) then {
        _w = _sizeW;
        _h = _sizeH;
        _rot = 0;
    };

    // Inside the compartment it names - the kit's own grid's, or its one open compartment, STORAGE_COLS
    // wide and as long as it needs - and free. A shaped item takes only its own cells, as it lies
    // (fnc_cellFree).
    if ([_kit, _view, [_col, _row, _block, _w, _h], ([_class, _rot] call EFUNC(items,footprintAs)) select 2] call FUNC(cellFree)) then {
        _spot = [_col, _row, _block, _w, _h, _rot];
    } else {
        _elsewhere = true;
    };
};

if !([_kit, _class, _n, _rounds] call FUNC(changeKit)) exitWith {[LLSTRING(EmptyMagazine), [], false]};

// What this execution read of the kit is out of date now (einv_storage_fnc_findEntry).
EGVAR(storage,cache) deleteAt _kitKey;

private _after = [_kit, true] call FUNC(getEntries);
private _mine = _after select {(_x getOrDefault ["key", ""]) isEqualTo _key};
private _landed = [];

if (count _mine > _before) then {
    // A tile of its own. Without a free cell asked for, where the kit's layout put it - the one of its
    // kind on a cell none of its kind held before, as the tiles that were there keep theirs. Its record
    // there either way: what every window shows, kept from now on.
    if (_spot isEqualTo []) then {
        private _held = (_view select {(_x getOrDefault ["key", ""]) isEqualTo _key}) apply {[_x get "col", _x get "row", _x getOrDefault ["block", -1]]};
        private _index = _mine findIf {
            !(_x getOrDefault ["overflow", false]) && {!([_x get "col", _x get "row", _x getOrDefault ["block", -1]] in _held)}
        };

        if (_index >= 0) then {
            private _tile = _mine select _index;

            _spot = [_tile get "col", _tile get "row", _tile getOrDefault ["block", 0], _tile get "w", _tile get "h", parseNumber (_tile getOrDefault ["rotated", false])];
        };
    };

    if (_spot isNotEqualTo []) then {
        [_kitKey, createHashMapFromArray [
            ["class", _class], ["count", _n], ["ammo", _rounds param [0, 0]], ["key", _key],
            ["w", _spot select 3], ["h", _spot select 4]
        ], _spot, true] call EFUNC(storage,setPlace);

        _landed = _spot;
    };
} else {
    // Onto a pile of its kind, where that lies.
    _elsewhere = false;

    if (_mine isNotEqualTo []) then {
        private _tile = _mine select 0;

        _landed = [_tile get "col", _tile get "row", _tile getOrDefault ["block", 0], _tile get "w", _tile get "h", parseNumber (_tile getOrDefault ["rotated", false])];
    };
};

["", _landed, _elsewhere]
