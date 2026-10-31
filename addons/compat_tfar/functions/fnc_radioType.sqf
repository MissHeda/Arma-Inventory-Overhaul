#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What kind of radio a class is, for the window: a short-range radio of its own, the prototype a radio
 * is made from (TFAR replaces it with one of its own once someone carries it), or a backpack with a
 * long-range radio. Asked on hover, so it reads TFAR's cached answers only and changes nothing.
 *
 * Arguments:
 * 0: Class <STRING>
 *
 * Return Value:
 * 0 none, 1 short-range radio of its own, 2 prototype, 3 long-range backpack <NUMBER>
 *
 * Example:
 * ["TFAR_anprc152_1"] call aio_compat_tfar_fnc_radioType;
 *
 * Public: No
 */

params [["_class", "", [""]]];

if (_class isEqualTo "") exitWith {0};

// A backpack: a long-range radio when TFAR's config says so.
if (isClass (configFile >> "CfgVehicles" >> _class)) exitWith {
    [0, 3] select (getNumber (configFile >> "CfgVehicles" >> _class >> "tf_hasLRradio") == 1)
};

if (!isClass (configFile >> "CfgWeapons" >> _class)) exitWith {0};

switch (true) do {
    case (_class call TFAR_fnc_isPrototypeRadio): {2};
    case (_class call TFAR_fnc_isRadio): {1};
    default {0};
}
