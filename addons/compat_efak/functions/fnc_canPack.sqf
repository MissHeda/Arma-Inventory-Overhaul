#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether a kit takes so many of an item now - asked by the window before anything is sent
 * (fnc_canDrop) and again right before every write, by the kit op at the kit's authority, against the
 * kit as it is then (fnc_putIntoKit, fnc_opKitMove). In this order, with Enhanced First Aid Kits' words
 * where it has them:
 *   its contents have not reached this machine yet - it would look empty (fnc_notReady)
 *   a kit nobody has carried yet - it has no contents of its own
 *   the kit itself, or a kit it is packed in - a kit in itself would be lost for good
 *   that mod's rules for the kit: kits in kits, its list, its types, medical only, its defaults
 *   (efak_core_fnc_canPackItem)
 *   no more than its default contents, where the mission limits it to them
 *   room: that mod's masses (efak_core_fnc_getItemMass) against the kit's capacity - config masses,
 *   never this mod's weight= rules, which that mod knows nothing of
 * Whether packing is switched on is asked before this (fnc_canDrop): a uniform taken off for an item
 * out of the kit may go back in all the same, as in that mod's own wearItem.
 *
 * Arguments:
 * 0: Kit class <STRING>
 * 1: Item class <STRING>
 * 2: How many <NUMBER> (default: 1)
 *
 * Return Value:
 * [takes them, reason - "" when it does] <ARRAY>
 *
 * Example:
 * ["efak_IFAK_7", "ACE_fieldDressing", 3] call einv_compat_efak_fnc_canPack;
 *
 * Public: No
 */

params [["_kit", "", [""]], ["_class", "", [""]], ["_count", 1, [0]]];

private _wait = call FUNC(notReady);

if (_wait isNotEqualTo "") exitWith {[false, _wait]};

if (toLowerANSI _kit in (missionNamespace getVariable [QEFAKGVAR(core,needsConversion), createHashMap])) exitWith {
    [false, localize "STR_efak_gui_Error_NotOpenedYet"]
};

if ([_class, _kit] call FUNC(contains)) exitWith {[false, LLSTRING(NotIntoItself)]};

([_kit, _class, 1, true] call EFAKFUNC(core,canPackItem)) params ["_allowed", "_reason"];

if (!_allowed) exitWith {[false, [_reason, localize "STR_efak_gui_Row_NotAllowed"] select (_reason isEqualTo "")]};

private _contents = [_kit] call EFAKFUNC(core,getContents);
private _limit = [_kit, _class] call EFAKFUNC(core,getPackLimit);

if (_limit >= 0 && {(([_contents, _class] call EFAKFUNC(core,countItem)) + _count) > _limit}) exitWith {
    [false, localize "STR_efak_core_Error_DefaultsReached"]
};

private _mass = [_class] call EFAKFUNC(core,getItemMass);
private _free = ([_kit] call EFAKFUNC(core,getCapacity)) - ([_contents] call EFAKFUNC(core,getUsedCapacity));

if (_mass > 0 && {(floor ((_free + KIT_MASS_EPSILON) / _mass)) < _count}) exitWith {
    [false, localize "STR_efak_core_Error_NotEnoughSpace"]
};

[true, ""]
