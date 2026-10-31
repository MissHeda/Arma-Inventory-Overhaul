#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Keeps the count that a box's caption line shows for the hands' queue (GVAR(handBoxes), fnc_updateStatus): an entry
 * of the queue left it, either because its time was up and it was sent (fnc_runQueue) or because it was cancelled
 * (fnc_cancelQueued). When nothing of the box waits any more its record goes, and so does the chip the next time
 * fnc_updateStatus looks (fnc_animateStatus asks for it).
 *
 * Arguments:
 * 0: The queue entry that left <HASHMAP>
 * 1: It was sent - false: it was cancelled <BOOL> (default: true)
 *
 * Return Value:
 * None
 *
 * Example:
 * [_head, true] call einv_gui_fnc_boxStep;
 *
 * Public: No
 */

params [["_entry", createHashMap, [createHashMap]], ["_sent", true, [true]]];

private _box = _entry getOrDefault ["box", objNull];

if (isNull _box) exitWith {};

private _index = GVAR(handBoxes) findIf {(_x get "holder") isEqualTo _box};

if (_index < 0) exitWith {};

private _record = GVAR(handBoxes) select _index;

if (_sent) then {
    _record set ["done", (_record get "done") + 1];
} else {
    _record set ["total", ((_record get "total") - 1) max 0];
};

if ((_record get "done") >= (_record get "total")) then {
    GVAR(handBoxes) deleteAt _index;
};
