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

// What waits already: a second move of the same tile or worn item is not asked for.
private _waiting = [];

{
    _waiting append (_x getOrDefault ["sources", []]);
} forEach GVAR(handQueue);

private _slotsWaiting = GVAR(handQueue) apply {_x getOrDefault ["slot", []]};

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
    private _kind = _move getOrDefault ["kind", "move"];

    {
        _x params ["_holder", "_tile"];

        if (count _tile == 0) then {continue};

        private _key = _tile getOrDefault ["key", ""];

        if (_key isEqualTo "") then {
            _key = [_tile] call EFUNC(storage,entryKey);
        };

        _sources pushBack [_holder, _key, _tile getOrDefault ["block", 0], _tile getOrDefault ["col", -1], _tile getOrDefault ["row", -1]];
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
    // to run, so no wait either.
    private _shown = ([createHashMapFromArray [["sources", _sources], ["slot", _slot]]] call FUNC(queueTiles)) isNotEqualTo []
        || {_slot isNotEqualTo [] && {(uiNamespace getVariable [QGVAR(slots), []]) findIf {
            (_x param [5, ""]) isEqualTo (_slot select 1) && {(_x param [6, objNull]) isEqualTo (_slot select 0)} && {(_x param [7, -1]) < 0}
        } >= 0}};

    if (!_shown) then {
        _instant pushBack _move;
        continue;
    };

    // Already waiting: left out, not sent a second time.
    if (
        (_slot isNotEqualTo [] && {_slot in _slotsWaiting})
        || {_sources findIf {_x in _waiting} >= 0}
    ) then {
        continue;
    };

    _waiting append _sources;

    if (_slot isNotEqualTo []) then {
        _slotsWaiting pushBack _slot;
    };

    GVAR(handId) = GVAR(handId) + 1;

    private _own = +_options;
    _own set ["now", true];

    _held pushBack createHashMapFromArray [
        ["id", GVAR(handId)], ["move", _move], ["options", _own], ["hand", _hand], ["time", _seconds],
        ["sources", _sources], ["slot", _slot], ["fx", []], ["arc", controlNull], ["step", 1]
    ];
} forEach _moves;

if (_held isEqualTo []) exitWith {[_instant, 0]};

// The hint after everything went as asked belongs to the last one.
for "_i" from 0 to (count _held - 2) do {
    ((_held select _i) get "options") set ["label", ""];
};

if (GVAR(handQueue) isEqualTo []) then {
    GVAR(handStarted) = -1;
};

GVAR(handQueue) append _held;

// The tiles fade and the circles come at once; the next frame starts the clock.
call FUNC(drawPending);

[_instant, count _held]
