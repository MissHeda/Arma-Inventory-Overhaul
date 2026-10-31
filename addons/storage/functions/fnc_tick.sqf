#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Every machine's per-frame handler: runs queued phases whole, in arrival order, until PHASE_FRAME_OPS
 * ops ran this frame - at least one phase -, a phase whose root is not local here any more answering
 * "NotLocal" for every op (journaled). Every few seconds drops journal entries older than JOURNAL_KEEP
 * seconds, and requests whose answer never came within that time. On the server in multiplayer, every
 * HUB_TICK seconds, also the hub's held phases and re-sends (fnc_hubTick).
 *
 * A queued phase is [journal key, root, ops, context, continuation, continuation args] - pushed by
 * fnc_runPhase, and by the hub for the server's own roots.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call aio_storage_fnc_tick;
 *
 * Public: No
 */

// Whole phases only - a payload never waits across a frame on a client -, as many as fit into the
// frame's budget. Many players emptying crates at once spread over a few frames instead of one.
private _ran = 0;

while {
    GVAR(queue) isNotEqualTo []
    && {_ran == 0 || {_ran + count (((GVAR(queue) select 0) param [2, []])) <= PHASE_FRAME_OPS}}
} do {
    // Out of the queue before it runs: a script error inside stops this frame's loop, not the next one's.
    (GVAR(queue) deleteAt 0) params [
        ["_key", "", [""]],
        ["_root", objNull, [objNull]],
        ["_ops", [], [[]]],
        ["_context", createHashMap, [createHashMap]],
        ["_continuation", {}, [{}]],
        ["_continuationArgs", []]
    ];

    _ran = _ran + ((count _ops) max 1);

    // Its turn has come: the root may have gone to another machine meanwhile. Then nothing runs, and that
    // is journaled as well - a late copy of this attempt never runs here, even should the root come back.
    if (if (isNull _root) then {isServer} else {local _root}) then {
        [_ops, _context, _key, _continuation, _continuationArgs] call FUNC(execute);
    } else {
        private _results = _ops apply {["NotLocal", [], []]};

        GVAR(journal) set [_key, ["done", _results, [], diag_tickTime, []]];
        [_results, [], _continuationArgs] call _continuation;
    };
};

// The hub's held phases and re-sends. Single player never needs the hub.
if (isServer && {isMultiplayer} && {diag_tickTime >= GVAR(hubTickAt)}) then {
    GVAR(hubTickAt) = diag_tickTime + HUB_TICK;

    call FUNC(hubTick);
};

// Now and then: what nobody will ask for again. A phase still queued stays - it has yet to run.
if (diag_frameNo % 300 == 0) then {
    private _now = diag_tickTime;
    private _old = [];

    {
        if ((_y param [0, ""]) isNotEqualTo "queued" && {_now - (_y param [3, _now]) > JOURNAL_KEEP}) then {
            _old pushBack _x;
        };
    } forEach GVAR(journal);

    {
        GVAR(journal) deleteAt _x;
    } forEach _old;

    // Requests whose answer never came - the server dropped them, or went away: the window stopped waiting
    // long ago (aio_gui_fnc_onFrame).
    _old = [];

    {
        if (_now - (_y param [4, _now]) > JOURNAL_KEEP) then {
            _old pushBack _x;
        };
    } forEach GVAR(requests);

    {
        GVAR(requests) deleteAt _x;
    } forEach _old;
};
