#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Puts an item on the soldier: into the chosen target slot when it takes the class, else the slot that does
 * (einv_storage_fnc_slotFor); a magazine is loaded into the first weapon that takes it. Weapons and
 * containers go through the swaps (fnc_swapWeapon, fnc_swapContainer); nothing takes it, and one is added
 * instead.
 *
 * Anything else is put on with einv_storage_fnc_putOn: a full magazine, a bare weapon. What was in the slot
 * is thrown away when this arsenal offers it; what it does not offer is stored in a container with room,
 * and if there is none the second click throws it away (fnc_arm). A binocular whose config lists
 * magazines gets the first one that is offered, as BI's arsenal does. A weapon or binocular put on is held
 * by the soldier (fnc_showItem); the sound names the item (["equip", class]).
 *
 * Arguments:
 * 0: Class <STRING>
 * 1: Slot id, "" to choose <STRING> (default: "")
 *
 * Return Value:
 * Put on <BOOL>
 *
 * Example:
 * ["H_HelmetB"] call einv_arsenal_fnc_equipItem;
 *
 * Public: No
 */

params [["_class", "", [""]], ["_slot", "", [""]]];

private _unit = GVAR(center);

if (_class isEqualTo "" || {isNull _unit}) exitWith {false};

private _name = [_class] call EFUNC(gui,itemName);

// ----- Which slot -----
private _target = GVAR(targetSlot);

if (_slot isEqualTo "") then {
    _slot = _target;
};

if (_slot isNotEqualTo "") then {
    // A weapon's slot named for a magazine or a part goes on the part of that weapon that takes it.
    if !([_unit, _slot, _class] call EFUNC(storage,slotAccepts)) then {
        _slot = if (_slot in ["primary", "handgun", "launcher"]) then {[_unit, _slot, _class] call EFUNC(storage,partFor)} else {""};
    };
};

if (_slot isEqualTo "") then {
    _slot = [_unit, _class] call EFUNC(storage,slotFor);
};

// Nothing takes it: one is added.
if (_slot isEqualTo "") exitWith {
    private _added = [_class, 1] call FUNC(quickAdd);

    if (_added == 0) then {
        [format [LLSTRING(Hint_NoSlot), _name]] call EFUNC(gui,flashHint);
    };

    _added > 0
};

(_slot splitString "_") params ["_base"];

if (_slot in ["primary", "handgun", "launcher"]) exitWith {
    private _done = [_slot, _class] call FUNC(swapWeapon);

    // He holds what he was just given.
    if (_done) then {
        [_slot] call FUNC(showItem);
    };

    _done
};

if (_slot in ["uniform", "vest", "backpack"]) exitWith {
    [_slot, _class] call FUNC(swapContainer)
};

// ----- What is in the slot now -----
private _old = [_unit, _slot] call EFUNC(storage,getSlot);
private _oldClass = _old getOrDefault ["class", ""];

if (toLowerANSI _oldClass isEqualTo toLowerANSI _class) exitWith {true};

// Something the arsenal lacks must have a place, or the second click.
if (count _old > 0 && {[_old] call FUNC(isUnique)}) then {
    private _probe = ["item", _oldClass, 1, []];

    if (_base in ["binocular"]) then {
        _probe = ["weapon", [_oldClass, "", "", "", [], [], ""]];
    };

    if !([_probe, true] call FUNC(storeAway)) then {
        if !(["swap|" + _slot + "|" + _class, format [LLSTRING(Hint_ConfirmUnique), [_oldClass] call EFUNC(gui,itemName)]] call FUNC(arm)) then {
            _slot = "";
        };
    };
};

if (_slot isEqualTo "") exitWith {false};

// ----- On -----
private _payload = [_class, 1] call EFUNC(storage,makePayload);

([_unit, _slot, _payload] call EFUNC(storage,putOn)) params ["_status", "_taken"];

if (_status isNotEqualTo "") exitWith {
    // Whatever came off is put back: nothing may be lost.
    if (_taken isNotEqualTo []) then {
        if ((([_unit, _slot, _taken] call EFUNC(storage,putOn)) select 0) isNotEqualTo "") then {
            [_taken] call FUNC(storeAway);
        };
    };

    ["Failed"] call EFUNC(gui,flashHint);

    false
};

// What came off: gone when the arsenal has it, stored when it does not.
private _stored = false;

if (_taken isNotEqualTo [] && {count _old > 0} && {[_old] call FUNC(isUnique)}) then {
    _stored = [_taken] call FUNC(storeAway);
};

// A binocular with magazines of its own takes the first one that is offered.
if (_base isEqualTo "binocular") then {
    private _offered = (getArray (configFile >> "CfgWeapons" >> _class >> "magazines")) select {(toLowerANSI _x) in GVAR(availableLc)};

    if (_offered isNotEqualTo []) then {
        _unit addWeaponItem [_class, _offered select 0, true];
    };
};

["equip", _class] call EFUNC(gui,playSound);

if (_base isEqualTo "binocular") then {
    [_base] call FUNC(showItem);
};

if (_stored) then {
    [format [LLSTRING(Hint_StoredOld), [_oldClass] call EFUNC(gui,itemName), [(uiNamespace getVariable [QGVAR(column), createHashMap]) getOrDefault ["stored", objNull]] call EFUNC(gui,containerName)]] call FUNC(message);
} else {
    [format [LLSTRING(Hint_Added), _name]] call FUNC(message);
};

call EFUNC(gui,requestRebuild);

true
