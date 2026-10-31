#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Why a medical item cannot be used on the unit itself now - in a few words for the line over the bar.
 * Asked when fnc_pickTreatment found no part ACE lets the unit treat. The first that applies, for the
 * item's first action:
 *
 *   nothing to treat   no bleeding part for a bandage, no limb for a tourniquet
 *   not on oneself     the action is for others only (ACE's setting or the action itself)
 *   medical training   the unit's medic level is too low for it (ACE's settings for each treatment)
 *   weapon             ACE wants the weapon lowered or holstered first
 *   nothing to splint  no broken limb
 *
 * and, when none of them fits, that it cannot be done now.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: The item's actions, [[action, role], ...] (fnc_treatmentIndex) <ARRAY>
 * 2: The candidates fnc_pickTreatment tried <ARRAY>
 *
 * Return Value:
 * Reason, a text <STRING>
 *
 * Example:
 * [player, _actions, _candidates] call aio_hotbar_fnc_whyNot;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_actions", [], [[]]], ["_candidates", [], [[]]]];

(_actions param [0, ["", "any"]]) params ["_action", "_role"];

private _config = configFile >> "ace_medical_treatment_actions" >> _action;

// A number in the config, or the name of a setting that holds it (ACE's GET_NUMBER_ENTRY).
private _fnc_number = {
    params ["_entry"];

    if (isText _entry) then {
        missionNamespace getVariable [getText _entry, 0]
    } else {
        getNumber _entry
    }
};

private _self = [_config >> "allowSelfTreatment"] call _fnc_number;
private _required = [_config >> "medicRequired"] call _fnc_number;

call {
    // Nothing to do on any part: for these two it is the patient that is missing, not a permission.
    if (_candidates isEqualTo [] && {_role isEqualTo "bandage"}) exitWith {LLSTRING(Reason_NoBleeding)};
    if (_candidates isEqualTo [] && {_role isEqualTo "tourniquet"}) exitWith {LLSTRING(Reason_NoTourniquet)};

    if (_self == 0) exitWith {LLSTRING(Reason_NotYourself)};

    if ((_self == 2 && {!([_unit, 2] call ace_medical_treatment_fnc_isMedic)}) || {!([_unit, _required] call ace_medical_treatment_fnc_isMedic)}) exitWith {
        LLSTRING(Reason_NeedsMedic)
    };

    if (!([_unit, _unit, _config] call ace_medical_treatment_fnc_canTreat_holsterCheck)) exitWith {
        [LLSTRING(Reason_Lower), LLSTRING(Reason_Holster)] select ((missionNamespace getVariable ["ace_medical_treatment_holsterRequired", 0]) >= 3)
    };

    if (_role isEqualTo "splint") exitWith {LLSTRING(Reason_NoFracture)};

    LLSTRING(Reason_CannotNow)
}
