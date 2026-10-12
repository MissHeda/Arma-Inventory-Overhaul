#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * How many of what a class stands for the player carries - the number on its slot. What counts depends
 * on what the class does (fnc_useOf):
 *
 *   throw    - the grenades of that class
 *   reload   - the magazines of that class with rounds in them, the loaded one not among them
 *   medical  - the items of that class; with Enhanced First Aid Kits also those in kits that may be used
 *              for treatment (efak_medical_fnc_countItem)
 *   consume  - all of the chain: the full bottle and the half one
 *   kit      - the kits of that type
 *
 * Arguments:
 * 0: Class <STRING>
 * 1: What the unit carries, [items, magazines, magazinesAmmoFull] - read once for several classes
 *    (fnc_counts); [] to read it here <ARRAY> (default: [])
 *
 * Return Value:
 * Count <NUMBER>
 *
 * Example:
 * ["ACE_elasticBandage"] call einv_hotbar_fnc_count;
 *
 * Public: No
 */

params [["_class", "", [""]], ["_carried", [], [[]]]];

private _unit = ACE_player;

if (_class isEqualTo "" || {isNull _unit}) exitWith {0};

([_class] call FUNC(useOf)) params ["_kind", "_data"];

if (_kind isEqualTo "") exitWith {0};

// Kits are the one thing counted by Enhanced First Aid Kits itself.
if (_kind isEqualTo "kit") exitWith {
    if (isNil "efak_core_fnc_getCarriedKits") exitWith {0};

    private _prototype = _data;

    {([_x] call efak_core_fnc_getPrototype) == _prototype} count ([_unit] call efak_core_fnc_getCarriedKits)
};

if (_carried isEqualTo []) then {
    _carried = [items _unit, magazines _unit, magazinesAmmoFull _unit];
};

_carried params ["_items", "_magazines", "_ammoFull"];

// How many of one class lie in uniform, vest and backpack - as items or as magazines, whichever it is.
private _fnc_have = {
    params ["_item"];

    if (isClass (configFile >> "CfgMagazines" >> _item)) then {
        {_x == _item} count _magazines
    } else {
        {_x == _item} count _items
    }
};

switch (_kind) do {
    case "throw": {
        {_x == _class} count _magazines
    };
    case "reload": {
        {(_x select 0) == _class && {!(_x select 2)} && {(_x select 1) > 0}} count _ammoFull
    };
    case "consume": {
        private _sum = 0;

        {
            _sum = _sum + ([_x] call _fnc_have);
        } forEach _data;

        _sum
    };
    case "medical": {
        // The kits of Enhanced First Aid Kits count too: ACE's treatments take the items out of them.
        if (!isNil "efak_medical_fnc_countItem") then {
            [_unit, _class] call efak_medical_fnc_countItem
        } else {
            [_class] call _fnc_have
        }
    };
    default {0};
}
