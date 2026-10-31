#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Where new things of a class would go on a unit's worn containers, without adding anything: for each
 * container of fnc_unitTargets, in that order, as many of what is left as its grid has room for
 * (fnc_hasRoom - free cells are the only limit, the stacks of its key that are not full first, a backpack
 * never into a backpack). The count that fits is found by halving, so a few layouts answer however many are
 * asked for. Read from the places and the cargo this machine has, which are the same picture everywhere:
 * the unit need not be local.
 *
 * What fnc_addToUnit adds, and what it reports for a unit that is local elsewhere.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Class <STRING>
 * 2: How many <NUMBER> (default: 1)
 * 3: Rounds in each magazine, -1 for full ones <NUMBER> (default: -1)
 *
 * Return Value:
 * [[container, how many], ...] in the order to add; empty when nothing fits <ARRAY>
 *
 * Example:
 * [player, "ACE_fieldDressing", 8] call einv_storage_fnc_addFit;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_class", "", [""]], ["_count", 1, [0]], ["_rounds", -1, [0]]];

if (isNull _unit || {_class isEqualTo ""} || {_count < 1}) exitWith {[]};

private _info = [_class] call EFUNC(items,getInfo);
private _capacity = _info getOrDefault ["capacity", 0];
private _ammo = [_capacity, (_rounds min _capacity) max 0] select (_rounds >= 0 && {_capacity > 0});

// Whether n of them fit into a container, as a tile of that many would lie there.
private _fnc_fits = {
    params ["_box", "_n"];

    [_box, createHashMapFromArray [
        ["class", _class], ["count", _n], ["ammo", _ammo], ["capacity", _capacity],
        ["attachments", []], ["container", objNull]
    ]] call FUNC(hasRoom)
};

private _plan = [];
private _left = _count;

{
    if (_left <= 0) exitWith {};

    private _box = _x;
    private _fit = 0;

    if ([_box, _left] call _fnc_fits) then {
        _fit = _left;
    } else {
        // Room for one at least: the most that fits lies between one and all of what is left.
        if ([_box, 1] call _fnc_fits) then {
            private _low = 1;
            private _high = _left;

            while {_high - _low > 1} do {
                private _mid = floor ((_low + _high) / 2);

                if ([_box, _mid] call _fnc_fits) then {
                    _low = _mid;
                } else {
                    _high = _mid;
                };
            };

            _fit = _low;
        };
    };

    if (_fit > 0) then {
        _plan pushBack [_box, _fit];
        _left = _left - _fit;
    };
} forEach ([_unit, _class] call FUNC(unitTargets));

_plan
