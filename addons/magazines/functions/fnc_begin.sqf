#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Starts a repack of the parts given - magazines of one class, ascending by rounds - in the window. The
 * timing is ACE's own schedule (ace_magazinerepack_fnc_simulateRepackEvents, with ACE's settings: time
 * per round, per magazine, per belt link), the soldier goes down on one knee and does the gear gesture
 * as ACE's repack does (ace_common_fnc_goKneeling, doGesture, the repack animation setting), and the
 * checks ACE's progress bar makes every frame are made here too (fnc_onFrame). Nothing in the cargo
 * changes until the repack ends (fnc_stop, fnc_commit).
 *
 * The job is kept in GVAR(job); the window draws it on the tiles (fnc_drawJob) and the hands are busy
 * until it ends.
 *
 * Arguments:
 * 0: Magazine class <STRING>
 * 1: Parts, see fnc_ownPartials - ascending by rounds <ARRAY>
 * 2: Their root, whose authority writes the result (einv_storage_fnc_rootOf) <OBJECT>
 *
 * Return Value:
 * Started <BOOL>
 *
 * Example:
 * ["30Rnd_65x39_caseless_mag", _parts, player] call einv_magazines_fnc_begin;
 *
 * Public: No
 */

params [["_class", "", [""]], ["_parts", [], [[]]], ["_root", objNull, [objNull]]];

if (_class isEqualTo "" || {count _parts < 2} || {isNull _root} || {[] call FUNC(isBusy)}) exitWith {false};

private _info = [_class] call EFUNC(items,getInfo);
private _capacity = _info get "capacity";
private _isBelt = getNumber (configFile >> "CfgMagazines" >> _class >> "ACE_isBelt") == 1;
private _counts = _parts apply {_x select 2};

// ACE's own schedule. It sorts a copy of the counts; ours come sorted already, so its i-th count is our
// i-th part (alike counts are interchangeable).
private _events = [_capacity, _counts, _isBelt] call ACEFUNC(magazinerepack,simulateRepackEvents);

if (isNil "_events" || {!(_events isEqualType [])} || {_events isEqualTo []}) exitWith {false};

private _unit = EGVAR(gui,unit);

if !([_unit, objNull, REPACK_EXCEPTIONS] call ACEFUNC(common,canInteractWith)) exitWith {
    ["Failed"] call EFUNC(gui,flashHint);
    false
};

// As ACE starts its repack: down on one knee, the gear gesture when its setting wants it.
if (!isNil QACEFUNC(common,goKneeling)) then {
    [_unit] call ACEFUNC(common,goKneeling);
};

if (missionNamespace getVariable [QACEGVAR(magazinerepack,repackAnimation), true] && {!isNil QACEFUNC(common,doGesture)}) then {
    [_unit, "Gear"] call ACEFUNC(common,doGesture);
};

GVAR(job) = createHashMapFromArray [
    ["unit", _unit], ["class", _class], ["name", _info get "name"], ["picture", _info get "picture"],
    ["capacity", _capacity], ["root", _root], ["parts", _parts], ["events", _events],
    ["total", ((_events select -1) select 0) max 0.01], ["start", CBA_missionTime], ["done", 0],
    ["startCounts", +_counts], ["counts", +_counts], ["receiving", count _counts - 1], ["hintLeft", -1]
];

private _display = uiNamespace getVariable [QEGVAR(gui,display), displayNull];

// Hands busy: nothing lights up under the mouse meanwhile, the name at the mouse goes.
[_display, [], true] call EFUNC(gui,updateHover);
[_display] call FUNC(drawJob);

true
