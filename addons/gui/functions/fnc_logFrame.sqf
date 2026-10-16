#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Keeps the tally of what the window's frames cost in script (fnc_frame) and writes it to the RPT as one line
 * every FRAME_LOG_COUNT frames, when the window closes and when a drag starts:
 * "timing: frames idle 0.06 ms avg 0.45 max (n 800) / hover held 0.03 ms avg ... / drag ...". "hover held" is a
 * mouse moving inside the cell it was in, "hover same" one that came onto another cell or place but found
 * what it had found, "hover new" one that found something else (the name at the mouse, the hint and the
 * light are made then); a frame over 1 ms is counted as slow. The engine's drawing of the display's
 * controls is not in these figures - with the window idle, a frame of 3.2 ms and 0.06 ms of script says
 * where the rest goes.
 *
 * Arguments:
 * 0: What the frame was - "idle", "held", "same", "new", "drag"; "" writes the tally <STRING> (default: "")
 * 1: Milliseconds it took <NUMBER> (default: 0)
 *
 * Return Value:
 * None
 *
 * Example:
 * ["idle", 0.06] call einv_gui_fnc_logFrame;
 *
 * Public: No
 */

params [["_kind", "", [""]], ["_took", 0, [0]]];

if (isNil QGVAR(frameTiming)) then {
    GVAR(frameTiming) = createHashMap;
};

private _tally = GVAR(frameTiming);

if (_kind isNotEqualTo "") then {
    private _record = _tally getOrDefault [_kind, [0, 0, 0, 0]];

    _record set [0, (_record select 0) + 1];
    _record set [1, (_record select 1) + _took];
    _record set [2, (_record select 2) max _took];

    if (_took > 1) then {
        _record set [3, (_record select 3) + 1];
    };

    _tally set [_kind, _record];
};

private _frames = 0;

{
    _frames = _frames + (_y select 0);
} forEach _tally;

if (_frames == 0 || {_kind isNotEqualTo "" && {_frames < FRAME_LOG_COUNT}}) exitWith {};

private _parts = [];

{
    private _name = [_x, "hover " + _x] select (_x in ["held", "same", "new"]);

    _y params ["_count", "_total", "_most", "_slow"];

    _parts pushBack format [
        "%1 %2 ms avg %3 max (n %4, %5 over 1 ms)", _name, (_total / _count) toFixed 3, _most toFixed 2, _count, _slow
    ];
} forEach _tally;

INFO_1("timing: frames - %1",_parts joinString " / ");

GVAR(frameTiming) = createHashMap;
