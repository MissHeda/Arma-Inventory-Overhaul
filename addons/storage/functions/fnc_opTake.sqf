#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Op "take": out of a holder - produced the payload. Not there with that many: "Gone" - all or nothing
 * for the count asked for. A whole tile's record leaves the holder, and the execution's view of it
 * follows (fnc_findEntry: the tile's count lowered, at 0 it is gone).
 *
 * The engine picks which weapon of a class leaves, and which of two uniforms, vests or backpacks of one
 * class: those go through fnc_removeSameClass - all of the class out, the very ones asked for handed on,
 * the others back in, verified - once for this take and every later take of the class from the holder
 * in the phase (the context's "batch" keeps theirs: 20 identical rifles are 20 out and none back, once).
 * What could not go back in is produced as well, after the payload, and settles back into the holder.
 * Anything else goes through fnc_removeEntry. Both verify by counting before and after.
 *
 * Arguments:
 * 0: Args, [from, entry array, how many (-1 all)] <ARRAY>
 * 1: Context - "requester", "where", "txId", "root", "settlement", "ops", "opIndex", "batch"
 *    (einv_storage_fnc_execute) <HASHMAP>
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
 * [[cursorObject, _entryArray, 1], _context] call einv_storage_fnc_opTake;
 *
 * Public: No
 */

params [["_args", [], [[]]], ["_context", createHashMap, [createHashMap]]];

_args params [["_from", objNull, [objNull, ""]], ["_entryArray", [], [[]]], ["_count", -1, [0]]];

// A holder of another type is taken from with that type's own op (GVAR(holderTypes) "take").
if (_from isEqualType "") exitWith {["Failed", [], []]};
if (isNull _from) exitWith {["Moved", [], []]};

private _opIndex = _context getOrDefault ["opIndex", -1];
private _batch = _context getOrDefault ["batch", createHashMap];
private _entry = [_from, _entryArray] call FUNC(findEntry);

// The record leaves with a whole tile; the view follows either way.
private _fnc_taken = {
    params ["_n"];

    private _have = _entry getOrDefault ["count", 1];

    if (_n >= _have) then {
        [_from, _entry, []] call FUNC(setPlace);
        _entry set ["count", 0];
    } else {
        _entry set ["count", _have - _n];
    };
};

// A take before this one in the phase took this item out along with the rest of its class.
if (_opIndex in _batch) exitWith {
    (_batch deleteAt _opIndex) params [["_status", "Failed", [""]], ["_produced", [], [[]]]];

    if (_status isEqualTo "" && {count _entry > 0}) then {
        [1] call _fnc_taken;
    };

    [_status, _produced, []]
};

if (count _entry == 0) exitWith {["Gone", [], []]};

private _have = _entry getOrDefault ["count", 1];

if (_count > _have) exitWith {["Gone", [], []]};

if (_count < 1) then {
    _count = _have;
};

private _class = _entry getOrDefault ["class", ""];
private _lower = toLowerANSI _class;
private _kind = ([_class] call EFUNC(items,getInfo)) getOrDefault ["kind", ""];
private _weapon = (_entry getOrDefault ["attachments", []]) isNotEqualTo [] || {_kind in ["rifle", "handgun", "launcher", "binocular"]};
private _wearable = !isNull (_entry getOrDefault ["container", objNull]) || {_kind in ["uniform", "vest", "backpack"]};
private _status = "";
private _produced = [];

if (_weapon || {_wearable && {({toLowerANSI (_x select 0) isEqualTo _lower} count (everyContainer _from)) > 1}}) then {
    // This take and every later take of the class from this holder in the phase, each its own tile of the
    // view - two takes never claim the same one.
    private _group = [[_opIndex, _entry]];
    private _ops = _context getOrDefault ["ops", []];
    private _view = [_from, []] call FUNC(findEntry);
    private _tiles = _view getOrDefault ["entries", []];

    _entry set ["claimed", true];

    for "_j" from (_opIndex + 1) to (count _ops - 1) do {
        (_ops select _j) params [["_name", "", [""]], ["_jArgs", [], [[]]]];
        _jArgs params [["_jFrom", objNull, [objNull, ""]], ["_jArray", [], [[]]]];

        if (_name isEqualTo "take" && {_jFrom isEqualTo _from} && {toLowerANSI (_jArray param [0, ""]) isEqualTo _lower}) then {
            _jArray params ["", "", "", "", "", "", ["_col", -1, [0]], ["_row", -1, [0]], "", "", ["_block", -1, [0]], ["_key", "", [""]]];

            if (_key isEqualTo "") then {
                _key = [[_jArray] call FUNC(entryFromArray)] call FUNC(entryKey);
            };

            private _fnc_free = {
                (_x getOrDefault ["count", 1]) > 0
                && {!(_x getOrDefault ["claimed", false])}
                && {(_x getOrDefault ["key", ""]) isEqualTo _key}
            };

            private _at = _tiles findIf {
                call _fnc_free
                && {(_x getOrDefault ["block", -2]) == _block}
                && {(_x getOrDefault ["col", -2]) == _col}
                && {(_x getOrDefault ["row", -2]) == _row}
            };

            if (_at < 0) then {
                _at = _tiles findIf _fnc_free;
            };

            if (_at < 0) then {
                _batch set [_j, ["Gone", []]];
            } else {
                private _jEntry = _tiles select _at;

                _jEntry set ["claimed", true];
                _group pushBack [_j, _jEntry];
            };
        };
    };

    {
        (_x select 1) deleteAt "claimed";
    } forEach _group;

    ([_from, _class, _group apply {_x select 1}] call FUNC(removeSameClass)) params [
        ["_payloads", [], [[]]],
        ["_strays", [], [[]]],
        ["_notes", [], [[]]]
    ];

    // The later takes' items are theirs now (they find them in the batch, and fnc_phaseFinalize does should
    // this phase be stopped): marked as landed in this take's notes - by the journal index
    // fnc_removeSameClass gave, else by the payload.
    {
        _x params ["_j"];

        if (_forEachIndex > 0) then {
            private _payload = _payloads param [_forEachIndex, []];

            if (_payload isEqualType [] && {_payload isNotEqualTo []}) then {
                private _note = _notes param [_forEachIndex, -1];

                ["in", [_payload, _note] select (_note isEqualType 0 && {_note >= 0})] call FUNC(journalNote);
                _batch set [_j, ["", [_payload]]];
            } else {
                _batch set [_j, ["Failed", []]];
            };
        };
    } forEach _group;

    private _own = _payloads param [0, []];

    if (_own isEqualType [] && {_own isNotEqualTo []}) then {
        _produced pushBack _own;
    } else {
        _status = "Failed";
    };

    _produced append (_strays select {_x isEqualType [] && {_x isNotEqualTo []}});
} else {
    private _payload = [_from, _entry, _count] call FUNC(removeEntry);

    if (isNil "_payload" || {!(_payload isEqualType [])} || {_payload isEqualTo []}) then {
        _status = "Failed";
    } else {
        _produced pushBack _payload;
    };
};

if (_status isEqualTo "") then {
    [_count] call _fnc_taken;
};

[_status, _produced, []]
