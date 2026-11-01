#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether an item can go into one of a unit's equipment slots (ids as in fnc_getSlot): the right kind
 * of item, and for a weapon's parts one that fits the weapon in that slot - an attachment from its
 * compatible items, a magazine its muzzle takes. Never a slot ACRE2 keeps for itself (the dummy radio in
 * the radio slot, aio_compat_acre_fnc_isFixedSlot): every way to equip asks this - drag, Alt+click, menu,
 * double click.
 *
 * A part slot is answered from the item's kind first, before the weapon in it is looked up: a helmet is
 * no magazine, so the unit's loadout is not read at all. What a weapon takes is kept per weapon and slot
 * in GVAR(compatSets), class names in lower case, read from config once (config does not change during a
 * mission). A caller that asks about many slots in a row - the drag lighting every slot that takes the
 * item (aio_gui_fnc_showTargets) - hands in the unit's equipment, read once.
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
 * [player, "primary_optic", "optic_Aco"] call aio_storage_fnc_slotAccepts;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_slotId", "", [""]], ["_class", "", [""]], ["_equipment", createHashMap, [createHashMap]]];

if (isNull _unit || {_class isEqualTo ""}) exitWith {false};

// ACRE2's radio slot (aio_compat_acre, only when that addon is loaded).
if (!isNil QEFUNC(compat_acre,isFixedSlot) && {[_unit, _slotId] call EFUNC(compat_acre,isFixedSlot)}) exitWith {false};

(_slotId splitString "_") params [["_base", ""], ["_part", ""]];

private _kind = ([_class] call EFUNC(items,getInfo)) get "kind";

// The second primary on the back (fnc_secondPrimary): a rifle, on a unit that has the slot, and one the mod
// lets go there - KJW's keeps lists of the weapons it allows.
if (_slotId isEqualTo "primary2") exitWith {
    _kind isEqualTo "rifle"
    && {(_equipment getOrDefault ["primary2", -1]) isEqualType [] || {([_unit] call FUNC(secondPrimary)) select 0}}
    && {[_unit, _class] call (GVAR(secondPrimaryMod) getOrDefault ["accepts", {true}])}
};

if (_part isEqualTo "") exitWith {
    _kind isEqualTo (switch (_base) do {
        case "primary": {"rifle"};
        default {_base};
    })
};

if (count _equipment == 0 && {_part in ["muzzle", "rail", "optic", "bipod", "mag", "mag2"]}) then {
    // The kind first, before the loadout is read: a helmet is no magazine.
    private _isMagazine = _part in ["mag", "mag2"];

    if (_isMagazine && {!(_kind in ["magazine", "grenade"])}) exitWith {};
    if (!_isMagazine && {_kind isNotEqualTo _part}) exitWith {};

    _equipment = [_unit] call FUNC(getEquipment);
};

// The weapon's part: the same check for a worn weapon as for one lying in a container (fnc_partFits), so what lights up green
// is what goes on.
[(_equipment getOrDefault [_base, []]) param [0, ""], _part, _class] call FUNC(partFits)
