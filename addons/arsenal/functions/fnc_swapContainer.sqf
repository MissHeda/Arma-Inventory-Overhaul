#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Puts another uniform, vest or backpack on: what the old one held moves into the new, the places with it
 * (the old one's snapshot travels in the payload of the new, einv_storage_fnc_snapshot, so no record is
 * copied by hand), and what does not fit goes back to the arsenal (fnc_trimToFit). A placeholder is just
 * filled. A uniform's insignia is applied again.
 *
 * An old container that this arsenal does not offer is stored in a container with room, empty; without room
 * it asks for the second click before it is thrown away. The contents are never lost: what is not offered
 * stays as the red row of the new container when it has no cell.
 *
 * Arguments:
 * 0: Slot id - "uniform", "vest" or "backpack" <STRING>
 * 1: Class <STRING>
 *
 * Return Value:
 * Done <BOOL>
 *
 * Example:
 * ["vest", "V_PlateCarrier1_rgr"] call einv_arsenal_fnc_swapContainer;
 *
 * Public: No
 */

params [["_slot", "", [""]], ["_class", "", [""]]];

private _unit = GVAR(center);

if (isNull _unit || {_class isEqualTo ""} || {!(_slot in ["uniform", "vest", "backpack"])}) exitWith {false};

private _oldClass = ([_unit] call EFUNC(storage,getEquipment)) getOrDefault [_slot, ""];

if (toLowerANSI _oldClass isEqualTo toLowerANSI _class) exitWith {true};

private _oldContainer = switch (_slot) do {
    case "uniform": {uniformContainer _unit};
    case "vest": {vestContainer _unit};
    default {backpackContainer _unit};
};

private _empty = [[[], []], [], [], [[], []], [], [[], []]];

// ----- An old container the arsenal lacks needs a place, empty, or the second click -----
private _keep = [];

if (_oldClass isNotEqualTo "" && {[_oldClass] call FUNC(isUnique)}) then {
    _keep = if (_slot isEqualTo "backpack") then {["backpack", _oldClass, _empty]} else {["item", _oldClass, 1, _empty]};

    if !([_keep, true] call FUNC(storeAway)) then {
        // No room: the second click throws it away, the first only asks.
        if !(["swap|" + _slot + "|" + _class, format [LLSTRING(Hint_ConfirmUnique), [_oldClass] call EFUNC(gui,itemName)]] call FUNC(arm)) then {
            _class = "";
        };

        _keep = [];
    };
};

if (_class isEqualTo "") exitWith {false};

// ----- On, with what the old one held -----
private _inner = if (isNull _oldContainer) then {[]} else {[_oldContainer] call EFUNC(storage,snapshot)};

private _payload = if (_slot isEqualTo "backpack") then {
    ["backpack", _class, _inner]
} else {
    ["item", _class, 1, _inner]
};

([_unit, _slot, _payload] call EFUNC(storage,putOn)) params ["_status", "_taken"];

if (_status isNotEqualTo "") exitWith {
    // Whatever came off goes back on: nothing may be lost.
    if (_taken isNotEqualTo []) then {
        if ((([_unit, _slot, _taken] call EFUNC(storage,putOn)) select 0) isNotEqualTo "") then {
            ERROR_2("Could not put %1 on %2 and could not put the old one back.",_class,_slot);
        };
    };

    ["Failed"] call EFUNC(gui,flashHint);

    false
};

// The old one's contents live in the new container now; the old one itself is stored when it must be.
private _stored = false;

if (_keep isNotEqualTo []) then {
    _stored = [_keep] call FUNC(storeAway);
};

// A uniform has no insignia of its own: the one chosen goes on again.
if (_slot isEqualTo "uniform") then {
    private _insignia = missionNamespace getVariable [QACEGVAR(arsenal,currentInsignia), ""];

    if (_insignia isNotEqualTo "") then {
        ["insignia", _insignia, false] call FUNC(applyIdentity);
    };
};

// What has no cell in the new container goes back to the arsenal.
private _went = [_unit] call FUNC(trimToFit);

["equip", _class] call EFUNC(gui,playSound);

switch (true) do {
    case (_went isNotEqualTo []): {
        private _names = (_went select [0, 4]) apply {format ["%1× %2", _x select 1, [_x select 0] call EFUNC(gui,itemName)]};

        [format [LLSTRING(Hint_WentBack), (_names joinString ", ") + (["", ", ..."] select (count _went > 4))], "loss"] call FUNC(message);
    };
    case (_stored): {
        [format [
            LLSTRING(Hint_StoredOld), [_oldClass] call EFUNC(gui,itemName),
            [(uiNamespace getVariable [QGVAR(column), createHashMap]) getOrDefault ["stored", objNull]] call EFUNC(gui,containerName)
        ]] call FUNC(message);
    };
    default {
        [format [LLSTRING(Hint_Added), [_class] call EFUNC(gui,itemName)]] call FUNC(message);
    };
};

call EFUNC(gui,requestRebuild);

true
