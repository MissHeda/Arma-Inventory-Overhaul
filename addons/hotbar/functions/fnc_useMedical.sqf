#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Bandages, a tourniquet, a splint, an injection, pills, an IV: treats the unit itself with it. The
 * treatment and the part of the body are picked by fnc_pickTreatment - the part that bleeds most for a
 * bandage, the worst bleeding limb for a tourniquet - and started with ACE's own
 * ace_medical_treatment_fnc_treatment, so everything ACE does is done: the progress bar, the animation,
 * the item taken, the conditions, the medic levels, the holster rule, every setting. With Advanced
 * Combat Medical this is its version of that function, and its actions are in the list like ACE's.
 * With Enhanced First Aid Kits the item is taken out of a carried kit as well.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Class <STRING>
 * 2: Slot index - not used <NUMBER>
 *
 * Return Value:
 * [done, text] - what is being done and to which part, or why not <ARRAY>
 *
 * Example:
 * [player, "ACE_elasticBandage", 1] call einv_hotbar_fnc_useMedical;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_class", "", [""]]];

if (isNil "ace_medical_treatment_fnc_treatment") exitWith {[false, LLSTRING(Reason_NoUse)]};

// ACE lets a soldier treat himself in a seat and in a building; the progress bar says the same.
if (!([_unit, ["isNotInside", "isNotSitting"]] call FUNC(canAct))) exitWith {[false, LLSTRING(Reason_NotNow)]};

([_unit, _class] call FUNC(pickTreatment)) params ["_action", "_part", "_reason"];

if (_reason isNotEqualTo "") exitWith {[false, _reason]};

private _started = [_unit, _unit, _part, _action] call ace_medical_treatment_fnc_treatment;

// ACE says false when it will not start the treatment. No answer at all means it put it off by a frame
// because its interaction menu is open: it will start, and counts as started.
if (!isNil "_started" && {_started isEqualTo false}) exitWith {[false, LLSTRING(Reason_CannotNow)]};

// The parts are named by the lowercase names ACE uses.
private _partName = switch (_part) do {
    case "head": {LLSTRING(Part_head)};
    case "body": {LLSTRING(Part_body)};
    case "leftarm": {LLSTRING(Part_leftarm)};
    case "rightarm": {LLSTRING(Part_rightarm)};
    case "leftleg": {LLSTRING(Part_leftleg)};
    case "rightleg": {LLSTRING(Part_rightleg)};
    default {_part};
};

[true, format ["%1 - %2", localize getText (configFile >> "ace_medical_treatment_actions" >> _action >> "displayNameProgress"), _partName]]
