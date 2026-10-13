#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Op "takeOff": off a unit's slot (fnc_takeOff, the slot verified empty after) - produced the payload.
 * Its origin is the slot: unconsumed, it goes back on there while the slot is still empty, else into
 * the requester's vehicle or onto the ground (fnc_settle). An empty slot is "Gone"; one the engine would
 * not empty "Failed".
 *
 * Arguments:
 * 0: Args, [unit, slot id] <ARRAY>
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
 * [[player, "headgear"], _context] call einv_storage_fnc_opTakeOff;
 *
 * Public: No
 */

params [["_args", [], [[]]], ["_context", createHashMap, [createHashMap]]];

_args params [["_unit", objNull, [objNull]], ["_slot", "", [""]]];

if (isNull _unit) exitWith {["Moved", [], []]};
if (count ([_unit, _slot] call FUNC(getSlot)) == 0) exitWith {["Gone", [], []]};

private _payload = [_unit, _slot] call FUNC(takeOff);

if (isNil "_payload" || {!(_payload isEqualType [])}) then {
    _payload = [];
};

if (_slot isEqualTo "backpack" && {DROP_DEBUG}) then {
    diag_log text format [
        "einv drop: %1 phase %2 on %3 - takeOff %4 (settlement %5)",
        _context getOrDefault ["txId", ""], _context getOrDefault ["phase", -1], clientOwner,
        ["failed, nothing handed on", "handed on " + str (_payload param [1, ""])] select (_payload isNotEqualTo []),
        _context getOrDefault ["settlement", false]
    ];
};

if (_payload isEqualTo []) exitWith {["Failed", [], []]};

["", [_payload], []]
