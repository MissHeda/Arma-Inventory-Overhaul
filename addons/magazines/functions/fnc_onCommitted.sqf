#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The answer to the repack's transaction (the callback of fnc_commit): the status of its one op - "" done,
 * "Gone" a magazine was taken meanwhile, else a reason (out of reach, locked, not ready ...) - is handed to
 * fnc_finish. When it is done the window waits for the places it wrote to reach this machine, as it does for
 * its moves (aio_gui_fnc_onFrame), or at most ANSWER_WAIT seconds: the cargo can arrive before its places,
 * and a magazine would show on a first-fit cell for a moment.
 *
 * Arguments:
 * 0: Request id <STRING>
 * 1: Summary (aio_storage_fnc_onAnswer) <ARRAY>
 * 2: Revisions, [[holder, revision], ...] <ARRAY>
 * 3: The record fnc_commit gave along <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["2:14", _summary, _revisions, _record] call aio_magazines_fnc_onCommitted;
 *
 * Public: No
 */

params ["", ["_summary", [], [[]]], ["_revisions", [], [[]]], ["_record", createHashMap, [createHashMap]]];

if (count _record == 0) exitWith {};

// The first op of the first phase: [status, extra].
private _status = ((((_summary param [0, []]) param [0, []]) param [0, []]) param [0, "Failed", [""]]);

if (_status isNotEqualTo "" || {(_record get "why") isEqualTo "Closed"} || {isNull (uiNamespace getVariable [QEGVAR(gui,display), displayNull])}) exitWith {
    [_status, _record] call FUNC(finish);
};

// The places it wrote, read here: every revision named, or ANSWER_WAIT seconds.
[{
    params ["_revisions"];

    (_revisions findIf {
        _x params [["_holder", objNull, [objNull, ""]], ["_revision", 0, [0]]];

        (_holder isEqualType "" || {!isNull _holder}) && {(([_holder] call EFUNC(storage,readPlaces)) select 0) < _revision}
    }) < 0
}, {
    params ["", "_record"];

    ["", _record] call FUNC(finish);
}, [_revisions, _record], ANSWER_WAIT, {
    params ["", "_record"];

    ["", _record] call FUNC(finish);
}] call CBA_fnc_waitUntilAndExecute;
