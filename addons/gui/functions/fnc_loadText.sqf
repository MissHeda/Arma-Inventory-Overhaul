#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The weight on a section's caption line: what its contents weigh in kilograms, "3.4 kg". It is only
 * told, never held against anything - no container has a weight limit, its free cells decide what fits.
 *
 * Arguments:
 * 0: Entries it holds <ARRAY of HASHMAPs>
 *
 * Return Value:
 * The text <STRING>
 *
 * Example:
 * [_entries] call einv_gui_fnc_loadText;
 *
 * Public: No
 */

params [["_entries", [], [[]]]];

format ["%1 kg", (([_entries] call EFUNC(storage,getMass)) * MASS_TO_KG) toFixed 1]
