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
 * What lies in a uniform, vest or backpack that the settings "Use items from ..." close to it does not
 * count (aio_storage_fnc_useCarried): the slot shows what can be used.
 *
 * Arguments:
 * 0: Class <STRING>
 * 1: What the unit carries, [items, magazines, magazinesAmmoFull] - read once for several classes
 *    (fnc_counts); [] to read it here <ARRAY> (default: [])
 * 2: The same without what lies in a container that cannot be used from - [] to work it out here <ARRAY>
 *    (default: [])
 *
 * Return Value:
 * Count <NUMBER>
 *
 * Example:
 * ["ACE_elasticBandage"] call aio_hotbar_fnc_count;
 *
 * Public: No
 */

params [["_class", "", [""]], ["_carried", [], [[]]], ["_usable", [], [[]]]];

private _unit = PLAYER_UNIT;

if (_class isEqualTo "" || {isNull _unit}) exitWith {0};

([_class] call FUNC(useOf)) params ["_kind", "_data"];

if (_kind isEqualTo "") exitWith {0};

// Kits are the one thing counted by Enhanced First Aid Kits itself - less those in a container that cannot
// be used from.
if (_kind isEqualTo "kit") exitWith {
    if (isNil "efak_core_fnc_getCarriedKits") exitWith {0};

    private _prototype = _data;
    private _kits = [_unit] call efak_core_fnc_getCarriedKits;

    _kits = ([_unit, [_kits]] call EFUNC(storage,useCarried)) select 0;

    {([_x] call efak_core_fnc_getPrototype) == _prototype} count _kits
};

if (_carried isEqualTo []) then {
    _carried = [items _unit, magazines _unit, magazinesAmmoFull _unit];
};

// What can be used: the same lists less what lies in a container the settings close (as they are while none).
if (_usable isEqualTo []) then {
    _usable = [_unit, _carried] call EFUNC(storage,useCarried);
};

_usable params ["_items", "_magazines", "_ammoFull"];

// How many of one class lie in uniform, vest and backpack - as items or as magazines, whichever it is - in
// one set of the lists.
private _fnc_have = {
    params ["_item", "_lists"];

    if (isClass (configFile >> "CfgMagazines" >> _item)) then {
        {_x == _item} count (_lists select 1)
    } else {
        {_x == _item} count (_lists select 0)
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
            _sum = _sum + ([_x, _usable] call _fnc_have);
        } forEach _data;

        _sum
    };
    case "medical": {
        // The kits of Enhanced First Aid Kits count too: ACE's treatments take the items out of them. Its count
        // knows nothing of the settings, so what lies in a closed container is taken off it.
        if (!isNil "efak_medical_fnc_countItem") then {
            ([_unit, _class] call efak_medical_fnc_countItem) - ([_class, _carried] call _fnc_have) + ([_class, _usable] call _fnc_have)
        } else {
            [_class, _usable] call _fnc_have
        }
    };
    default {0};
}
