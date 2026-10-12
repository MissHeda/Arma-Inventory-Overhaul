#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The server takes on a transaction a machine could not run by itself (event einv_storage_hubStart): it
 * is carried in GVAR(hub) and driven on from the first phase the requester did not run (fnc_hubNext).
 *
 * In multiplayer the requester must be the unit of the machine that sent it - the guards trust the
 * requester, so nobody may name someone else. A machine without a player unit of its own (the server, a
 * headless client) may ask without a requester. A transaction that names another machine's unit is
 * refused with an RPT warning: none of its own phases runs, but what its requester already took out in
 * the phases it ran itself is settled like anything else - back where it came from, else into the
 * requester's vehicle, else onto the ground - so a refusal never loses an item.
 *
 * GVAR(hub) holds per transaction id: [transaction (its phases grow by the settlement steps), results
 * per phase, the phase under way, settlement step (0 while its own phases run), revisions
 * [[holder, revision], ...], number of its own phases, per phase [settlement step, root was an object],
 * the phase under way as sent [index, ops with refs filled in, op map, attempt, settlement]].
 *
 * Arguments:
 * 0: Transaction, [id, requester, requester's machine, where, phases, silent] - a 7th element true
 *    marks a transaction of settlement phases only (handed over by fnc_requestNext) <ARRAY>
 * 1: Results of the phases the requester ran already, per phase per op [status, produced, extra]
 *    <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_tx, _results] call einv_storage_fnc_hubStart;
 *
 * Public: No
 */

params [["_tx", [], [[]]], ["_results", [], [[]]]];

if (!isServer) exitWith {};

// A copy: the server's own requests arrive in-process, and the hub adds settlement phases to what it
// carries - the requester's own record of the request must not change with it.
_tx = +_tx;
_results = +_results;

_tx params [
    ["_id", "", [""]],
    ["_requester", objNull, [objNull]],
    ["_requesterOwner", -1, [0]],
    ["_where", [], [[]]],
    ["_phases", [], [[]]],
    ["_silent", false, [false]]
];

if (_id isEqualTo "") exitWith {
    WARNING("A transaction without an id reached the server - ignored.");
};

if (_id in GVAR(hub)) exitWith {
    WARNING_1("Transaction %1 reached the server twice - the second copy is ignored.",_id);
};

// Every phase names the object whose authority runs it (objNull: the server) and a list of ops.
private _broken = _phases findIf {
    !(_x isEqualType [])
    || {!((_x param [0, 0]) isEqualType objNull)}
    || {!((_x param [1, 0]) isEqualType [])}
};

if (_broken >= 0) exitWith {
    WARNING_2("Transaction %1 has a broken phase %2 - ignored.",_id,_broken);
};

// The results must stand for phases that exist, each a list of op results.
if (count _results > count _phases || {_results isNotEqualTo [] && {!(_results isEqualTypeAll [])}}) exitWith {
    WARNING_1("Transaction %1 came with broken results - ignored.",_id);
};

// Put the parts back in the order params read them, so the copy is complete whatever was missing.
_tx = [_id, _requester, _requesterOwner, _where, _phases, _silent, _tx param [6, false, [false]]];

private _trusted = !isMultiplayer || {
    if (isNull _requester) then {
        // The server or a headless client asking for a mission script: no unit of their own to check.
        _requesterOwner == 2 || {(entities "HeadlessClient_F") findIf {owner _x == _requesterOwner} >= 0}
    } else {
        owner _requester == _requesterOwner
    }
};

if (!_trusted) then {
    private _name = "nobody";
    if (!isNull _requester) then {_name = name _requester};
    WARNING_3("Transaction %1 names %2 as its requester, whom machine %3 does not control - none of its phases runs, what it already took out is put back.",_id,_name,_requesterOwner);

    // Its own phases count as not done; settlement then returns what the requester's phases took.
    for "_index" from (count _results) to (count _phases - 1) do {
        _results pushBack (((_phases select _index) select 1) apply {["Failed", [], []]});
    };
};

// Which phases had an object for a root: one that is null later went away meanwhile, while objNull from
// the start is the server's own ground work (fnc_hubRoute).
private _info = _phases apply {[0, !isNull (_x select 0)]};

GVAR(hub) set [_id, [_tx, _results, count _results, 0, [], count _phases, _info, []]];

[_id] call FUNC(hubNext);
