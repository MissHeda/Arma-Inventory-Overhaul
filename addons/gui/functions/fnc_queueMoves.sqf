#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The hands' queue, as fnc_sendMoves meets it: of the moves it was given, those that need the hands - a drop,
 * a move to a different container or holder, putting on and taking off (fnc_queueTime) - are not sent but
 * kept in the window's queue (GVAR(handQueue)), one entry per move, each with its own circle on its tile
 * (fnc_drawQueue). The rest go on at once. Only the first entry runs (fnc_animateQueue); when its circle is
 * full fnc_runQueue sends it through fnc_sendMoves as any move, so nothing is reserved, changed or checked
 * differently on the way: the authority decides when the move arrives.
 *
 * Nothing is queued when no time is set for its kind (0), when the window is not the inventory (ACE Arsenal's
 * panel stays instant) or is not open, or when nothing of the move is on the window (no tile to put a circle on). A move of a tile or worn item that already waits is left out.
 *
 * The label an option brings (the hint after a Take all) goes with the last entry of the call, the one whose
 * answer ends it.
 *
 * Cost: one call for all the moves of a Take all or a group drag, and no drawing in it - the entries are only
 * added and fnc_drawQueue is asked for (GVAR(queueDirty), done by fnc_animateQueue in the next frame, or by any
 * drawPending before, from GVAR(queueFrom) on), so the circles of N entries are made once, not N times. Whether a tile
 * waits is one look in the queue's index by cell (fnc_queueIndex, fnc_queueWaits) and the tile is the HashMap the caller
 * named (the entry's "hint", fnc_queueTiles) - a move costs a few lookups however long the queue is and however many tiles
 * the container has, which is what the quick move key held down (one call per repeat) needs.
 *
 * Arguments:
 * 0: Moves, as fnc_sendMoves takes them <ARRAY>
 * 1: Options of fnc_sendMoves <HASHMAP>
 *
 * Return Value:
 * [moves to send now, how many were queued] <ARRAY>
 *
 * Example:
 * [_moves, createHashMap] call einv_gui_fnc_queueMoves;
 *
 * Public: No
 */

disableSerialization;

params [["_moves", [], [[]]], ["_options", createHashMap, [createHashMap]]];

private _display = uiNamespace getVariable [QGVAR(display), displayNull];

if (isNull _display || {!(call FUNC(isInventoryMode))}) exitWith {[_moves, 0]};

// What waits already is looked up in the queue's index (fnc_queueIndex): a second move of the same tile or worn item
// is not asked for, and the ask costs the same however long the queue is. A worn item is told by its slot, which the
// few entries of that kind are searched for.
private _cache = createHashMap;
private _slotsAdded = [];

private _instant = [];
private _held = [];

{
    private _move = _x;

    ([_move] call FUNC(queueTime)) params ["_hand", "_seconds"];

    if (_hand isEqualTo "" || {_seconds <= 0}) then {
        _instant pushBack _move;
        continue;
    };

    // The tiles it takes from, named as the moves in flight name them (fnc_sendMoves), so the same tile is found
    // again when the window is drawn anew - and the worn item a take off or swap lifts from its slot.
    private _sources = [];
    private _slot = [];
    private _hint = [];
    private _kind = _move getOrDefault ["kind", "move"];

    {
        _x params ["_holder", "_tile"];

        if (count _tile == 0) then {continue};

        private _key = _tile getOrDefault ["key", ""];

        if (_key isEqualTo "") then {
            _key = [_tile] call EFUNC(storage,entryKey);
        };

        _sources pushBack [_holder, _key, _tile getOrDefault ["block", 0], _tile getOrDefault ["col", -1], _tile getOrDefault ["row", -1]];
        _hint pushBack _tile;
    } forEach (switch (_kind) do {
        case "move";
        case "equip": {[[_move getOrDefault ["from", objNull], _move getOrDefault ["entry", createHashMap]]]};
        case "exchange": {
            [
                [_move getOrDefault ["from", objNull], _move getOrDefault ["entry", createHashMap]],
                [_move getOrDefault ["to", objNull], _move getOrDefault ["otherEntry", createHashMap]]
            ]
        };
        default {[]};
    });

    if (_kind in ["unequip", "swap"]) then {
        _slot = [_move getOrDefault ["unit", objNull], _move getOrDefault ["slot", ""]];
    };

    // Nothing of it on the window - a kit unpacked from the menu with its window closed, a slot not shown: no circle
    // to run, so no wait either. The tile the caller names is the one on the window while its controls are there
    // (fnc_queueTiles); only otherwise is the window searched.
    private _found = [createHashMapFromArray [["sources", _sources], ["slot", _slot], ["hint", _hint]], _cache] call FUNC(queueTiles);

    private _shown = _found isNotEqualTo []
        || {_slot isNotEqualTo [] && {(uiNamespace getVariable [QGVAR(slots), []]) findIf {
            (_x param [5, ""]) isEqualTo (_slot select 1) && {(_x param [6, objNull]) isEqualTo (_slot select 0)} && {(_x param [7, -1]) < 0}
        } >= 0}};

    if (!_shown) then {
        _instant pushBack _move;
        continue;
    };

    // Already waiting: left out, not sent a second time.
    if (
        (_slot isNotEqualTo [] && {_slot in _slotsAdded || {([_slot select 0, _slot select 1] call FUNC(queuedSlot)) > 0}})
        || {_sources findIf {[_x] call FUNC(queueWaits)} >= 0}
    ) then {
        continue;
    };

    if (_slot isNotEqualTo []) then {
        _slotsAdded pushBack _slot;
    };

    GVAR(handId) = GVAR(handId) + 1;

    private _own = +_options;
    _own set ["now", true];

    private _entry = createHashMapFromArray [
        ["id", GVAR(handId)], ["move", _move], ["options", _own], ["hand", _hand], ["time", _seconds],
        ["sources", _sources], ["slot", _slot], ["hint", _hint], ["fx", []], ["arc", controlNull], ["step", 1]
    ];

    _held pushBack _entry;

    // At once, so the same tile twice in one call is left out as well.
    [[_entry], true] call FUNC(queueIndex);
} forEach _moves;

if (_held isEqualTo []) exitWith {[_instant, 0]};

// The hint after everything went as asked belongs to the last one.
for "_i" from 0 to (count _held - 2) do {
    ((_held select _i) get "options") set ["label", ""];
};

if (GVAR(handQueue) isEqualTo []) then {
    GVAR(handStarted) = -1;
};

// The circles of the entries before these stay as they are: only the new ones need a pass (fnc_drawQueue).
GVAR(queueFrom) = [count GVAR(handQueue), GVAR(queueFrom) min count GVAR(handQueue)] select GVAR(queueDirty);

GVAR(handQueue) append _held;

// The tiles fade and the circles come once, in the next frame (fnc_animateQueue), which also starts the clock; a
// caller that draws at once (fnc_drawPending) does it for the whole queue.
GVAR(queueDirty) = true;

[_instant, count _held]
