#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What kind of radio a class is, for the window: a radio of its own (ACRE2 gives each one a unique class,
 * ACRE_PRC152_ID_1) or the base class of a radio, which ACRE2 replaces with a unique one once someone
 * carries it. Asked on hover, so it reads ACRE's configs only and changes nothing.
 *
 * Arguments:
 * 0: Class <STRING>
 *
 * Return Value:
 * 0 none, 1 radio of its own, 2 base radio <NUMBER>
 *
 * Example:
 * ["ACRE_PRC152_ID_1"] call einv_compat_acre_fnc_radioType;
 *
 * Public: No
 */

params [["_class", "", [""]]];

if (_class isEqualTo "") exitWith {0};

switch (true) do {
    case ([_class] call acre_api_fnc_isRadio): {1};
    case (getNumber (configFile >> "CfgWeapons" >> _class >> "acre_isRadio") == 1 && {[_class] call acre_api_fnc_isBaseRadio}): {2};
    default {0};
}
