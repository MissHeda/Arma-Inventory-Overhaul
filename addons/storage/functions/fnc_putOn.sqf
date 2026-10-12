#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Puts a payload (fnc_removeEntry) on a unit, into one of its equipment slots (ids as in fnc_getSlot),
 * and hands back what was in the slot before as a payload of its own. A uniform, vest or backpack
 * comes with its contents and places (fnc_restore), and the one taken off keeps its own.
 *
 * Step by step, each step checked: the old item off - the slot must be empty then, else "Failed" and
 * nothing goes on -; the new one on - the slot must then hold its class (a weapon slot: a weapon) and a
 * magazine the payload's rounds, else whatever went on comes off again, the old item goes back on and
 * it is "Bounced": the payload is still whole. The old item is handed back exactly when it left -
 * also when it is of the same class (a magazine swap) - and noted in the journal of the phase running
 * here (fnc_journalNote); put back on, it is marked consumed again.
 *
 * Runs where the unit is local: the commands that change a unit's gear need it. A slot holds one item:
 * a payload of more than one, or one the slot does not take (fnc_slotAccepts), is refused ("Failed",
 * nothing changed).
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Slot id <STRING>
 * 2: Payload <ARRAY>
 *
 * Return Value:
 * [status, old] <ARRAY>
 *   status - "" it is on, "Failed" nothing went on and the payload is whole (the slot could not be
 *     emptied, or the payload does not belong there), "Bounced" it did not go on and the payload is
 *     whole <STRING>
 *   old - payload of what was in the slot and left it, [] for nothing <ARRAY>
 *
 * Example:
 * [player, "headgear", ["item", "H_HelmetB", 1, []]] call einv_storage_fnc_putOn;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_slotId", "", [""]], ["_payload", [], [[]]]];

if (isNull _unit || {_payload isEqualTo []}) exitWith {["Failed", []]};

(_slotId splitString "_") params [["_base", ""], ["_part", ""]];

private _wholeWeapon = _part isEqualTo "" && {_base in ["primary", "handgun", "launcher", "binocular"]};

// The class and, for a magazine, the rounds a payload puts on.
private _fnc_classOf = {
    params ["_put"];

    if ((_put select 0) isEqualTo "weapon") exitWith {(_put param [1, [], [[]]]) param [0, "", [""]]};

    _put param [1, "", [""]]
};

private _fnc_roundsOf = {
    params ["_put"];

    if ((_put select 0) isNotEqualTo "magazine") exitWith {-1};

    (_put param [2, [], [[]]]) param [0, -1, [0]]
};

private _newClass = [_payload] call _fnc_classOf;

// A slot holds one: more than one would leave the rest nowhere.
private _many = switch (_payload select 0) do {
    case "magazine": {count (_payload param [2, [], [[]]]) > 1};
    case "item": {(_payload param [2, 1, [0]]) > 1};
    default {false};
};

if (_many) exitWith {
    ERROR_2("Cannot put more than one %1 on %2 - nothing was changed.",_newClass,_slotId);
    ["Failed", []]
};

// The engine puts a weapon into the slot of its own kind whatever was asked: one that does not belong
// here would land elsewhere while its payload went back as well.
if !([_unit, _slotId, _newClass] call FUNC(slotAccepts)) exitWith {
    ERROR_2("%1 does not go on %2 - nothing was changed.",_newClass,_slotId);
    ["Failed", []]
};

// Puts a payload on the empty slot.
private _fnc_on = {
    params ["_put"];

    private _class = [_put] call _fnc_classOf;

    switch (true) do {
        case (_part isEqualTo "" && {_base in ["primary", "handgun", "launcher"]}): {
            private _weapon = if ((_put select 0) isEqualTo "weapon") then {_put select 1} else {[_class]};

            [_unit, _base, [_weapon] call FUNC(normalizeWeapon)] call FUNC(addWeapon);
        };
        case (_part isNotEqualTo ""): {
            if (_part in ["mag", "mag2"]) then {
                [_unit, _base, true, _class, [_put] call _fnc_roundsOf, _part isEqualTo "mag2"] call FUNC(weaponPart);
            } else {
                [_unit, _base, true, _class] call FUNC(weaponPart);
            };
        };
        case (_base in ["uniform", "vest", "backpack"]): {
            // What it held - or nothing: a backpack added by class comes with its default contents.
            private _inner = if ((_put select 0) isEqualTo "backpack") then {_put param [2, [], [[]]]} else {_put param [3, [], [[]]]};

            if (_inner isEqualTo []) then {
                _inner = [[[], []], [], [], [[], []], [], [[], []]];
            };

            private _container = switch (_base) do {
                case "uniform": {_unit forceAddUniform _class; uniformContainer _unit};
                case "vest": {_unit addVest _class; vestContainer _unit};
                default {_unit addBackpackGlobal _class; backpackContainer _unit};
            };

            if (!isNull _container) then {
                [_container, _inner] call FUNC(restore);
            };
        };
        case (_base isEqualTo "headgear"): {_unit addHeadgear _class};
        case (_base isEqualTo "goggles"): {_unit addGoggles _class};
        case (_base isEqualTo "binocular"): {
            private _own = [];

            if ((_put select 0) isEqualTo "weapon") then {
                _own = ([_put select 1] call FUNC(normalizeWeapon)) select 4;
            };

            _unit addWeapon _class;

            // A battery the engine loaded by itself came out of the unit's own containers: back in there
            // once it is out - else there would be two -, then its own goes in.
            private _loaded = (([_unit] call FUNC(getEquipment)) getOrDefault ["binocular", []]) param [4, [], [[]]];

            if (_loaded isNotEqualTo []) then {
                _unit removeBinocularItem (_loaded select 0);

                private _still = (([_unit] call FUNC(getEquipment)) getOrDefault ["binocular", []]) param [4, [], [[]]];

                if (_still isEqualTo []) then {
                    _unit addMagazine [_loaded select 0, _loaded param [1, 1]];
                };
            };

            if (_own isNotEqualTo []) then {
                _unit addWeaponItem [_class, [_own select 0, _own param [1, 1], _class], true];
            };
        };
        default {
            // Map, GPS, radio, compass, watch, NVG: linked items.
            _unit linkItem _class;
        };
    };
};

// It is on as it was: a weapon slot holds a weapon (only ours can have come), any other slot the class,
// a magazine slot also its rounds.
private _fnc_isOn = {
    params ["_put"];

    private _now = [_unit, _slotId] call FUNC(getSlot);

    if (count _now == 0) exitWith {false};
    if (_wholeWeapon) exitWith {true};
    if (toLowerANSI (_now getOrDefault ["class", ""]) isNotEqualTo toLowerANSI ([_put] call _fnc_classOf)) exitWith {false};

    private _rounds = [_put] call _fnc_roundsOf;

    _rounds < 0 || {!(_part in ["mag", "mag2"])} || {(_now getOrDefault ["ammo", -1]) isEqualTo _rounds}
};

// On, or the slot empty again with nothing of it left on: true when it counts as on. What cannot come
// off again stays and counts as on - the payload going elsewhere as well would make a copy.
private _fnc_tryOn = {
    params ["_put"];

    [_put] call _fnc_on;

    if ([_put] call _fnc_isOn) exitWith {true};

    if (count ([_unit, _slotId] call FUNC(getSlot)) > 0) then {
        [_unit, _slotId, false] call FUNC(takeOff);
    };

    if (count ([_unit, _slotId] call FUNC(getSlot)) > 0) exitWith {
        private _putClass = [_put] call _fnc_classOf;
        ERROR_2("%1 went on %2 not as it was and cannot come off again - it stays.",_putClass,_slotId);
        true
    };

    false
};

// The old item off first: the slot must be empty before the new one goes on.
private _old = [];
private _oldNote = -1;

if (count ([_unit, _slotId] call FUNC(getSlot)) > 0) then {
    _old = [_unit, _slotId, false] call FUNC(takeOff);

    if (_old isNotEqualTo []) then {
        _oldNote = ["out", +_old] call FUNC(journalNote);
    };
};

if (count ([_unit, _slotId] call FUNC(getSlot)) > 0) exitWith {
    ERROR_2("Could not empty %1 for %2 - nothing was put on.",_slotId,_newClass);
    ["Failed", _old]
};

if ([_payload] call _fnc_tryOn) exitWith {["", _old]};

// Did not go on: the old item back where it was, the payload goes back whole.
if (_old isNotEqualTo [] && {[_old] call _fnc_tryOn}) then {
    ["in", _oldNote] call FUNC(journalNote);
    _old = [];
};

ERROR_2("Could not put %1 on %2 - it goes back.",_newClass,_slotId);

["Bounced", _old]
