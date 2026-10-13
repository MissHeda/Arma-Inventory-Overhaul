#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What the hint says while the mouse is on something that is no tile and no slot (fnc_updateHover): the
 * weight card and a section's caption line. The words are what the container holds weighs or the soldier's
 * tier with the numbers in them - always in kilograms - in the colour that goes with it.
 *
 * The kinds:
 *   "weight" [unit]             - "34.5 kg - Heavy: jogging tires you", then every tier above in its colour:
 *                                 "Overloaded from 45.0 kg", "Critical from 60.0 kg"
 *   "load"   [container, name]  - what the container's contents weigh (muted). It says nothing about
 *                                 room: weight limits no container, its free cells do
 *
 * Arguments:
 * 0: Kind <STRING>
 * 1: Its arguments, see above <ARRAY>
 *
 * Return Value:
 * Parts, [[text, colour key], ...] - [] for none <ARRAY>
 *
 * Example:
 * ["load", [vestContainer player, "Tactical Rig"]] call einv_gui_fnc_infoHint;
 *
 * Public: No
 */

params [["_kind", "", [""]], ["_args", [], [[]]]];

// A weight in kilograms, one decimal, two under one kilogram.
private _fnc_kg = {
    params ["_mass"];

    private _kg = (_mass max 0) * MASS_TO_KG;

    _kg toFixed ([1, 2] select (_kg < 1))
};

switch (_kind) do {
    case "weight": {
        _args params [["_unit", objNull, [objNull]]];

        private _limits = [_unit] call EFUNC(weight,getLimits);
        private _load = [_unit] call EFUNC(weight,getLoad);
        private _tier = [_unit, _load] call EFUNC(weight,getTier);

        ([_tier, _limits] call EFUNC(weight,tierText)) params ["_word", "_effect"];

        private _loadKg = [_load] call _fnc_kg;
        private _colors = ["text2", "warn", "loss", "loss"];
        private _parts = [[
            [format [LLSTRING(Tier_Now), _loadKg, _word], format [LLSTRING(Tier_NowDesc), _loadKg, _word, _effect]] select (_effect isNotEqualTo ""),
            _colors select _tier
        ]];

        // The tiers above this one and where they start. Heavy only counts as a tier of its own where it
        // starts before Overloaded.
        {
            _x params ["_tierAbove", "_key", "_kg"];

            if (_tier < _tierAbove && {_tierAbove != TIER_HEAVY || {(_limits get "heavyKg") < (_limits get "overloadedKg")}}) then {
                _parts pushBack [
                    format [LLSTRING(Tier_From), ([_tierAbove, _limits] call EFUNC(weight,tierText)) select 0, (_limits get _kg) toFixed 1],
                    _key
                ];
            };
        } forEach [[TIER_HEAVY, "warn", "heavyKg"], [TIER_OVERLOADED, "loss", "overloadedKg"], [TIER_CRITICAL, "loss", "criticalKg"]];

        _parts
    };
    case "load": {
        _args params [["_container", objNull, [objNull]], ["_name", "", [""]]];

        if (isNull _container) exitWith {[]};

        private _mass = [[_container] call EFUNC(storage,getContents)] call EFUNC(storage,getMass);

        [[format ["%1: %2 kg", _name, [_mass] call _fnc_kg], "muted"]]
    };
    default {[]};
}
