#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Once a frame from fnc_onFrame: runs every key of fnc_coalesce whose time has come (at most one run per key, with the latest
 * request) and forgets the keys that are idle and no longer resting, so the table stays as short as what is being clicked.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call einv_gui_fnc_coalesceTick;
 *
 * Public: No
 */

if (count GVAR(coalesced) == 0) exitWith {};

private _now = diag_tickTime;

{
    private _key = _x;
    private _state = GVAR(coalesced) getOrDefault [_key, []];

    if (_state isEqualTo []) then {continue};

    private _due = _state select 2;

    if (_due >= 0) then {
        if (_now >= _due) then {
            [_key] call FUNC(coalesceRun);
        };
    } else {
        if (_now >= (_state select 3)) then {
            GVAR(coalesced) deleteAt _key;
        };
    };
} forEach (keys GVAR(coalesced));
