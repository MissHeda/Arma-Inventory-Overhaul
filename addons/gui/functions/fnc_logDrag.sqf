#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Writes the RPT line of a drag's timings (einv_gui_debugTiming) and forgets them: the lift, how many frames the
 * drag lasted, what a frame cost on average and at most, which parts the slowest one went to, and in how many the
 * target was worked out anew (fnc_startDrag, fnc_updateDrag). Nothing when the setting was off at the lift or the
 * line is written already.
 *
 * Where a drag ends - fnc_endDrag, and fnc_build and fnc_onUnload, which end it without fnc_endDrag (a rebuild, the
 * window closing by Escape, the Gear key or another mod): the line is not lost with them.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call einv_gui_fnc_logDrag;
 *
 * Public: No
 */

private _timing = GVAR(dragRoom) getOrDefault ["timing", []];

if (_timing isEqualTo []) exitWith {};

GVAR(dragRoom) deleteAt "timing";

_timing params ["_lift", "_frames", "_total", "_slowest", "_parts", "_anew"];

private _start = _lift toFixed 1;
private _average = (_total / (_frames max 1)) toFixed 2;
private _most = (_slowest max 0) toFixed 2;

INFO_6("timing: drag %3 ms avg, %4 ms max over %2 frames (start %1 ms; slowest frame: %5; target worked out anew in %6 frames)",_start,_frames,_average,_most,_parts,_anew);
