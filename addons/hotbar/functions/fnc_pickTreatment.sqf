#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Picks what to do with a medical item on the unit itself and where: the treatment (one of the actions
 * ACE or a mod lists the item for) and the part of the body. The part depends on what the treatment is
 * (the role of fnc_treatmentIndex):
 *
 *   bandage    the part that bleeds most; one a tourniquet holds shut comes last
 *   tourniquet the arm or leg that bleeds most and has none yet - never a limb that does not bleed
 *   splint     a broken leg before a broken arm
 *   other      (injections, pills, drips, ...) a free arm first, then a leg, the torso, the head; a limb
 *              with a tourniquet only as a last resort
 *
 * Every candidate is held against ACE's own question, whether the unit may do it now
 * (ace_medical_treatment_fnc_canTreat: allowed part, items at hand, medic level, holster rule, the
 * treatment's own condition, so a bandage is only picked for a bleeding part and a splint only for a
 * fracture). The first that passes is the answer, so a second press goes to the next part.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Item class <STRING>
 *
 * Return Value:
 * [action, part, reason] - the action's class in ACE's list and the lowercase part ("leftleg"), or
 * ["", "", why not as a text] <ARRAY>
 *
 * Example:
 * [player, "ACE_elasticBandage"] call einv_hotbar_fnc_pickTreatment;
 *
 * Public: No
 */

#define ALL_PARTS ["head", "body", "leftarm", "rightarm", "leftleg", "rightleg"]
#define PART_ORDER ["leftarm", "rightarm", "leftleg", "rightleg", "body", "head"]

params [["_unit", objNull, [objNull]], ["_class", "", [""]]];

private _actions = (call FUNC(treatmentIndex)) getOrDefault [toLowerANSI _class, []];
private _tourniquets = _unit getVariable ["ace_medical_tourniquets", [0, 0, 0, 0, 0, 0]];
private _wounds = _unit getVariable ["ace_medical_openWounds", createHashMap];
private _candidates = [];

if !(_wounds isEqualType createHashMap) then {
    _wounds = createHashMap;
};

{
    _x params ["_action", "_role"];

    private _order = _forEachIndex;

    {
        private _part = _x;
        private _partIndex = _forEachIndex;
        private _tourniquet = (_tourniquets param [_partIndex, 0]) > 0;
        private _bleeding = 0;

        // How much the part loses: every wound's size times how fast it bleeds, as ACE's own check for a
        // bleeding part reads them ([id, amount, bleeding, damage]).
        {
            _x params ["", ["_amount", 0], ["_rate", 0]];

            _bleeding = _bleeding + _amount * _rate;
        } forEach (_wounds getOrDefault [_part, []]);

        private _score = switch (_role) do {
            // What bleeds most; what a tourniquet holds shut still loses a little.
            case "bandage": {
                if (_bleeding > 0) then {_bleeding * ([1, 0.001] select _tourniquet)} else {-1}
            };
            // The worst bleeding arm or leg that has none yet.
            case "tourniquet": {
                if (_partIndex > 1 && {!_tourniquet} && {_bleeding > 0}) then {_bleeding} else {-1}
            };
            // A leg before an arm: legs carry you. canSplint decides whether one is broken.
            case "splint": {
                if (_partIndex > 1) then {[1, 2] select (_partIndex > 3)} else {-1}
            };
            // A free arm first; a limb with a tourniquet only takes it in later.
            default {
                10 - (PART_ORDER find _part) - ([0, 6] select _tourniquet)
            };
        };

        if (_score > 0) then {
            _candidates pushBack [_score, -_order, _action, _part];
        };
    } forEach ALL_PARTS;
} forEach _actions;

_candidates sort false;

private _index = _candidates findIf {[_unit, _unit, _x select 3, _x select 2] call ace_medical_treatment_fnc_canTreat};

if (_index >= 0) exitWith {
    (_candidates select _index) params ["", "", "_action", "_part"];

    [_action, _part, ""]
};

["", "", [_unit, _actions, _candidates] call FUNC(whyNot)]
