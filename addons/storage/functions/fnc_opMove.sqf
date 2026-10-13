#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Op "move": within one root - a crate into a backpack lying in it, own uniform into own backpack.
 * "IntoItself" when the target is the moved uniform, vest or backpack or lies in it (fnc_liesIn); then
 * "NoBackpack" for a backpack into a backpack (fnc_backpackIntoBackpack) and a spot - the cell when free,
 * else the first fit ("elsewhere"), with none "NoRoom" - all before anything moves. Then out as op "take"
 * does (verified) and in as op "put" does (fnc_addPayload); the record at the spot, a whole tile's record
 * gone from the source. A rest that did not arrive goes back into the source, verified; what does not go
 * back either is "Bounced" with it. The same holder twice is op "place".
 *
 * Extra: [landed cell, elsewhere, what went back into the source - [] for nothing].
 *
 * Arguments:
 * 0: Args, [from, to, entry array, how many (-1 all), cell] <ARRAY>
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
 * [[_from, _to, _entryArray, -1, []], _context] call einv_storage_fnc_opMove;
 *
 * Public: No
 */

params [["_args", [], [[]]], ["_context", createHashMap, [createHashMap]]];

_args params [
    ["_from", objNull, [objNull, ""]],
    ["_to", objNull, [objNull, ""]],
    ["_entryArray", [], [[]]],
    ["_count", -1, [0]],
    ["_cell", [], [[]]]
];

// Holders of another type move with that type's own op (GVAR(holderTypes) "move").
if (_from isEqualType "" || {_to isEqualType ""}) exitWith {["Failed", [], []]};
if (isNull _from || {isNull _to}) exitWith {["Moved", [], []]};

if (_from isEqualTo _to) exitWith {
    if (_cell isEqualTo []) then {["", [], []]} else {[[_from, _entryArray, _cell], _context] call FUNC(opPlace)}
};

private _entry = [_from, _entryArray] call FUNC(findEntry);

if (count _entry == 0) exitWith {["Gone", [], []]};
if (_count > (_entry getOrDefault ["count", 1])) exitWith {["Gone", [], []]};

// A uniform, vest or backpack never goes into itself, or into anything lying in it.
private _inside = _entry getOrDefault ["container", objNull];

if (!isNull _inside && {[_to, _inside] call FUNC(liesIn)}) exitWith {["IntoItself", [], []]};

// A backpack never goes into a backpack.
if ([_to, _entry] call FUNC(backpackIntoBackpack)) exitWith {["NoBackpack", [], []]};

// A spot, before anything moves (op "put" only checking, the backpack rule not asked again).
([[_to, ["item", _entry getOrDefault ["class", ""], 1, []], _cell, true, true], _context] call FUNC(opPut)) params [
    ["_checked", "Failed", [""]],
    "",
    ["_checkExtra", [], [[]]]
];

if (_checked isNotEqualTo "") exitWith {[_checked, [], []]};

_checkExtra params [["_spot", [], [[]]], ["_elsewhere", false, [false]]];

if (_spot isEqualTo []) exitWith {["NoRoom", [], []]};

// Out, verified (op "take": the record, the view, a class taken as a whole).
([[_from, _entryArray, _count], _context] call FUNC(opTake)) params [["_takeStatus", "Failed", [""]], ["_produced", [], [[]]]];

if (_takeStatus isNotEqualTo "") exitWith {[_takeStatus, _produced, []]};

private _payload = _produced param [0, []];
private _strays = _produced select [1];

if (_payload isEqualTo []) exitWith {["Failed", _strays, []]};

// In, verified.
([[_to, _payload, _spot], _context] call FUNC(opPut)) params [["_putStatus", "Failed", [""]], ["_putProduced", [], [[]]], ["_putExtra", [], [[]]]];

if (_putStatus isEqualTo "") exitWith {
    ["", _strays, [_putExtra param [0, _spot], _elsewhere || {_putExtra param [1, false]}, []]]
};

// What did not arrive goes back where it was, verified; what does not go back either bounces on with it
// and settles (fnc_settle).
private _back = if (_putStatus isEqualTo "Bounced") then {_putProduced param [0, []]} else {_payload};

if (_back isEqualTo []) exitWith {["", _strays, [_putExtra param [0, _spot], _elsewhere, []]]};

([[_from, _back, []], _context] call FUNC(opPut)) params [["_backStatus", "Failed", [""]], ["_backProduced", [], [[]]]];

if (_backStatus isEqualTo "") exitWith {
    // Part of it went over: done, the rest is back. None of it: why not - the target gone meanwhile
    // counts as moved.
    if (_putStatus isEqualTo "Bounced" && {_back isNotEqualTo _payload}) exitWith {
        ["", _strays, [_putExtra param [0, _spot], _elsewhere, _back]]
    };

    private _reason = if (_putStatus isEqualTo "Bounced") then {_putExtra param [2, "NoRoom"]} else {_putStatus};

    [["Moved", _reason] select (_reason isNotEqualTo "Gone"), _strays, []]
};

["Bounced", ([[_back], _backProduced] select (_backStatus isEqualTo "Bounced")) + _strays, []]
