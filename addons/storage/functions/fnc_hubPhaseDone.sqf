#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * An answered phase (event einv_storage_phaseDone, in-process for the server's own). Ignored unless the
 * hub waits for that very attempt - a late copy of an answer, or one for an attempt it gave up on.
 *
 * "NotLocal" for every op - the root was not local where it arrived, nothing ran there - is tried again
 * as the next attempt after attempt x NOTLOCAL_BACKOFF seconds, routed anew (fnc_hubRoute); after
 * NOTLOCAL_TRIES attempts every op counts as "Moved" and settlement returns what it was to carry. Any
 * other answer is kept (copied, the ops left out as "Skipped" put back in their places), its revisions
 * merged - the latest per holder - and the transaction driven on (fnc_hubNext). Once the root's last
 * outstanding phase is answered, phases held for it are routed at once.
 *
 * Arguments:
 * 0: Request id <STRING>
 * 1: Phase index <NUMBER>
 * 2: Attempt <NUMBER>
 * 3: Results, per op sent [status, produced, extra] <ARRAY>
 * 4: Revisions, [[holder, revision], ...] <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["2:14", 1, 0, _results, _revisions] call einv_storage_fnc_hubPhaseDone;
 *
 * Public: No
 */

params [
    ["_id", "", [""]],
    ["_index", 0, [0]],
    ["_attempt", 0, [0]],
    ["_answer", [], [[]]],
    ["_answerRevisions", [], [[]]]
];

if (!isServer) exitWith {};

private _key = format ["%1|%2", _id, _index];
private _waiting = GVAR(waiting) getOrDefault [_key, []];

if (_waiting isEqualTo [] || {(_waiting select 2) != _attempt}) exitWith {};

GVAR(waiting) deleteAt _key;

// That machine holds nothing of the root any more once this was its last phase of it.
private _rootFree = false;
private _rootId = _waiting select 5;

if (_rootId isNotEqualTo "") then {
    private _wait = GVAR(rootWaits) getOrDefault [_rootId, []];

    if (_wait isNotEqualTo []) then {
        private _keys = _wait select 1;
        private _at = _keys find _key;

        if (_at >= 0) then {_keys deleteAt _at};

        if (_keys isEqualTo []) then {
            _wait set [3, diag_tickTime];
            _rootFree = true;
        };
    };
};

private _entry = GVAR(hub) getOrDefault [_id, []];

if (
    _entry isNotEqualTo []
    && {count (_entry select 1) == _index}
    && {((_entry select 7) param [0, -1]) == _index}
) then {
    _entry params ["_tx", "_results", "", "", "_revisions", "", "", "_current"];
    _current params ["", "_send", "_map"];

    private _notLocal = _answer isNotEqualTo [] && {
        (_answer findIf {(_x param [0, "", [""]]) isNotEqualTo "NotLocal"}) < 0
    };

    if (_notLocal) then {
        private _next = _attempt + 1;

        if (_next >= NOTLOCAL_TRIES) then {
            WARNING_2("Phase %1: its container was not local where the server sent it, %2 times - put back.",_key,_next);
            _results pushBack (_map apply {[["Moved", [], []], ["Skipped", [], []]] select (_x < 0)});
            [_id] call FUNC(hubNext);
        } else {
            // Tried again a little later each time, so a few quick tries never all land in the moment in
            // which neither the old nor the new owner sees the root local.
            private _now = diag_tickTime;

            _current set [3, _next];
            GVAR(held) set [_key, [_next, _now + _next * NOTLOCAL_BACKOFF, _now, "time", _id, _index]];
        };
    } else {
        if (count _answer != count _send) then {
            WARNING_3("Phase %1 answered %2 ops of %3 - the missing ones count as failed.",_key,count _answer,count _send);
        };

        _results pushBack (_map apply {
            if (_x < 0) then {
                ["Skipped", [], []]
            } else {
                private _result = _answer param [_x, []];

                if (_result isEqualType [] && {_result isNotEqualTo []}) then {+_result} else {["Failed", [], []]}
            };
        });

        {
            if (_x isEqualType [] && {count _x >= 2}) then {
                _x params ["_holder", "_revision"];

                private _at = _revisions findIf {(_x select 0) isEqualTo _holder};

                if (_at < 0) then {
                    _revisions pushBack [_holder, _revision];
                } else {
                    _revisions set [_at, [_holder, _revision]];
                };
            };
        } forEach _answerRevisions;

        [_id] call FUNC(hubNext);
    };
};

// Phases held only because this machine still held phases of their root: routed now rather than at
// the next look (fnc_hubTick). Every held one of that kind - the route decides again for each.
if (_rootFree) then {
    private _due = [];

    {
        if ((_y select 3) isEqualTo "root") then {_due pushBack [_x, _y select 4, _y select 5]};
    } forEach GVAR(held);

    {
        _x params ["_heldKey", "_heldId", "_heldIndex"];

        if (_heldKey in GVAR(held) && {[_heldId, _heldIndex] call FUNC(hubRoute)}) then {
            [_heldId] call FUNC(hubNext);
        };
    } forEach _due;
};
