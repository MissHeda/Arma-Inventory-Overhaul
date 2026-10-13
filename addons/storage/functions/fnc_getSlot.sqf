#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What a unit has in one of its equipment slots, as an entry like those of fnc_getContents - so a
 * slot's item can be weighed (fnc_getMass) and laid on a grid like any tile.
 *
 * Slot ids: primary, handgun, launcher, binocular, headgear, goggles, nvg, uniform, vest, backpack,
 * map, gps, radio, compass, watch - and a weapon's parts as <weapon>_<part>, part being muzzle, rail,
 * optic, bipod, mag (the loaded magazine) or mag2 (the second muzzle's, e.g. a grenade launcher's).
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Slot id <STRING>
 *
 * Return Value:
 * Entry, or an empty HashMap when the slot is empty <HASHMAP>
 *
 * Example:
 * [player, "primary_optic"] call einv_storage_fnc_getSlot;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_slotId", "", [""]]];

if (isNull _unit) exitWith {createHashMap};

(_slotId splitString "_") params [["_base", ""], ["_part", ""]];

private _value = ([_unit] call FUNC(getEquipment)) getOrDefault [_base, ""];
private _class = "";
private _ammo = 0;
private _attachments = [];
private _inside = objNull;

if (_base in ["primary", "handgun", "launcher"]) then {
    if (_value isEqualTo []) exitWith {};

    if (_part isEqualTo "") exitWith {
        _class = _value select 0;
        _attachments = _value;
    };

    private _index = ["", "muzzle", "rail", "optic", "mag", "mag2", "bipod"] find _part;
    private _thing = _value param [_index, ""];

    if (_thing isEqualType [] && {_thing isNotEqualTo []}) then {
        _class = _thing select 0;
        _ammo = _thing param [1, 0];
    };

    if (_thing isEqualType "") then {
        _class = _thing;
    };
} else {
    // The binocular comes as a weapon array: only its class goes on the slot.
    if (_value isEqualType []) then {
        _value = _value param [0, ""];
    };

    _class = _value;

    _inside = switch (_base) do {
        case "uniform": {uniformContainer _unit};
        case "vest": {vestContainer _unit};
        case "backpack": {backpackContainer _unit};
        default {objNull};
    };
};

if (_class isEqualTo "") exitWith {createHashMap};

private _info = [_class] call EFUNC(items,getInfo);

(_info get "size") params ["_w", "_h"];

createHashMapFromArray [
    ["class", _class],
    ["count", 1],
    ["ammo", _ammo],
    ["capacity", _info get "capacity"],
    ["attachments", _attachments],
    ["container", _inside],
    ["w", _w],
    ["h", _h],
    ["slot", _slotId]
]
