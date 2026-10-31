#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Asks for a transaction: phases, each a list of ops on one root (GVAR(ops)), run one after the other,
 * each by its root's authority. Phases that may run here (fnc_isLocalRoot: every one in single player
 * and in Eden, in multiplayer those on this machine's own player unit) run at once; from the first one
 * that may not, the server's hub carries the transaction on (fnc_hubStart).
 *
 * Whatever an op produced and no later op consumed is settled - back where it came from, into the
 * requester's vehicle, onto the ground (fnc_settle): nothing is ever lost. When everything ran, the
 * callback gets [id, summary, revisions, callback args] (fnc_onAnswer) - not for a silent request. All
 * here, it is called before this returns.
 *
 * A transaction that needs the hub before the server answered this machine's greeting with this very
 * version (fnc_hubReady) does not start: every op "NotReady", answered at once - what this machine
 * took out could not be handed on.
 *
 * The phases are copied: what the caller holds is never changed.
 *
 * Arguments:
 * 0: Phases, [[root - objNull for the server, [[op, args], ...]], ...]; an op's args may hold ["#ref",
 *    phase, op, n] - the n-th payload an earlier op produced <ARRAY>
 * 1: Callback, given [id, summary, revisions, callback args] <CODE> (default: {})
 * 2: Callback args <ANY> (default: [])
 * 3: Silent - nobody is answered <BOOL> (default: false)
 * 4: Requester - whose reach counts and where their drops land <OBJECT> (default: ACE_player, else
 *    player)
 *
 * Return Value:
 * Request id, "<machine id>:<session>-<n>" - "" when there was nothing to ask for <STRING>
 *
 * Example:
 * [[[player, [["sort", [backpackContainer player]]]]], {hint str _this}] call aio_storage_fnc_request;
 *
 * Public: Yes
 */

params [
    ["_phases", [], [[]]],
    ["_callback", {}, [{}]],
    ["_callbackArgs", []],
    ["_silent", false, [false]],
    ["_requester", objNull, [objNull]]
];

_phases = (+_phases) select {
    _x isEqualType []
    && {(_x param [0, objNull]) isEqualType objNull}
    && {(_x param [1, 0]) isEqualType []}
};

if (_phases isEqualTo []) exitWith {""};

if (isNull _requester) then {
    _requester = missionNamespace getVariable ["ACE_player", player];

    if (isNil "_requester" || {!(_requester isEqualType objNull)}) then {
        _requester = player;
    };
};

private _machine = call FUNC(machineId);
private _id = format ["%1:%2-%3", _machine, GVAR(session), GVAR(nextRequest)];

GVAR(nextRequest) = GVAR(nextRequest) + 1;

// Where a drop of the requester's lands, taken now: settlement may come long after, with the requester
// moved on, seated or gone.
private _where = if (isNull _requester) then {
    // Nobody asked - a mission script on a dedicated server: what is left goes to the ground where the
    // first container named lies, rather than nowhere.
    private _first = _phases findIf {!isNull (_x select 0)};

    [[], [], objNull, if (_first < 0) then {[]} else {getPosASL ((_phases select _first) select 0)}]
} else {
    [[_requester] call FUNC(groundPos), eyePos _requester, objectParent _requester, getPosASL _requester]
};

// A server without the hub's events - or with other ones - would drop what this machine handed it.
if (_phases findIf {!([_x select 0] call FUNC(isLocalRoot))} >= 0 && {!(call FUNC(hubReady))}) exitWith {
    if (!_silent) then {
        [_id, [_phases apply {(_x select 1) apply {["NotReady", []]}}, [0, 0, 0], objNull], [], _callbackArgs] call _callback;
    };

    _id
};

// [tx, results, callback, callback args, asked at, revisions, settlement step done, how many phases were
// asked for, payloads handed to the hub's settlement [back, vehicle, ground]] (fnc_requestNext).
GVAR(requests) set [_id, [
    [_id, _requester, _machine, _where, _phases, _silent],
    [],
    _callback,
    _callbackArgs,
    diag_tickTime,
    [],
    0,
    count _phases,
    [0, 0, 0]
]];

[_id] call FUNC(requestNext);

_id
