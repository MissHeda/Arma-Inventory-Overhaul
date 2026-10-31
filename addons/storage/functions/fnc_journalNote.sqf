#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Notes in the journal of the phase running here (GVAR(journalKey)) what left a container and what
 * landed: "out" writes a payload down the moment it left - fnc_removeEntry, fnc_removeSameClass,
 * fnc_takeOff, the old item of fnc_putOn, the kit ops - and "in" marks one consumed the moment its add
 * was verified. A phase stopped by a script error hands every payload the op that was running took out
 * and did not land to settlement (fnc_phaseFinalize).
 *
 * The notes belong to the op running now. "in" takes the index "out" gave, or the payload itself: then
 * the latest note of that very payload this op has not marked yet - for an op that lands what a
 * function it called took out (op "move"). A payload no note of this op names was carried in from
 * elsewhere: nothing to mark.
 *
 * Nothing outside a phase: the Arsenal and Eden change their containers directly.
 *
 * Arguments:
 * 0: Kind - "out" or "in" <STRING>
 * 1: The payload ("out" or "in"), or the index "out" gave ("in") <ARRAY or NUMBER>
 *
 * Return Value:
 * The note's index in the journal entry, -1 outside a phase or for nothing to mark <NUMBER>
 *
 * Example:
 * ["out", _payload] call aio_storage_fnc_journalNote;
 *
 * Public: No
 */

params [["_kind", "", [""]], ["_payloadOrIndex", [], [[], 0]]];

if (!GVAR(executing) || {GVAR(journalKey) isEqualTo ""}) exitWith {-1};

private _entry = GVAR(journal) getOrDefault [GVAR(journalKey), []];

if ((_entry param [0, ""]) isNotEqualTo "running") exitWith {-1};

// [op, payload, landed]. The op running now is the one after those with a result.
private _notes = _entry select 4;
private _op = count (_entry select 1);
private _index = -1;

if (_kind isEqualTo "out") then {
    if (_payloadOrIndex isEqualType [] && {_payloadOrIndex isNotEqualTo []}) then {
        _notes pushBack [_op, +_payloadOrIndex, false];
        _index = count _notes - 1;
    };
} else {
    if (_kind isEqualTo "in") then {
        if (_payloadOrIndex isEqualType 0) then {
            _index = _payloadOrIndex;
        } else {
            for "_i" from (count _notes - 1) to 0 step -1 do {
                (_notes select _i) params ["_noteOp", "_payload", "_landed"];

                if (_noteOp == _op && {!_landed} && {_payload isEqualTo _payloadOrIndex}) exitWith {
                    _index = _i;
                };
            };
        };

        if (_index >= 0 && {_index < count _notes}) then {
            (_notes select _index) set [2, true];
        } else {
            _index = -1;
        };
    };
};

_index
