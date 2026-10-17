#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Op "put": a payload into a holder - one an earlier op produced (a ref, filled in by the driver) or one
 * the transaction carries. A null holder or an empty ground pile: "Bounced" with all of it. A spot -
 * the cell when free, else the first fit ("elsewhere") - else "Bounced", and a backpack into a backpack
 * is "NoBackpack"; forced (settlement into the requester's vehicle) neither is asked and an overflow row
 * is fine. What did not arrive
 * (fnc_addPayload) is "Bounced" with the rest; the record at the spot, the nested places and tag
 * restored (fnc_addPayload). The execution's view of the holder follows (fnc_findEntry).
 *
 * Stacks. Of a class that stacks (items, grenades and the like), a payload either joins the tiles of its
 * key that have room - in their order, a tile filled before the next one is looked at - and what is left
 * opens new tiles (a full stack each, then the remainder), or, with "separate", is a tile of its own at the
 * cell asked for (cut into full tiles when it is more than a stack): it joins nothing. With "merge into"
 * the tile at that cell, when it is of the payload's key and has room, is filled first, then as without. Quick
 * move, Take all, Sort, the plan and settlement never ask for either and so keep filling partial stacks.
 * Only the tiles that open need a free spot; a payload that fits into the room of the tiles it joins needs
 * none. The counts live in the places' records (fnc_setCount, fnc_setPlace), changed here in step with the
 * cargo, so the stack that was chosen gains the items.
 *
 * Extra: [landed cell [col, row, block, w, h, rot] - [] in an overflow row; for a payload that only joined
 * a tile, that tile's [col, row, block] -, elsewhere]; when it bounced a third element says why: "Gone"
 * (nothing to put it into), "NoBackpack" (a backpack into a backpack), "NoRoom", "Failed" (the engine
 * took none of it).
 *
 * Checking only (args 4): nothing changes; the status is "" or that reason, the extra [spot, elsewhere,
 * merged] - spot the first new tile's, [] when none opens; merged: the whole payload joins tiles that
 * are there.
 *
 * Arguments:
 * 0: Args, [to, payload or ref, cell (default: []), forced (default: false), checking only (default:
 *    false), separate (default: false), merge into (default: [])] <ARRAY>
 *    merge into is the [col, row, compartment] of the tile to fill first
 * 1: Context - "requester", "where", "txId", "root", "settlement" (einv_storage_fnc_execute) <HASHMAP>
 *
 * Return Value:
 * [status, produced, extra] <ARRAY>
 *   status - "" done, else why not ("Gone", "Taken", "NoRoom", "NoBackpack", "NotLocal",
 *     "Moved", "IntoItself", "OutOfReach", "Bounced", "Skipped", "Failed", a guard's reason or a reason
 *     already in words)
 *   produced - the payloads it handed on, each consumed by a later op or settled
 *     (einv_storage_fnc_settle)
 *   extra - what else it tells, [] for nothing
 *
 * Example:
 * [[backpackContainer player, _payload, []], _context] call einv_storage_fnc_opPut;
 *
 * Public: No
 */

params [["_args", [], [[]]], ["_context", createHashMap, [createHashMap]]];

_args params [
    ["_to", objNull, [objNull, ""]],
    ["_payload", [], [[]]],
    ["_cell", [], [[]]],
    ["_force", false, [false]],
    ["_check", false, [false]],
    ["_separate", false, [false]],
    ["_mergeInto", [], [[]]]
];

if (_payload isEqualTo []) exitWith {["Skipped", [], []]};

// A holder of another type is put into with that type's own op (GVAR(holderTypes) "put").
if (_to isEqualType "") exitWith {["Failed", [], []]};

// Not put: all of it bounces - it counts as handed over, and settles on (fnc_settle).
private _fnc_bounce = {
    params ["_reason"];

    if (_check) exitWith {[_reason, [], [[], false]]};

    ["Bounced", [+_payload], [[], false, _reason]]
};

if (isNull _to) exitWith {["Gone"] call _fnc_bounce};

private _view = [_to, []] call FUNC(findEntry);
private _tiles = _view getOrDefault ["entries", []];

// The engine deletes an empty pile: whatever went in would be gone with it.
if ([_to] call FUNC(isGroundHolder) && {_tiles findIf {(_x getOrDefault ["count", 1]) > 0} < 0}) exitWith {
    ["Gone"] call _fnc_bounce
};

_payload params [["_type", "", [""]], ["_what", ""]];

private _class = if (_type isEqualTo "weapon") then {_what param [0, ""]} else {_what};

if !(_class isEqualType "" && {_class isNotEqualTo ""}) exitWith {
    ERROR_1("Cannot put %1 anywhere - not a payload.",_payload);
    ["Failed", [], []]
};

private _rounds = if (_type isEqualTo "magazine") then {_payload param [2, []]} else {[]};
private _count = switch (_type) do {
    case "magazine": {count _rounds};
    case "item": {_payload param [2, 1]};
    default {1};
};

// As a tile would come out of the cargo once it lies here.
private _probe = createHashMapFromArray [
    ["class", _class],
    ["count", _count max 1],
    ["ammo", _rounds param [0, 0]],
    ["attachments", [[], _what] select (_type isEqualTo "weapon")],
    ["container", objNull]
];

// A backpack into a backpack bounces; the cells decide everything else, below.
if (!_force && {[_to, _probe] call FUNC(backpackIntoBackpack)}) exitWith {
    ["NoBackpack"] call _fnc_bounce
};

// ---------------------------------------------------------------------------
// Does it stack? Items and magazines of a class that stacks, all with the same rounds, and not into the
// hidden holder of Strict mode: those lie in tiles of a count, which the places' records keep. Anything
// else is one tile.
// ---------------------------------------------------------------------------
private _info = [_class] call EFUNC(items,getInfo);
private _stack = (_info getOrDefault ["stack", 1]) max 1;

private _stackable = _stack > 1
    && {_count > 0}
    && {!((_info getOrDefault ["kind", ""]) in ["uniform", "vest", "backpack"])}
    && {
        (_type isEqualTo "item" && {(_payload param [3, []]) isEqualTo []})
        || {_type isEqualTo "magazine" && {(_info getOrDefault ["capacity", 0]) > 0} && {count (_rounds arrayIntersect _rounds) == 1}}
    }
    && {!([_to, _class] call FUNC(hiddenRoute))};

private _key = [_payload] call FUNC(payloadKey);

// The tiles of its key that can be joined: placed ones, in the order of their records.
private _same = [];

if (_stackable) then {
    _same = _tiles select {
        (_x getOrDefault ["count", 1]) > 0 && {!(_x getOrDefault ["overflow", false])} && {!(_x getOrDefault ["strict", false])}
        && {(_x getOrDefault ["key", ""]) isEqualTo _key}
    };
};

// What goes into which tile, for that many: [[index in _same, how many], ...] and the counts of the new
// tiles. Joined: the tile asked for first, then the others with room in their order - unless it is to
// stand apart.
private _fnc_distribute = {
    params ["_n"];

    private _joins = [];
    private _left = _n;

    if (!_separate) then {
        if (_mergeInto isNotEqualTo []) then {
            private _at = _same findIf {
                (_x getOrDefault ["col", -1]) == (_mergeInto param [0, -2])
                && {(_x getOrDefault ["row", -1]) == (_mergeInto param [1, -2])}
                && {(_x getOrDefault ["block", 0]) == (_mergeInto param [2, 0])}
            };

            if (_at >= 0) then {
                private _add = _left min (_stack - ((_same select _at) get "count"));

                if (_add > 0) then {
                    _joins pushBack [_at, _add];
                    _left = _left - _add;
                };
            };
        };

        {
            if (_left > 0 && {(_joins findIf {(_x select 0) == _forEachIndex}) < 0}) then {
                private _add = _left min (_stack - (_x get "count"));

                if (_add > 0) then {
                    _joins pushBack [_forEachIndex, _add];
                    _left = _left - _add;
                };
            };
        } forEach _same;
    };

    private _new = [];

    while {_left > 0} do {
        _new pushBack (_left min _stack);
        _left = _left - _stack;
    };

    [_joins, _new]
};

private _plan = if (_stackable) then {[_count] call _fnc_distribute} else {[[], [1]]};

_plan params ["_joins", "_newCounts"];

// A spot for every tile that opens: the cell asked for, else the first fit, upright, then turned. A payload
// that fits into the room of the tiles it joins needs none.
private _spots = [];
private _elsewhere = false;

if (_newCounts isNotEqualTo []) then {
    ([_view, _class, _cell, count _newCounts] call FUNC(findSpots)) params ["_found", "_else"];

    _spots = _found;
    _elsewhere = _else;
};

// Forced, an overflow row is fine: shown apart, never lost.
if (!_force && {(_spots findIf {_x isEqualTo []}) >= 0}) exitWith {["NoRoom"] call _fnc_bounce};
if (_check) exitWith {["", [], [_spots param [0, []], _elsewhere, _newCounts isEqualTo []]]};

private _rest = [_to, _payload] call FUNC(addPayload);

if (isNil "_rest" || {!(_rest isEqualType [])}) then {
    _rest = [];
};

if (_rest isEqualTo _payload) exitWith {["Failed"] call _fnc_bounce};

// How much of it came in: a part that did not goes on as the rest.
if (_stackable && {_rest isNotEqualTo []}) then {
    private _arrived = _count - (switch (_type) do {
        case "magazine": {count (_rest param [2, []])};
        default {_rest param [2, 0]};
    });

    _plan = [_arrived max 0] call _fnc_distribute;
    _joins = _plan select 0;
    _newCounts = _plan select 1;
};

(_info getOrDefault ["footprint", [1, 1, []]]) params [["_w", 1, [0]], ["_h", 1, [0]], ["_holes", [], [[]]]];

private _turnedHoles = (_info getOrDefault ["footprintTurned", [_h, _w, []]]) param [2, []];

// The records, in step with the cargo: a tile joined gains its items, a tile that opens gets a record of
// its own at its spot (the n-th record of a key is the n-th tile of the key, so it goes last).
{
    _x params ["_index", "_add"];

    private _tile = _same select _index;
    private _now = (_tile get "count") + _add;

    [_to, _tile, _now] call FUNC(setCount);
    _tile set ["count", _now];
} forEach _joins;

{
    private _spot = _spots param [_forEachIndex, []];

    if (_spot isNotEqualTo []) then {
        private _landed = createHashMapFromArray [
            ["class", _class],
            ["key", _key],
            ["w", _spot select 3],
            ["h", _spot select 4]
        ];

        if (_stackable) then {
            _landed set ["count", _x];
        };

        [_to, _landed, _spot, true] call FUNC(setPlace);
    };
} forEach _newCounts;

// Landed: noted, should it have left a container in this very op (op "move"). A rest that did not is
// out again until it lands somewhere.
["in", _payload] call FUNC(journalNote);

if (_rest isNotEqualTo []) then {
    ["out", _rest] call FUNC(journalNote);
};

// The view follows: a plain item, magazine or weapon that all landed lies where it was put. Anything
// else - a uniform, vest or backpack is a new object with a new key - is laid out anew when asked.
if (_rest isEqualTo [] && {_type in ["weapon", "magazine"] || {_type isEqualTo "item" && {(_payload param [3, []]) isEqualTo []}}}) then {
    {
        private _spot = _spots param [_forEachIndex, []];

        _tiles pushBack createHashMapFromArray [
            ["class", _class],
            ["key", _key],
            ["count", [_probe get "count", _x] select _stackable],
            ["ammo", _probe get "ammo"],
            ["capacity", _info getOrDefault ["capacity", 0]],
            ["attachments", _probe get "attachments"],
            ["container", objNull],
            ["strict", [_to, _class] call FUNC(hiddenRoute)],
            ["block", _spot param [2, -1]],
            ["col", _spot param [0, 0]],
            ["row", _spot param [1, 0]],
            ["w", _spot param [3, _w]],
            ["h", _spot param [4, _h]],
            ["rotated", (_spot param [5, 0]) == 1],
            ["holes", [_holes, _turnedHoles] select ((_spot param [5, 0]) == 1)],
            ["overflow", _spot isEqualTo []]
        ];
    } forEach _newCounts;
} else {
    GVAR(cache) deleteAt (netId _to);
};

// Where it landed: the first tile that opened, else the tile it joined.
private _landedCell = _spots param [0, []];

if (_landedCell isEqualTo [] && {_joins isNotEqualTo []}) then {
    private _joined = _same select ((_joins select 0) select 0);

    _landedCell = [_joined getOrDefault ["col", 0], _joined getOrDefault ["row", 0], _joined getOrDefault ["block", 0]];
};

if (_rest isNotEqualTo []) exitWith {["Bounced", [+_rest], [_landedCell, _elsewhere, "NoRoom"]]};

["", [], [_landedCell, _elsewhere]]
