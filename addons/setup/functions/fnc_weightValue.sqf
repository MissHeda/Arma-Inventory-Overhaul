#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Reads what was typed into the Items step's weight field: kilograms as digits with one dot or comma
 * (0.45, 12, ,5), rounded to the gram and at most what the rules engine allows (EDIT_WEIGHT_MAX).
 * Nothing typed means no weight of its own, config's stays.
 *
 * Arguments:
 * 0: Text <STRING>
 *
 * Return Value:
 * Weight in kg; -1 for nothing typed; -2 for text that is no weight <NUMBER>
 *
 * Example:
 * ["0,45"] call einv_setup_fnc_weightValue;
 *
 * Public: No
 */

params [["_text", "", [""]]];

private _clean = (trim _text) regexReplace [",", "."];

if (_clean isEqualTo "") exitWith {-1};

// Digits with one dot at most, and at least one digit: 12, 0.5, 2., .25.
if !(_clean regexMatch "^([0-9]+[.]?[0-9]*|[.][0-9]+)$") exitWith {-2};

((round ((parseNumber _clean) * 1000)) / 1000) min EDIT_WEIGHT_MAX
