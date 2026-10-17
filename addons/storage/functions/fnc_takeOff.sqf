#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Takes what a unit has in one of its equipment slots (ids as in fnc_getSlot) off and hands it back as
 * a payload (fnc_addPayload) - a weapon with its attachments and magazines, a binocular with its
 * battery, a uniform, vest or backpack with its contents and places (fnc_snapshot).
 *
 * Runs where the unit is local: the commands that change a unit's gear need it. Checked afterwards:
 * what is still in the slot is not handed on. What came off is noted in the journal of the phase
 * running here the moment it left (fnc_journalNote) - fnc_putOn notes the old item itself. A backpack
 * still worn after removeBackpack is looked at again a frame later: gone by then, it goes back on from
 * its snapshot rather than being lost.
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

        // The muzzle is empty again: nothing is expected of it any more, the reload key may act at once (a
        // note of an earlier load, the key's repeat gap) and the notes of where the magazines lie are renewed.
        [objNull] call FUNC(noteHandLoad);
        GVAR(reloadAt) = 0;
        [_unit] call FUNC(useTrack);
        ["magazine", _class, [_entry get "ammo"]]
    };
    case (_part isNotEqualTo ""): {
        [_unit, _base, false, _class] call FUNC(weaponPart);
        ["item", _class, 1, []]
    };
    case (_base in ["uniform", "vest", "backpack"]): {
        // What the hidden holder keeps for it (Strict mode) goes back into it first, so the snapshot carries
        // it along - into the dropped backpack, as the player would expect (fnc_hiddenReturn; the holder is
        // taken again should the item be put on again, fnc_opStrict).
        [_unit, _base] call FUNC(hiddenReturn);

        private _snapshot = [_entry get "container", _class] call FUNC(snapshot);

        // removeBackpack, not removeBackpackGlobal: the global command takes the backpack off only a frame
        // later, so the check below still saw it worn, handed nothing on - and then the engine took it
        // off after all, with everything in it: a dropped backpack was gone. The unit is local here, and
        // what the local command does to a local unit every machine sees (ACE's own drop does the same).
        switch (_base) do {
            case "uniform": {removeUniform _unit};
            case "vest": {removeVest _unit};
            default {
                // Marked before it goes: the engine keeps it in a plain holder of its own until the end of
                // the frame, which fnc_getGroundHolder must not take for a pile to join.
                (backpackContainer _unit) setVariable [QGVAR(takenOff), true];
                removeBackpack _unit;
            };
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

private _stillOn = toLowerANSI (([_unit, _slotId] call FUNC(getSlot)) getOrDefault ["class", ""]) isEqualTo toLowerANSI _class;

// Still there - the engine did not take it off: hand nothing on, or it would exist twice.
if (_stillOn) exitWith {
    ERROR_2("Could not take %1 off %2 - nothing was moved.",_class,_slotId);

    // Should the engine take the backpack off later after all - the way removeBackpackGlobal did, which
    // lost every dropped backpack -, nothing was handed on and it would be gone with all it held: a frame
    // later it goes back on, filled from the snapshot. Still worn then, or another one on: nothing to do.
    if (_slotId isEqualTo "backpack") then {
        [{
            params ["_unit", "_class", "_snapshot"];

            if (isNull _unit || {!local _unit} || {backpack _unit isNotEqualTo ""}) exitWith {};

            _unit addBackpack _class;

            private _container = backpackContainer _unit;

            if (!isNull _container) then {
                [_container, _snapshot] call FUNC(restore);
            };

            ERROR_2("%1 came off %2 only a frame after it was asked to - it was put back on.",_class,_unit);
        }, [_unit, _class, _payload param [2, []]]] call FUNC(nextFrame);
    };

    []
};

if (_note) then {
    ["out", +_payload] call FUNC(journalNote);
};

_payload
