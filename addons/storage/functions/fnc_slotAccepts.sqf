#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether an item can go into one of a unit's equipment slots (ids as in fnc_getSlot): the right kind
 * of item, and for a weapon's parts one that fits the weapon in that slot - an attachment from its
 * compatible items, a magazine its muzzle takes. Never a slot ACRE2 keeps for itself (the dummy radio in
 * the radio slot, einv_compat_acre_fnc_isFixedSlot): every way to equip asks this - drag, Alt+click, menu,
 * double click.
 *
 * A part slot is answered from the item's kind first, before the weapon in it is looked up: a helmet is
 * no magazine, so the unit's loadout is not read at all. What a weapon takes is kept per weapon and slot
 * in GVAR(compatSets), class names in lower case, read from config once (config does not change during a
 * mission). A caller that asks about many slots in a row - the drag lighting every slot that takes the
 * item (einv_gui_fnc_showTargets) - hands in the unit's equipment, read once.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Slot id <STRING>
 * 2: Item class <STRING>
 * 3: The unit's equipment as fnc_getEquipment has it - read here when not given <HASHMAP> (default: empty)
 *
 * Return Value:
 * Fits <BOOL>
 *
 * Example:
 * [player, "primary_optic", "optic_Aco"] call einv_storage_fnc_slotAccepts;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_slotId", "", [""]], ["_class", "", [""]], ["_equipment", createHashMap, [createHashMap]]];

if (isNull _unit || {_class isEqualTo ""}) exitWith {false};

// ACRE2's radio slot (einv_compat_acre, only when that addon is loaded).
if (!isNil QEFUNC(compat_acre,isFixedSlot) && {[_unit, _slotId] call EFUNC(compat_acre,isFixedSlot)}) exitWith {false};

(_slotId splitString "_") params [["_base", ""], ["_part", ""]];

private _kind = ([_class] call EFUNC(items,getInfo)) get "kind";

if (_part isEqualTo "") exitWith {
    _kind isEqualTo (switch (_base) do {
        case "primary": {"rifle"};
        default {_base};
    })
};

// The kind decides before the weapon is looked up: only a magazine or grenade goes on a magazine slot,
// only an attachment of that kind on its own slot.
private _isMagazine = _part in ["mag", "mag2"];

if (_isMagazine && {!(_kind in ["magazine", "grenade"])}) exitWith {false};
if (!_isMagazine && {_kind isNotEqualTo _part}) exitWith {false};

if (count _equipment == 0) then {
    _equipment = [_unit] call FUNC(getEquipment);
};

private _weapon = (_equipment getOrDefault [_base, []]) param [0, ""];

if (_weapon isEqualTo "") exitWith {false};

// What the weapon takes in this slot, worked out once per weapon: the magazines of the slot's muzzle, or its
// compatible items (the same for every attachment slot).
private _setKey = (toLowerANSI _weapon) + (["|items", "|" + _part] select _isMagazine);
private _set = GVAR(compatSets) get _setKey;

if (isNil "_set") then {
    private _list = [];

    if (_isMagazine) then {
        private _muzzles = getArray (configFile >> "CfgWeapons" >> _weapon >> "muzzles");
        private _muzzle = if (_part isEqualTo "mag") then {"this"} else {
            (_muzzles select {_x != "this" && {_x != (_muzzles param [0, ""])}}) param [0, ""]
        };

        if (_muzzle isNotEqualTo "") then {
            _list = compatibleMagazines [_weapon, _muzzle];
        };
    } else {
        _list = [_weapon] call CBA_fnc_compatibleItems;
    };

    if (isNil "_list" || {!(_list isEqualType [])}) then {
        _list = [];
    };

    _set = createHashMapFromArray (_list apply {[toLowerANSI _x, true]});
    GVAR(compatSets) set [_setKey, _set];
};

(toLowerANSI _class) in _set
