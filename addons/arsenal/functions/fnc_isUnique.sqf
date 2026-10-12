#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether something the soldier carries is not offered by this arsenal: its class, its base for weapons and
 * backpacks and its layout key are all missing from the supply. Kept per class until the supply changes.
 *
 * Given an entry (a tile of the window or the item in a slot) instead of a class, it asks about everything
 * that would leave with it: the item, a weapon's parts and loaded magazines, and what a uniform, vest or
 * backpack holds, containers inside containers included. True when any of it is unique.
 *
 * Arguments:
 * 0: Class, or an entry as einv_storage_fnc_getContents gives it <STRING or HASHMAP>
 *
 * Return Value:
 * Unique <BOOL>
 *
 * Example:
 * ["arifle_MX_F"] call einv_arsenal_fnc_isUnique;
 *
 * Public: No
 */

params [["_what", "", ["", createHashMap]]];

private _stamp = GVAR(availableStamp);

// What was found out holds until the supply changes.
if ((GVAR(uniqueCache) getOrDefault ["#stamp", -1]) != _stamp) then {
    GVAR(uniqueCache) = createHashMapFromArray [["#stamp", _stamp]];
};

// An entry: every class that would leave with it.
if (_what isEqualType createHashMap) exitWith {
    private _classes = [];

    private _fnc_collect = {
        params ["_entry"];

        _classes pushBack (_entry getOrDefault ["class", ""]);

        {
            private _part = if (_x isEqualType []) then {_x param [0, ""]} else {_x};

            if (_part isEqualType "" && {_part isNotEqualTo ""}) then {
                _classes pushBack _part;
            };
        } forEach ((_entry getOrDefault ["attachments", []]) select [1]);

        private _inside = _entry getOrDefault ["container", objNull];

        if (!isNull _inside) then {
            {
                [_x] call _fnc_collect;
            } forEach ([_inside] call EFUNC(storage,getContents));
        };
    };

    [_what] call _fnc_collect;

    (_classes findIf {_x isNotEqualTo "" && {[_x] call FUNC(isUnique)}}) >= 0
};

private _class = _what;

if (_class isEqualTo "") exitWith {false};

private _lc = toLowerANSI _class;
private _known = GVAR(uniqueCache) get _lc;

if (!isNil "_known") exitWith {_known};

private _available = GVAR(availableLc);

// Nothing is known to be offered (no session): nothing is unique.
if (count _available == 0) exitWith {false};

// Everything the catalog lists counts as offered as well: with ACE Arsenal Extended it lists variants that
// the flat list of ACE does not hold.
private _flatEntry = GVAR(lists) getOrDefault ["#flat", []];

if ((_flatEntry param [0, -1]) != _stamp) then {
    private _set = createHashMap;
    private _items = GVAR(catalogItems);

    if !(_items isEqualType createHashMap) then {
        _items = missionNamespace getVariable [QACEGVAR(arsenal,virtualItems), createHashMap];
    };

    private _fnc_add = {
        params ["_map"];

        {
            if (isNil "_y") then {
                _set set [toLowerANSI _x, true];
            } else {
                if (_y isEqualType createHashMap) then {
                    [_y] call _fnc_add;
                };
            };
        } forEach _map;
    };

    [_items] call _fnc_add;
    _flatEntry = [_stamp, _set];
    GVAR(lists) set ["#flat", _flatEntry];
};

private _flat = _flatEntry param [1, createHashMap];

private _fnc_offered = {
    params ["_given"];

    private _name = toLowerANSI _given;

    _name in _available || {_name in _flat}
};

private _offered = [_class] call _fnc_offered;

// A radio or kit instance counts for the base it was made from.
if (!_offered) then {
    _offered = [[_class] call EFUNC(storage,layoutKey)] call _fnc_offered;
};

// A weapon with attachments in its class, its base weapon.
if (!_offered && {!isNil QACEFUNC(arsenal,baseWeapon)}) then {
    _offered = [_class call ACEFUNC(arsenal,baseWeapon)] call _fnc_offered;
};

// A backpack with contents in its class, the plain one.
if (!_offered && {isClass (configFile >> "CfgVehicles" >> _class)} && {!isNil "CBA_fnc_getNonPresetClass"}) then {
    _offered = [[_class, "CfgVehicles"] call CBA_fnc_getNonPresetClass] call _fnc_offered;
};

GVAR(uniqueCache) set [_lc, !_offered];

!_offered
