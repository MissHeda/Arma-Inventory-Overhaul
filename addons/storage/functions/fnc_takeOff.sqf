#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Takes what a unit has in one of its equipment slots (ids as in fnc_getSlot) off and hands it back as
 * a payload (fnc_addPayload) - a weapon with its attachments and magazines, a binocular with its
 * battery, a uniform, vest or backpack with its contents and places (fnc_snapshot).
 *
 * Runs where the unit is local: the commands that change a unit's gear need it. Checked afterwards:
 * what is still in the slot is not handed on. What came off is noted in the journal of the phase
 * running here the moment it left (fnc_journalNote) - fnc_putOn notes the old item itself.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Slot id <STRING>
 * 2: Note it in the journal <BOOL> (default: true)
 *
 * Return Value:
 * Payload, [] when the slot was empty or nothing came off <ARRAY>
 *
 * Example:
 * [player, "headgear"] call einv_storage_fnc_takeOff;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_slotId", "", [""]], ["_note", true, [false]]];

private _entry = [_unit, _slotId] call FUNC(getSlot);

if (count _entry == 0) exitWith {[]};

(_slotId splitString "_") params [["_base", ""], ["_part", ""]];

private _class = _entry get "class";

private _payload = switch (true) do {
    case (_part isEqualTo "" && {_base in ["primary", "handgun", "launcher"]}): {
        _unit removeWeapon _class;
        ["weapon", [_entry get "attachments"] call FUNC(normalizeWeapon)]
    };
    case (_part in ["mag", "mag2"]): {
        [_unit, _base, false, _class] call FUNC(weaponPart);
        ["magazine", _class, [_entry get "ammo"]]
    };
    case (_part isNotEqualTo ""): {
        [_unit, _base, false, _class] call FUNC(weaponPart);
        ["item", _class, 1, []]
    };
    case (_base in ["uniform", "vest", "backpack"]): {
        private _snapshot = [_entry get "container", _class] call FUNC(snapshot);

        switch (_base) do {
            case "uniform": {removeUniform _unit};
            case "vest": {removeVest _unit};
            default {removeBackpackGlobal _unit};
        };

        if (_base isEqualTo "backpack") then {
            ["backpack", _class, _snapshot]
        } else {
            ["item", _class, 1, _snapshot]
        }
    };
    case (_base isEqualTo "headgear"): {removeHeadgear _unit; ["item", _class, 1, []]};
    case (_base isEqualTo "goggles"): {removeGoggles _unit; ["item", _class, 1, []]};
    case (_base isEqualTo "binocular"): {
        // The binocular goes with what is loaded in it - a laser designator's battery.
        private _weapon = ([_unit] call FUNC(getEquipment)) getOrDefault ["binocular", []];

        if !(_weapon isEqualType [] && {_weapon isNotEqualTo []}) then {
            _weapon = [_class];
        };

        _unit removeWeapon _class;
        ["weapon", [_weapon] call FUNC(normalizeWeapon)]
    };
    default {_unit unlinkItem _class; ["item", _class, 1, []]};
};

// Still there - the engine did not take it off: hand nothing on, or it would exist twice.
if (toLowerANSI (([_unit, _slotId] call FUNC(getSlot)) getOrDefault ["class", ""]) isEqualTo toLowerANSI _class) exitWith {
    ERROR_2("Could not take %1 off %2 - nothing was moved.",_class,_slotId);
    []
};

if (_note) then {
    ["out", +_payload] call FUNC(journalNote);
};

_payload
