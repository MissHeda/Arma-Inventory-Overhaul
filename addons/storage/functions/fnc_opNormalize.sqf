#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Op "normalize": a viewer's report that a holder's places and cargo disagree
 * (einv_gui_fnc_requestNormalize). Skipped for a holder normalised here less than half a second ago;
 * else normalised (fnc_normalize). When that wrote nothing and the viewer's revision and hash differ
 * from this machine's, the viewer holds a stale copy: the records are written again publicly (forced)
 * and the nested containers' tags set again (fnc_tagNested, forced) - at most once per holder every
 * FORCE_REPEAT seconds.
 *
 * When it last normalised and last wrote again for a stale copy is kept on the holder, local
 * (einv_storage_normalized), for kits in GVAR(normalizedKits). It runs as outside a phase: what it
 * writes is final at once, not buffered for the end of the phase.
 *
 * Arguments:
 * 0: Args, [holder, the viewer's revision (default: -1), the hash of the viewer's records (default: "" -
 *    not compared)] <ARRAY>
 * 1: Context - "requester", "where", "txId", "root", "settlement" (einv_storage_fnc_execute) <HASHMAP>
 *
 * Return Value:
 * [status, produced, extra] <ARRAY>
 *   status - "" done, else why not ("Gone", "Taken", "NoRoom", "NotLocal", "Moved",
 *     "IntoItself", "OutOfReach", "Bounced", "Skipped", "Failed", a guard's reason or a reason already
 *     in words)
 *   produced - the payloads it handed on, each consumed by a later op or settled
 *     (einv_storage_fnc_settle)
 *   extra - what else it tells, [] for nothing
 *
 * Example:
 * [[cursorObject, 4, _hash], _context] call einv_storage_fnc_opNormalize;
 *
 * Public: No
 */

params [["_args", [], [[]]], ["_context", createHashMap, [createHashMap]]];

_args params [["_holder", objNull, [objNull, ""]], ["_viewerRevision", -1, [0]], ["_viewerHash", "", [""]]];

private _isKey = _holder isEqualType "";

if (if (_isKey) then {_holder isEqualTo ""} else {isNull _holder}) exitWith {["Moved", [], []]};

// [normalised at, written again at].
(if (_isKey) then {
    GVAR(normalizedKits) getOrDefault [_holder, [-1e9, -1e9]]
} else {
    _holder getVariable [QGVAR(normalized), [-1e9, -1e9]]
}) params [["_normalizedAt", -1e9, [0]], ["_forcedAt", -1e9, [0]]];

// Several viewers report the same drift within moments of each other: once is enough.
if (diag_tickTime - _normalizedAt < 0.5) exitWith {["", [], []]};

_normalizedAt = diag_tickTime;

// Outside the buffer: the normalise and a stale copy's re-write are final the moment they are made.
GVAR(executing) = false;

private _wrote = [_holder] call FUNC(normalize);

if (
    !(!isNil "_wrote" && {_wrote isEqualTo true})
    && {_viewerHash isNotEqualTo ""}
    && {diag_tickTime - _forcedAt >= FORCE_REPEAT}
) then {
    ([_holder] call FUNC(readPlaces)) params [["_revision", 0, [0]], ["_records", [], [[]]]];

    // Nothing drifted here, yet the viewer holds something else: an older write of a previous authority
    // reached them last, or a tag never did. Everyone gets this machine's copy again.
    if ([_viewerRevision, _viewerHash] isNotEqualTo [_revision, hashValue _records]) then {
        _forcedAt = diag_tickTime;

        [_holder, _records, true] call FUNC(writePlaces);

        // The ids of what lies in it, sent again whether they changed or not.
        if (!_isKey) then {
            [_holder, true] call FUNC(tagNested);
        };
    };
};

GVAR(executing) = true;

if (_isKey) then {
    GVAR(normalizedKits) set [_holder, [_normalizedAt, _forcedAt]];
} else {
    _holder setVariable [QGVAR(normalized), [_normalizedAt, _forcedAt]];
};

["", [], []]
