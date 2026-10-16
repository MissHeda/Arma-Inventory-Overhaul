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
 * Extra: [landed cell [col, row, block, w, h, rot] - [] in an overflow row -, elsewhere]; when it bounced a
 * third element says why: "Gone" (nothing to put it into), "NoBackpack" (a backpack into a
 * backpack), "NoRoom", "Failed" (the engine took none of it).
 *
 * Checking only (args 4): nothing changes; the status is "" or that reason, the extra [spot, elsewhere].
 *
 * Arguments:
 * 0: Args, [to, payload or ref, cell (default: []), forced (default: false), checking only (default:
 *    false)] <ARRAY>
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
    ["_check", false, [false]]
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

// The view's cells, per compartment rows of booleans, true where a tile lies or a shaped compartment
// has a hole (fnc_seedTaken).
private _blocks = _view getOrDefault ["blocks", []];
private _open = _view getOrDefault ["open", false];
private _taken = [_blocks] call FUNC(seedTaken);

// A shaped item (size=xx/x-) takes only its own cells, holes as it lies (einv_items_fnc_footprintAs).
private _fnc_mark = {
    params ["_block", "_col", "_row", "_w", "_h", ["_holes", []]];

    if (_block < 0 || {_block >= count _blocks}) exitWith {};

    [_taken select _block, (_blocks select _block) select 0, _col, _row, _w, _h, _holes] call FUNC(takeCells);
};

private _fnc_free = {
    params ["_block", "_col", "_row", "_w", "_h", ["_holes", []]];

    if (_block < 0 || {_block >= count _blocks}) exitWith {false};

    (_blocks select _block) params ["_cols", "_rows"];

    if (_col < 0 || {_row < 0} || {_col + _w > _cols} || {!_open && {_row + _h > _rows}}) exitWith {false};

    [_taken select _block, _col, _row, _w, _h, _holes] call FUNC(cellsFree)
};

// Compartment after compartment, row by row - past the last row of an open grid everything is free.
private _fnc_firstFit = {
    params ["_w", "_h", ["_holes", []]];

    private _found = [];

    {
        _x params ["_cols", "_rows"];

        private _block = _forEachIndex;
        private _last = if (_open) then {count (_taken select _block)} else {_rows - _h};

        for "_row" from 0 to _last do {
            for "_col" from 0 to (_cols - _w) do {
                if ([_block, _col, _row, _w, _h, _holes] call _fnc_free) exitWith {
                    _found = [_col, _row, _block, _w, _h];
                };
            };

            if (_found isNotEqualTo []) exitWith {};
        };

        if (_found isNotEqualTo []) exitWith {};
    } forEach _blocks;

    _found
};

{
    if ((_x getOrDefault ["count", 1]) > 0 && {!(_x getOrDefault ["overflow", false])}) then {
        [_x getOrDefault ["block", -1], _x getOrDefault ["col", 0], _x getOrDefault ["row", 0], _x getOrDefault ["w", 1], _x getOrDefault ["h", 1], _x getOrDefault ["holes", []]] call _fnc_mark;
    };
} forEach _tiles;

// The requested cell when it is free - in the item's size, the way round it says (rot, 1 turned a
// quarter clockwise; a cell without it is turned when not as wide as the item upright) -, else the
// first fit, upright, then turned. A shaped item (size=xx/x-) is asked with its holes as it would lie,
// and one in a square box is tried turned too when that takes other cells.
private _info = [_class] call EFUNC(items,getInfo);

(_info getOrDefault ["footprint", [1, 1, []]]) params [["_w", 1, [0]], ["_h", 1, [0]], ["_holes", [], [[]]]];
_cell params [["_col", -1, [0]], ["_row", -1, [0]], ["_block", 0, [0]], ["_cellW", _w, [0]], ["_cellH", _h, [0]], ["_cellRot", -1, [0]]];

if !(_cellRot in [0, 1]) then {
    _cellRot = parseNumber (_cellW != _w);
};

if (([[_w, _h], [_h, _w]] select (_cellRot == 1)) isNotEqualTo [_cellW, _cellH]) then {
    _cellW = _w;
    _cellH = _h;
    _cellRot = 0;
};

private _turnedHoles = (_info getOrDefault ["footprintTurned", [_h, _w, []]]) param [2, []];
private _spot = [];
private _elsewhere = false;

if (_cell isNotEqualTo [] && {[_block, _col, _row, _cellW, _cellH, [_holes, _turnedHoles] select (_cellRot == 1)] call _fnc_free}) then {
    _spot = [_col, _row, _block, _cellW, _cellH, _cellRot];
} else {
    _spot = [_w, _h, _holes] call _fnc_firstFit;

    if (_spot isNotEqualTo []) then {
        _spot pushBack 0;
    } else {
        if (_w != _h || {_holes isNotEqualTo _turnedHoles}) then {
            _spot = [_h, _w, _turnedHoles] call _fnc_firstFit;

            if (_spot isNotEqualTo []) then {
                _spot pushBack 1;
            };
        };
    };

    _elsewhere = _cell isNotEqualTo [] && {_spot isNotEqualTo []};
};

// Forced, an overflow row is fine: shown apart, never lost.
if (_spot isEqualTo [] && {!_force}) exitWith {["NoRoom"] call _fnc_bounce};
if (_check) exitWith {["", [], [_spot, _elsewhere]]};

private _rest = [_to, _payload] call FUNC(addPayload);

if (isNil "_rest" || {!(_rest isEqualType [])}) then {
    _rest = [];
};

if (_rest isEqualTo _payload) exitWith {["Failed"] call _fnc_bounce};

private _key = [_payload] call FUNC(payloadKey);

if (_spot isNotEqualTo []) then {
    private _landed = createHashMapFromArray [
        ["class", _class],
        ["key", _key],
        ["w", _spot select 3],
        ["h", _spot select 4]
    ];

    [_to, _landed, _spot, true] call FUNC(setPlace);
};

// Landed: noted, should it have left a container in this very op (op "move"). A rest that did not is
// out again until it lands somewhere.
["in", _payload] call FUNC(journalNote);

if (_rest isNotEqualTo []) then {
    ["out", _rest] call FUNC(journalNote);
};

// The view follows: a plain item, magazine or weapon that all landed lies where it was put. Anything
// else - a uniform, vest or backpack is a new object with a new key, a stack may have joined another -
// is laid out anew when asked.
if (_rest isEqualTo [] && {_type in ["weapon", "magazine"] || {_type isEqualTo "item" && {(_payload param [3, []]) isEqualTo []}}}) then {
    _tiles pushBack createHashMapFromArray [
        ["class", _class],
        ["key", _key],
        ["count", _probe get "count"],
        ["ammo", _probe get "ammo"],
        ["capacity", ([_class] call EFUNC(items,getInfo)) getOrDefault ["capacity", 0]],
        ["attachments", _probe get "attachments"],
        ["container", objNull],
        ["hidden", [_to, _class] call FUNC(hiddenRoute)],
        ["block", _spot param [2, -1]],
        ["col", _spot param [0, 0]],
        ["row", _spot param [1, 0]],
        ["w", _spot param [3, _w]],
        ["h", _spot param [4, _h]],
        ["rotated", (_spot param [5, 0]) == 1],
        ["holes", [_holes, _turnedHoles] select ((_spot param [5, 0]) == 1)],
        ["overflow", _spot isEqualTo []]
    ];
} else {
    GVAR(cache) deleteAt (netId _to);
};

if (_rest isNotEqualTo []) exitWith {["Bounced", [+_rest], [_spot, _elsewhere, "NoRoom"]]};

["", [], [_spot, _elsewhere]]
