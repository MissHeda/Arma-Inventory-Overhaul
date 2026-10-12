#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * How many of each kind of item a soldier carries, counted by layout key - a radio instance counts for its
 * base radio, a kit for its prototype -, for the counts on the cards. What is worn and what is in the
 * uniform, vest and backpack counts, the parts on the weapons and the magazines loaded in them too, and
 * what lies in a container inside those.
 *
 * Also kept as GVAR(carried), which the catalog's cards read.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * Layout key -> count <HASHMAP>
 *
 * Example:
 * [player] call einv_arsenal_fnc_carriedCounts;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

private _counts = createHashMap;

if (isNull _unit) exitWith {
    GVAR(carried) = _counts;
    _counts
};

private _fnc_add = {
    params ["_class", ["_count", 1]];

    if (_class isEqualType "" && {_class isNotEqualTo ""}) then {
        private _key = [_class] call EFUNC(storage,layoutKey);

        _counts set [_key, (_counts getOrDefault [_key, 0]) + _count];
    };
};

// A weapon array: its class and everything on it.
private _fnc_weapon = {
    params ["_weapon"];

    {
        [[_x, _x param [0, ""]] select (_x isEqualType [])] call _fnc_add;
    } forEach _weapon;
};

// What a container holds, and what its containers hold.
private _fnc_container = {
    params ["_container"];

    {
        private _class = _x getOrDefault ["class", ""];
        private _inside = _x getOrDefault ["container", objNull];
        private _attachments = _x getOrDefault ["attachments", []];

        if (_attachments isNotEqualTo []) then {
            [_attachments] call _fnc_weapon;
        } else {
            [_class, _x getOrDefault ["count", 1]] call _fnc_add;
        };

        if (!isNull _inside) then {
            [_inside] call _fnc_container;
        };
    } forEach ([_container] call EFUNC(storage,getContents));
};

private _equipment = [_unit] call EFUNC(storage,getEquipment);

{
    private _worn = _equipment getOrDefault [_x, ""];

    if (_worn isEqualType []) then {
        [_worn] call _fnc_weapon;
    } else {
        [_worn] call _fnc_add;
    };
} forEach [
    "primary", "handgun", "launcher", "binocular", "uniform", "vest", "backpack", "headgear", "goggles",
    "map", "gps", "radio", "compass", "watch", "nvg"
];

{
    if (!isNull _x) then {
        [_x] call _fnc_container;
    };
} forEach [uniformContainer _unit, vestContainer _unit, backpackContainer _unit];

GVAR(carried) = _counts;

_counts
