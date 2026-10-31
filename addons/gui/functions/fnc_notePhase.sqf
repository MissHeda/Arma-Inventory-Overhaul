#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Where a timed frame's time goes, for "Log window timings (debug)" (aio_gui_debugTiming): the part of the
 * frame that ran until now is given what it took, and the next part begins. fnc_frame starts a frame with
 * the part "start" and ends it with ""; fnc_onFrame names each part where it begins (NOTE_PHASE: hover,
 * drag, search, queue, answers, the checks, the contents check and its redraws). Never called while the
 * setting is off - GVAR(phase) is nil then and NOTE_PHASE asks no more than that. fnc_logFrame writes the
 * tally (GVAR(phaseTally)) with the frames' line.
 *
 * Arguments:
 * 0: The part that begins now, "" for none <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["hover"] call aio_gui_fnc_notePhase;
 *
 * Public: No
 */

params [["_next", "", [""]]];

if (isNil QGVAR(phase)) exitWith {};

GVAR(phase) params ["_part", "_since"];

private _now = diag_tickTime;

if (_part isNotEqualTo "") then {
    private _took = (_now - _since) * 1000;
    private _record = GVAR(phaseTally) getOrDefault [_part, [0, 0]];

    _record set [0, (_record select 0) + _took];
    _record set [1, (_record select 1) max _took];
    GVAR(phaseTally) set [_part, _record];
};

GVAR(phase) = [_next, _now];
