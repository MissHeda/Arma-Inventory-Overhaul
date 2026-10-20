#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * One line of the RPT for what a part of ACE Arsenal's opening and settling cost, for "Log window timings
 * (debug)" (einv_gui_debugTiming): "timing: arsenal open - settle/stageOverflow 3.2 ms (+412 ms since the
 * display opened)". Nothing is written while the setting is off, nor for a part under 0.5 ms unless it is
 * a total (the passes that run a few ms a frame say what they spent in all). The first lines after the
 * display opened say where the seconds of opening go: the lines of this addon sum up what is ours, the
 * rest of the wait is ACE's own filling of its lists.
 *
 * Arguments:
 * 0: The part <STRING>
 * 1: diag_tickTime when it began <NUMBER>
 * 2: More to say, appended in brackets <STRING> (default: "")
 * 3: A total over several frames, written whatever it took <BOOL> (default: false)
 *
 * Return Value:
 * None
 *
 * Example:
 * ["settle/ungrey", _begin] call einv_arsenal_fnc_noteOpen;
 *
 * Public: No
 */

params [["_part", "", [""]], ["_begin", 0, [0]], ["_more", "", [""]], ["_total", false, [false]]];

if !(missionNamespace getVariable [QEGVAR(gui,debugTiming), false]) exitWith {};

private _now = diag_tickTime;
private _took = (_now - _begin) * 1000;

if (_took < 0.5 && {!_total}) exitWith {};

private _since = (_now - GVAR(openedAt)) * 1000;
private _tail = ["", " [" + _more + "]"] select (_more isNotEqualTo "");

INFO_4("timing: arsenal open - %1 %2 ms (+%3 ms since the display opened)%4",_part,_took toFixed 1,_since toFixed 0,_tail);
