#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The words for what a pick-up would make of the soldier: "+2.4 kg: you will be Overloaded (46.9 kg)".
 * Kilograms with one decimal, two under one kilogram, as the hint's weights are. It is a forecast for the
 * soldier's own weight bar (einv_weight) and refuses nothing - weight limits no container.
 *
 * Arguments:
 * 0: What it adds, config mass <NUMBER>
 * 1: The tier it would put the soldier in <NUMBER> (TIER_*)
 * 2: The soldier's load then, config mass <NUMBER>
 *
 * Return Value:
 * The text <STRING>
 *
 * Example:
 * [24, TIER_OVERLOADED, 1034] call einv_gui_fnc_weightText;
 *
 * Public: No
 */

params [["_need", 0, [0]], ["_tier", TIER_LIGHT, [0]], ["_load", 0, [0]]];

// A weight in kilograms, without the unit - the text says it.
private _fnc_kg = {
    params ["_mass"];

    private _kg = (_mass max 0) * MASS_TO_KG;

    _kg toFixed ([1, 2] select (_kg < 1))
};

format [
    LLSTRING(Hint_BodyTier), [_need] call _fnc_kg,
    (([_tier, [GVAR(unit)] call EFUNC(weight,getLimits)] call EFUNC(weight,tierText)) select 0),
    [_load] call _fnc_kg
]
