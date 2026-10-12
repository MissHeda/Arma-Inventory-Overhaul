#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * "Give back all": every tile of a class in the soldier's uniform, vest and backpack goes back. What is
 * not offered here (or holds something that is not) asks for the second click once for all of them.
 *
 * Arguments:
 * 0: Class <STRING>
 *
 * Return Value:
 * Given back <BOOL>
 *
 * Example:
 * ["ACE_fieldDressing"] call einv_arsenal_fnc_giveBackAll;
 *
 * Public: No
 */

params [["_class", "", [""]]];

private _unit = GVAR(center);

if (_class isEqualTo "" || {isNull _unit}) exitWith {false};

private _key = toLowerANSI _class;
private _found = [];

// Every tile of it, as the window shows it.
{
    if (!isNull _x) then {
        private _container = _x;
        private _layout = [_container, [_container] call EFUNC(storage,getContents)] call EFUNC(storage,getLayout);
        private _all = (_layout get "entries") + ((_layout getOrDefault ["overflow", []]) select {!(_x in (_layout get "entries"))});

        {
            if (toLowerANSI (_x getOrDefault ["class", ""]) isEqualTo _key) then {
                _found pushBack [_container, _x];
            };
        } forEach _all;
    };
} forEach [uniformContainer _unit, vestContainer _unit, backpackContainer _unit];

if (_found isEqualTo []) exitWith {false};

private _name = [_class] call EFUNC(gui,itemName);

if ((_found findIf {[_x select 1] call FUNC(isUnique)}) >= 0) then {
    private _text = if ([_class] call FUNC(isUnique)) then {
        format [LLSTRING(Hint_ConfirmUnique), _name]
    } else {
        format [LLSTRING(Hint_ConfirmContents), _name]
    };

    if !([format ["giveAll|%1", _key], _text] call FUNC(arm)) then {
        _found = [];
    };
};

if (_found isEqualTo []) exitWith {false};

private _total = 0;

{
    _x params ["_container", "_entry"];

    private _n = _entry getOrDefault ["count", 1];

    if ([[_container, _entry], -1, true] call FUNC(giveBack)) then {
        _total = _total + _n;
    };
} forEach _found;

if (_total == 0) exitWith {false};

[_class, -1, _total] call FUNC(aceCargoEvent);
["giveBack"] call EFUNC(gui,playSound);

[format [LLSTRING(Hint_GivenBack), [_name, format ["%1× %2", _total, _name]] select (_total > 1)]] call FUNC(message);

call EFUNC(gui,requestRebuild);

true
