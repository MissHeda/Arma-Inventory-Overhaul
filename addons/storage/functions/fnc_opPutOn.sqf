#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Op "putOn": a payload onto a unit's slot (fnc_putOn) - the old item off, after which the slot must be
 * empty (else "Failed", nothing put on), the new one on, after which the slot must hold its class and a
 * magazine its rounds (else "Bounced", produced [old, input]). Done: produced [old] - [] as a
 * placeholder when nothing came off, a ref to which is "Skipped". An item the slot does not take
 * (fnc_slotAccepts) is "Failed" before anything changes. Whatever came off is handed on whatever the
 * status - also with "Failed", when part of the old item came off but the slot would not empty - so it
 * goes where the old item was to go, or is settled, never lost.
 *
 * Arguments:
 * 0: Args, [unit, slot id, payload or ref] <ARRAY>
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
 * [[player, "headgear", _payload], _context] call einv_storage_fnc_opPutOn;
 *
 * Public: No
 */

params [["_args", [], [[]]], ["_context", createHashMap, [createHashMap]]];

_args params [["_unit", objNull, [objNull]], ["_slot", "", [""]], ["_payload", [], [[]]]];

if (_payload isEqualTo []) exitWith {["Skipped", [], []]};
if (isNull _unit) exitWith {["Moved", [], []]};

private _class = if ((_payload param [0, ""]) isEqualTo "weapon") then {(_payload param [1, []]) param [0, ""]} else {_payload param [1, ""]};

if !(_class isEqualType "" && {[_unit, _slot, _class] call FUNC(slotAccepts)}) exitWith {["Failed", [], []]};

private _answer = [_unit, _slot, _payload] call FUNC(putOn);

if (isNil "_answer" || {!(_answer isEqualType [])}) then {
    _answer = ["Failed", []];
};

// [status, old item]. An answer that is a payload itself - a weapon, say - is the old item alone.
if !(count _answer == 2 && {(_answer select 0) in ["", "Failed", "Bounced"]} && {(_answer select 1) isEqualType []}) then {
    _answer = ["", _answer];
};

_answer params ["_status", "_old"];

switch (_status) do {
    case "": {["", [+_old], []]};
    case "Bounced": {["Bounced", [+_old, +_payload], []]};
    default {["Failed", [[], [+_old]] select (_old isNotEqualTo []), []]};
}
