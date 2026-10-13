#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * After a loadout or a container swap: whatever has no cell on the grid goes back to the arsenal. What
 * this arsenal does not offer is never removed: it stays as the red row at the foot of the container, and
 * so does a container that holds something it does not offer. Kit ids of what goes are freed.
 *
 * Works on the soldier's uniform, vest and backpack; says nothing itself - the caller tells what went back.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * What went back, [[class, how many], ...] <ARRAY>
 *
 * Example:
 * [player] call einv_arsenal_fnc_trimToFit;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

if (isNull _unit) exitWith {[]};

private _went = [];
private _counts = createHashMap;

// Gives one tile back, quietly, and notes it.
private _fnc_remove = {
    params ["_container", "_entry"];

    private _class = _entry getOrDefault ["class", ""];
    private _n = _entry getOrDefault ["count", 1];

    if !([[_container, _entry], -1, true] call FUNC(giveBack)) exitWith {false};

    if !(_class in _counts) then {
        _went pushBack _class;
    };

    _counts set [_class, (_counts getOrDefault [_class, 0]) + _n];

    true
};

{
    private _container = _x;

    if (isNull _container) then {continue};

    // 1. What has no cell.
    private _layout = [_container, [_container] call EFUNC(storage,getContents), false] call EFUNC(storage,getLayout);

    {
        if !([_x] call FUNC(isUnique)) then {
            [_container, _x] call _fnc_remove;
        };
    } forEach (_layout getOrDefault ["overflow", []]);
} forEach [uniformContainer _unit, vestContainer _unit, backpackContainer _unit];

if (_went isNotEqualTo []) then {
    call EFUNC(gui,requestRebuild);
};

_went apply {[_x, _counts get _x]}
