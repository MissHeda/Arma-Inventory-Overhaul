#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether a value is a number the screen can use: a number, and not "Not a Number" or infinite - a control
 * given such a position raises a script error every frame it is asked for. The engine has no command for it;
 * its text says (a NaN reads "1.#QNAN" or "-1.#IND", infinity "1.#INF").
 *
 * Arguments:
 * 0: Value <ANY>
 *
 * Return Value:
 * It is a finite number <BOOL>
 *
 * Example:
 * [_boxX] call einv_gui_fnc_isFinite;
 *
 * Public: No
 */

params ["_value"];

!isNil "_value" && {_value isEqualType 0} && {((str _value) find "#") < 0}
