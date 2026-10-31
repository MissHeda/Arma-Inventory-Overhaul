#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What the two buttons of a cargo card may do now, and why not when they may not: the first check that
 * applies decides, for each button on its own. ACE's rules for unloading, as its menu applies them:
 * nothing in a locked vehicle, nothing that cannot be unloaded, not from the air, only within reach. A
 * crate that is locked to the player may be unloaded - a lock is about what is inside - but not opened.
 *
 * Arguments:
 * 0: Vehicle or crate the thing is loaded in <OBJECT>
 * 1: The loaded thing - an object, or a class name for one ACE has not made yet <OBJECT or STRING>
 * 2: Unit <OBJECT>
 *
 * Return Value:
 * "canOpen" <BOOL>, "openTip" why not <STRING>, "isOpen" <BOOL>, "canUnload" <BOOL>, "unloadTip" why not
 * <STRING> <HASHMAP>
 *
 * Example:
 * [cursorObject, _crate, player] call einv_compat_ace_cargo_fnc_rowState;
 *
 * Public: No
 */

params [["_holder", objNull, [objNull]], ["_item", objNull, [objNull, ""]], ["_unit", objNull, [objNull]]];

private _isString = _item isEqualType "";
private _openTip = "";
private _unloadTip = "";

// Open: a locked vehicle, a thing that is not made yet, one with nothing to look into, one locked to us.
switch (true) do {
    case (locked _holder >= 2): {
        _openTip = LLSTRING(Tip_VehicleLocked);
    };
    case (_isString): {
        _openTip = LLSTRING(Tip_Packed);
    };
    // What a vehicle carries is no tile to uncover: the loot of the vehicle is searched first (einv_gui).
    case (!isNull (uiNamespace getVariable [QEGVAR(gui,display), displayNull]) && {[_holder] call EFUNC(gui,isSearched)} && {EGVAR(gui,searchQueue) findIf {(_x select 0) isEqualTo _holder} >= 0}): {
        _openTip = LLSTRING(Tip_Unsearched);
    };
    case (!alive _item || {maxLoad _item <= 0} || {getNumber (configOf _item >> "disableInventory") == 1}): {
        _openTip = LLSTRING(Tip_NoInventory);
    };
    default {
        ([_unit, _item] call EFUNC(locks,canReach)) params ["_ok", "_reason"];

        if (!_ok) then {
            _openTip = _reason;
        };
    };
};

// Unload: a locked vehicle, a size ACE cannot unload, the air, too far, another unload under way.
switch (true) do {
    case (locked _holder >= 2): {
        _unloadTip = LLSTRING(Tip_VehicleLocked);
    };
    case ((_item call ACEFUNC(cargo,getSizeItem)) < 0): {
        _unloadTip = localize "STR_ACE_Cargo_UnloadingImpossible";
    };
    case (_holder isKindOf "Air" && {!isTouchingGround _holder}): {
        _unloadTip = LLSTRING(Tip_InAir);
    };
    case (
        (vehicle _unit) isNotEqualTo _holder
        && {([_unit, _holder] call ACEFUNC(interaction,getInteractionDistance)) >= MAX_LOAD_DISTANCE}
    ): {
        _unloadTip = LLSTRING(Tip_TooFar);
    };
    case (GVAR(unloading) isNotEqualTo [] && {(GVAR(unloading) select 0) isNotEqualTo _item}): {
        _unloadTip = LLSTRING(Tip_Busy);
    };
};

createHashMapFromArray [
    ["canOpen", _openTip isEqualTo ""],
    ["openTip", _openTip],
    ["isOpen", !_isString && {EGVAR(gui,opened) findIf {(_x select 1) isEqualTo _item} >= 0}],
    ["canUnload", _unloadTip isEqualTo ""],
    ["unloadTip", _unloadTip]
]
