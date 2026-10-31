#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Which treatments an item belongs to, read from ACE medical's own list of them
 * (ace_medical_treatment_actions - ACE's actions and those other mods add, Advanced Combat Medical's
 * among them). Built once, when first asked.
 *
 * An action counts when an item is what it uses up, when the unit may do it on itself, and when it is
 * not switched off outright (ACM turns ACE's blood, plasma and saline bags off with a condition of
 * "false"). What it does decides which part of the body the bar picks (fnc_pickTreatment): bandaging
 * the part that bleeds most, a tourniquet on the worst limb, a splint on a broken one, everything else
 * ("any") on a free arm first.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Lowercase item class -> [[action, role], ...] in the order of the config, role "bandage", "tourniquet",
 * "splint" or "any" <HASHMAP>
 *
 * Example:
 * call aio_hotbar_fnc_treatmentIndex;
 *
 * Public: No
 */

if (!isNil QGVAR(treatments)) exitWith {GVAR(treatments)};

private _index = createHashMap;

{
    private _action = _x;
    private _items = getArray (_action >> "items");

    // Not tied to an item: CPR, diagnosing, taking a tourniquet off, ...
    if (_items isEqualTo []) then {continue};

    // Never on oneself (body bags, ACM's emergency dressing and lozenge): a number of 0 is final; a name of
    // a setting is only known at the time of use (fnc_whyNot).
    if (isNumber (_action >> "allowSelfTreatment") && {getNumber (_action >> "allowSelfTreatment") == 0}) then {continue};

    // Switched off by the mod that replaced it.
    if (toLowerANSI getText (_action >> "condition") isEqualTo "false") then {continue};

    private _name = configName _action;
    private _callback = toLowerANSI getText (_action >> "callbackSuccess");
    private _role = switch (true) do {
        case (_callback isEqualTo "ace_medical_treatment_fnc_bandage"): {"bandage"};
        case (_callback isEqualTo "ace_medical_treatment_fnc_tourniquet"): {"tourniquet"};
        case ("splint" in toLowerANSI _name || {"splint" in _callback}): {"splint"};
        default {"any"};
    };

    {
        private _key = toLowerANSI _x;

        if !(_key in _index) then {
            _index set [_key, []];
        };

        (_index get _key) pushBack [_name, _role];
    } forEach _items;
} forEach ("true" configClasses (configFile >> "ace_medical_treatment_actions"));

GVAR(treatments) = _index;

_index
