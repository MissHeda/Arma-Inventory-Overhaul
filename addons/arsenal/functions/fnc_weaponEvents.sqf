#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Raises ace_arsenal_weaponItemChanged for every part of a weapon, unchanged itself, that differs from the
 * last build. Quiet after a loadout, an import or a swap of the weapon, which ACE raises nothing for.
 *
 * The parts are told as ACE numbers them: 0 muzzle, 1 side, 2 optic, 3 bipod, 4 magazine, 5 second magazine.
 *
 * Arguments:
 * 0: Only remember what is there <BOOL> (default: false)
 *
 * Return Value:
 * None
 *
 * Example:
 * call einv_arsenal_fnc_weaponEvents;
 *
 * Public: No
 */

params [["_quiet", false, [false]]];

private _unit = GVAR(center);

if (isNull _unit) exitWith {};

private _equipment = [_unit] call EFUNC(storage,getEquipment);

// Each weapon as [class, [muzzle, side, optic, bipod, magazine, second magazine]], the parts as classes.
private _now = ["primary", "handgun", "launcher", "binocular"] apply {
    private _weapon = _equipment getOrDefault [_x, []];

    if (_weapon isEqualTo []) then {
        ["", ["", "", "", "", "", ""]]
    } else {
        [
            _weapon param [0, ""],
            [
                _weapon param [1, ""], _weapon param [2, ""], _weapon param [3, ""], _weapon param [6, ""],
                (_weapon param [4, []]) param [0, ""], (_weapon param [5, []]) param [0, ""]
            ]
        ]
    }
};

private _last = GVAR(lastWeapons);

if (!_quiet && {count _last == count _now}) then {
    {
        _x params ["_class", "_parts"];
        (_last select _forEachIndex) params ["_lastClass", "_lastParts"];

        // Another weapon in the slot is a swap: ACE raises nothing for it.
        if (_class isNotEqualTo "" && {_class isEqualTo _lastClass}) then {
            {
                if (_x isNotEqualTo (_lastParts select _forEachIndex)) then {
                    [QACEGVAR(arsenal,weaponItemChanged), [_class, _x, _forEachIndex]] call CBA_fnc_localEvent;
                };
            } forEach _parts;
        };
    } forEach _now;
};

GVAR(lastWeapons) = _now;
