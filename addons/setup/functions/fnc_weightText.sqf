#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * A weight in kg as the Items step's weight field writes it: to the gram, as short as it can be (0.45, 12,
 * 0.001) - the way the rules' weight= has it.
 *
 * Arguments:
 * 0: Weight in kg <NUMBER>
 *
 * Return Value:
 * Text <STRING>
 *
 * Example:
 * [0.4499] call einv_setup_fnc_weightText;
 *
 * Public: No
 */

params [["_kg", 0, [0]]];

str ((round (_kg * 1000)) / 1000)
