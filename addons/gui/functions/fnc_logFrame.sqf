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
 * A second line follows it: "timing: frame parts - whole frame 4.02 ms avg 9.80 max (249 fps) / start 0.011 ms
 * avg 0.05 max / hover ... / search ... / contents 0.004 ms avg 3.10 max / ... - 1432 controls on the display,
 * 1011 shown; 96 tiles, 310 cell squares (180 shown)". The whole frame is the time from one frame of the window
 * to the next, so the game's FPS; each part is the script's time in that part of fnc_onFrame (fnc_notePhase),
 * on average per frame and the most one stretch of it took (the contents check runs once a second, so its
 * average is small and its most is the stutter). The controls are what the engine draws every frame.
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

// Where the time went, per part of the frame, and what the display holds.
private _phases = GVAR(phaseTally);

GVAR(phaseTally) = createHashMap;

if (count _phases == 0) exitWith {};

private _phaseParts = [];

(_phases getOrDefault ["frame", []]) params [["_wholeTotal", 0], ["_wholeMost", 0], ["_wholeCount", 0]];

if (_wholeCount > 0) then {
    private _wholeAvg = _wholeTotal / _wholeCount;

    _phaseParts pushBack format [
        "whole frame %1 ms avg %2 max (%3 fps)", _wholeAvg toFixed 2, _wholeMost toFixed 2, round (1000 / (_wholeAvg max 0.001))
    ];
};

{
    if (_x isEqualTo "frame") then {continue};

    _y params ["_total", "_most"];

    _phaseParts pushBack format ["%1 %2 ms avg %3 max", _x, (_total / _frames) toFixed 3, _most toFixed 2];
} forEach _phases;

// What the engine goes through every frame: the display's controls, and of those the tiles' and the cells'.
private _display = uiNamespace getVariable [QGVAR(display), displayNull];
private _counts = "";

if (!isNull _display) then {
    private _all = allControls _display;
    private _tiles = 0;
    private _squares = 0;
    private _squaresShown = 0;

    {
        _tiles = _tiles + count (_x getOrDefault ["tiles", []]);

        {
            if (!isNull _x) then {
                _squares = _squares + 1;

                if (ctrlShown _x) then {
                    _squaresShown = _squaresShown + 1;
                };
            };
        } forEach (_x getOrDefault ["cells", []]);
    } forEach (uiNamespace getVariable [QGVAR(grids), []]);

    _counts = format [
        " - %1 controls on the display, %2 shown; %3 tiles, %4 cell squares (%5 shown)",
        count _all, {ctrlShown _x} count _all, _tiles, _squares, _squaresShown
    ];
};

INFO_2("timing: frame parts - %1%2",_phaseParts joinString " / ",_counts);
