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
 *   room, in the measure the kit's room is counted in (fnc_roomMode):
 *     "capacity" - that mod's masses (efak_core_fnc_getItemMass) against the kit's capacity - config
 *                  masses, never this mod's weight= rules, which that mod knows nothing of
 *     "cells"    - a rule or its config gives the kit a grid: free cells in it and nothing else
 *                  (fnc_hasCells, "NoRoom"); that mod's capacity no longer counts
 * Whether packing is switched on is asked before this (fnc_canDrop): a uniform taken off for an item
 * out of the kit may go back in all the same, as in that mod's own wearItem.
 *
 * Arguments:
 * 0: Kit class <STRING>
 * 1: Item class <STRING>
 * 2: How many <NUMBER> (default: 1)
 * 3: Rounds of the magazines, for the cells they take: one number for all, -1 for full, or one per
 *    magazine <NUMBER or ARRAY> (default: -1)
 *
 * Return Value:
 * [takes them, reason - "" when it does] <ARRAY>
 *
 * Example:
 * ["efak_IFAK_7", "ACE_fieldDressing", 3] call einv_compat_efak_fnc_canPack;
 *
 * Public: No
 */

params [["_kit", "", [""]], ["_class", "", [""]], ["_count", 1, [0]], ["_rounds", -1, [0, []]]];

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

// A grid of its own: its cells are all its room.
if (([_kit] call FUNC(roomMode)) isEqualTo "cells") exitWith {
    [[false, "NoRoom"], [true, ""]] select ([_kit, _class, _count, _rounds] call FUNC(hasCells))
};

private _mass = [_class] call EFAKFUNC(core,getItemMass);
// getUsedCapacity takes the kit's class (or a contents list, which reads the same - efak 1.1.2 checked), as getCapacity
// does: the shape every other caller uses (the window title, the hint and the inspect card, fnc_fillState).
private _free = ([_kit] call EFAKFUNC(core,getCapacity)) - ([_kit] call EFAKFUNC(core,getUsedCapacity));

if (_mass > 0 && {(floor ((_free + KIT_MASS_EPSILON) / _mass)) < _count}) exitWith {
    [false, localize "STR_efak_core_Error_NotEnoughSpace"]
};

[true, ""]
