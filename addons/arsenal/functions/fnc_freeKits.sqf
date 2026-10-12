#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Frees the instance ids of Enhanced First Aid Kits' kits among classes that left the soldier. EFAK frees
 * them when a kit leaves by its own paths; giving back is none, and a long session would run the pool dry.
 * Skipped for a class the soldier still carries, and without EFAK.
 *
 * An element of the list may also be a payload (einv_storage_fnc_removeEntry, fnc_takeOff) or a snapshot
 * of a container: every class in it, nested containers included, is looked at.
 *
 * Arguments:
 * 0: Classes of everything that was destroyed, contents included - or the payloads <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [["efak_IFAK_7"]] call einv_arsenal_fnc_freeKits;
 *
 * Public: No
 */

params [["_classes", [], [[]]]];

// Without EFAK there is nothing to free.
if (isNil "efak_core_fnc_freeInstance" || {isNil "efak_core_prototypeOf"} || {isNil "efak_core_needsConversion"}) exitWith {};

private _all = [];

// A weapon array: its class, its parts and the magazines in it.
private _fnc_weapon = {
    params ["_weapon"];

    {
        private _part = if (_x isEqualType []) then {_x param [0, ""]} else {_x};

        if (_part isEqualType "" && {_part isNotEqualTo ""}) then {
            _all pushBack _part;
        };
    } forEach _weapon;
};

// What a container held: items, magazines, weapons, backpacks and the containers in it, each with a
// snapshot of its own.
private _fnc_snapshot = {
    params ["_snapshot"];

    _snapshot params [
        ["_items", [[], []], [[]]], ["_magazines", [], [[]]], ["_weapons", [], [[]]],
        ["_backpacks", [[], []], [[]]], ["_nested", [], [[]]]
    ];

    _all append (_items param [0, [], [[]]]);
    _all append (_backpacks param [0, [], [[]]]);

    {
        _all pushBack (_x param [0, ""]);
    } forEach _magazines;

    {
        [_x] call _fnc_weapon;
    } forEach _weapons;

    {
        _all pushBack (_x param [0, ""]);
        [_x param [2, [], [[]]]] call _fnc_snapshot;
    } forEach _nested;
};

{
    if (_x isEqualType "") then {
        _all pushBack _x;
    } else {
        if (_x isEqualType []) then {
            private _payload = _x;

            switch (_payload param [0, ""]) do {
                case "item": {
                    _all pushBack (_payload param [1, ""]);
                    [_payload param [3, [], [[]]]] call _fnc_snapshot;
                };
                case "backpack": {
                    _all pushBack (_payload param [1, ""]);
                    [_payload param [2, [], [[]]]] call _fnc_snapshot;
                };
                case "weapon": {[_payload param [1, [], [[]]]] call _fnc_weapon};
                case "magazine": {_all pushBack (_payload param [1, ""])};
                default {};
            };
        };
    };
} forEach _classes;

// Only instances, once each: a prototype has no id yet.
private _kits = createHashMap;

{
    private _lc = toLowerANSI _x;

    if (_x isNotEqualTo "" && {_lc in efak_core_prototypeOf} && {!(_lc in efak_core_needsConversion)}) then {
        _kits set [_lc, _x];
    };
} forEach _all;

if (count _kits == 0) exitWith {};

// A kit the soldier still carries keeps its id - a copy of the id in use must not be freed (EFAK's own rule
// when it restores a loadout).
private _carried = [];

if (!isNil "efak_core_fnc_getCarriedKits") then {
    _carried = ([GVAR(center)] call efak_core_fnc_getCarriedKits) apply {toLowerANSI _x};
};

{
    if !(_x in _carried) then {
        [_y] call efak_core_fnc_freeInstance;
    };
} forEach _kits;
