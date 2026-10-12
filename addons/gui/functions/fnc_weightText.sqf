#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The words for a weight refusal or forecast, with the numbers in them: "Too heavy for Tactical Rig: 0.1 kg
 * left, this weighs 0.5 kg", "Only 3 of 10 fit by weight into Backpack", "Moved 3 of 10 - the rest is too
 * heavy for Backpack", "Too heavy for your containers: 0.4 kg left at most" and "+2.4 kg: you will be
 * Overloaded (46.9 kg)". Kilograms with one decimal, two under one kilogram, as the hint's weights are.
 * Everything is worked out from the same rule the move itself meets (einv_storage_fnc_roomByWeight).
 *
 * The kinds, each with its own arguments after the kind:
 *   "tooHeavy"   [container, entry, count]       - why the container cannot take it; a backpack into a
 *                                                  backpack says so instead
 *   "someFit"    [container, entry, maxCount, stack] - only part of the stack fits
 *   "movedSome"  [container, moved, stack]       - a quick move took part of the stack
 *   "everywhere" [entry, bestFree]               - no container of the player has the room; bestFree is
 *                                                  the most any of them has left, config mass
 *   "body"       [need, tier, new load]          - what a pick-up will make of the soldier, config mass
 *                                                  and a TIER_*
 *
 * Arguments:
 * 0: Kind <STRING>
 * 1+: Its arguments, see above
 *
 * Return Value:
 * The text, "" for a kind it does not know <STRING>
 *
 * Example:
 * ["tooHeavy", vestContainer player, _entry, 5] call einv_gui_fnc_weightText;
 * ["body", 24, TIER_OVERLOADED, 1034] call einv_gui_fnc_weightText;
 *
 * Public: No
 */

params [["_kind", "", [""]]];

// A weight in kilograms, without the unit - the texts say it.
private _fnc_kg = {
    params ["_mass"];

    private _kg = (_mass max 0) * MASS_TO_KG;

    _kg toFixed ([1, 2] select (_kg < 1))
};

switch (_kind) do {
    case "tooHeavy": {
        _this params ["", ["_container", objNull, [objNull]], ["_entry", createHashMap, [createHashMap]], ["_count", -1, [0]]];

        private _room = [_container, _entry, _count] call EFUNC(storage,roomByWeight);

        if ((_room get "reason") isEqualTo "NoBackpack") then {
            LLSTRING(Hint_NoBackpack)
        } else {
            format [
                LLSTRING(Hint_TooHeavyFor), [_container] call FUNC(containerName),
                [_room get "free"] call _fnc_kg, [_room get "need"] call _fnc_kg
            ]
        }
    };
    case "someFit": {
        _this params ["", ["_container", objNull, [objNull]], "", ["_maxCount", 0, [0]], ["_stack", 1, [0]]];

        format [LLSTRING(Hint_SomeFit), _maxCount, _stack, [_container] call FUNC(containerName)]
    };
    case "movedSome": {
        _this params ["", ["_container", objNull, [objNull]], ["_moved", 0, [0]], ["_stack", 1, [0]]];

        format [LLSTRING(Hint_MovedSomeWeight), _moved, _stack, [_container] call FUNC(containerName)]
    };
    case "everywhere": {
        _this params ["", ["_entry", createHashMap, [createHashMap]], ["_bestFree", 0, [0]]];

        format [LLSTRING(Hint_TooHeavyEverywhere), [_bestFree] call _fnc_kg, [[[_entry]] call EFUNC(storage,getMass)] call _fnc_kg]
    };
    case "body": {
        _this params ["", ["_need", 0, [0]], ["_tier", TIER_LIGHT, [0]], ["_load", 0, [0]]];

        format [
            LLSTRING(Hint_BodyTier), [_need] call _fnc_kg,
            (([_tier, [GVAR(unit)] call EFUNC(weight,getLimits)] call EFUNC(weight,tierText)) select 0),
            [_load] call _fnc_kg
        ]
    };
    default {""};
}
