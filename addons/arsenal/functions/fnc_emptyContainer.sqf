#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * "Empty": everything in a container goes back to the arsenal; what is not offered here asks for the second
 * click first. Nothing is raised as ACE's cargo event: its "Remove all" raises none either.
 *
 * Arguments:
 * 0: Container <OBJECT>
 *
 * Return Value:
 * Emptied <BOOL>
 *
 * Example:
 * [vestContainer player] call einv_arsenal_fnc_emptyContainer;
 *
 * Public: No
 */

params [["_container", objNull, [objNull]]];

if (isNull _container) exitWith {false};

// Everything on it, as the window shows it - the red row at the foot too.
private _layout = [_container, [_container] call EFUNC(storage,getContents)] call EFUNC(storage,getLayout);
private _entries = (_layout get "entries") + ((_layout getOrDefault ["overflow", []]) select {!(_x in (_layout get "entries"))});

if (_entries isEqualTo []) exitWith {false};

private _containerName = [_container] call EFUNC(gui,containerName);

if ((_entries findIf {[_x] call FUNC(isUnique)}) >= 0) then {
    if !([format ["empty|%1", netId _container], format [LLSTRING(Hint_ConfirmContents), _containerName]] call FUNC(arm)) then {
        _entries = [];
    };
};

if (_entries isEqualTo []) exitWith {false};

// What went, by class.
private _went = [];
private _counts = createHashMap;

{
    private _class = _x getOrDefault ["class", ""];
    private _n = _x getOrDefault ["count", 1];

    if ([[_container, _x], -1, true] call FUNC(giveBack)) then {
        if !(_class in _counts) then {
            _went pushBack _class;
        };

        _counts set [_class, (_counts getOrDefault [_class, 0]) + _n];
    };
} forEach _entries;

if (_went isEqualTo []) exitWith {false};

// "3× Bandage, 2× Mk20", and so on for the first few.
private _names = (_went select [0, 3]) apply {
    format ["%1× %2", _counts get _x, [_x] call EFUNC(gui,itemName)]
};

["giveBack"] call EFUNC(gui,playSound);

[format [LLSTRING(Hint_GivenBack), (_names joinString ", ") + (["", ", ..."] select (count _went > 3))]] call FUNC(message);

call EFUNC(gui,requestRebuild);

true
