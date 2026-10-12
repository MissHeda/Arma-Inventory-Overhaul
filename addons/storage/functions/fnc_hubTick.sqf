#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The server's look at the hub, paced by fnc_tick (every HUB_TICK seconds - this function does not pace
 * itself): held phases whose time came are routed again (fnc_hubRoute), and every phase that has waited
 * PHASE_RESEND seconds for its answer at a machine still connected is sent again - the same attempt, so
 * that machine answers it from its journal should it have run already, and never runs it twice. That
 * also recovers a phase whose event a joining player's machine dropped because CBA's network handler was
 * not there yet. No timeout while a machine is connected: moving its phase elsewhere could run it twice.
 *
 * A machine that is no longer connected although no PlayerDisconnected came for it is handled as if it
 * had come (fnc_hubDisconnect) - what waited there would otherwise wait for ever.
 *
 * Roots nobody has sent anything to for a minute are forgotten (GVAR(rootWaits)) - their last owner
 * holds nothing of them, and its last changes have long reached everyone.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call einv_storage_fnc_hubTick;
 *
 * Public: No
 */

if (!isServer) exitWith {};

private _now = diag_tickTime;

// Held phases whose time came. Collected first: routing changes GVAR(held), and one route can finish
// a transaction whose other held phase is then gone as well.
private _due = [];

{
    if ((_y select 1) <= _now) then {_due pushBack [_x, _y select 4, _y select 5]};
} forEach GVAR(held);

{
    _x params ["_key", "_txId", "_index"];

    if (_key in GVAR(held) && {[_txId, _index] call FUNC(hubRoute)}) then {
        [_txId] call FUNC(hubNext);
    };
} forEach _due;

// Unanswered phases, sent again - unless their machine is not connected any more.
private _stale = [];
private _left = [];
private _connected = [];
private _connectedRead = false;

{
    _y params ["_owner", "_root", "_attempt", "_send", "_sentAt", "", "_txId", "_index"];

    if (_sentAt + PHASE_RESEND <= _now && {!(_owner in GVAR(gone))}) then {
        private _entry = GVAR(hub) getOrDefault [_txId, []];

        if (_entry isEqualTo [] || {((_entry select 7) param [0, -1]) != _index}) then {
            _stale pushBack _x;
        } else {
            // The machine ids of everyone connected, read once and only when needed. An empty list
            // cannot be right while a client holds a phase - then nobody counts as gone.
            if (_owner != 2 && {!_connectedRead}) then {
                _connected = allUsers apply {(getUserInfo _x) param [1, -1]};
                _connectedRead = true;
            };

            if (_owner != 2 && {_connected isNotEqualTo []} && {!(_owner in _connected)}) then {
                _left pushBackUnique _owner;
            } else {
                private _tx = _entry select 0;

                _y set [4, _now];
                [QGVAR(runPhase), [_txId, _index, _attempt, _root, +_send, _tx select 1, _tx select 3, (_entry select 7) select 4], _owner] call CBA_fnc_ownerEvent;
            };
        };
    };
} forEach GVAR(waiting);

{GVAR(waiting) deleteAt _x} forEach _stale;

{
    WARNING_1("Machine %1 is gone without a PlayerDisconnected - what waited there is routed again.",_x);
    [0, "", "unknown", false, _x, ""] call FUNC(hubDisconnect);
} forEach _left;

// Roots idle for a minute.
private _idle = [];

{
    if ((_y select 1) isEqualTo [] && {(_y select 3) + 60 < _now}) then {_idle pushBack _x};
} forEach GVAR(rootWaits);

{GVAR(rootWaits) deleteAt _x} forEach _idle;
