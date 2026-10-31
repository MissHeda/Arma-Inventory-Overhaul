#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The click on ACE Arsenal's Close button (set by fnc_interceptClose in place of ACE's own, which closed the
 * display with exit code 1 - "OK", which the Eden editor reads as "apply"): the window closes, but asks first
 * when something does not fit (fnc_confirmClose).
 *
 * Arguments:
 * 0: The button <CONTROL>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_button] call aio_arsenal_fnc_onCloseButton;
 *
 * Public: No
 */

disableSerialization;

params [["_button", controlNull, [controlNull]]];

if (isNull _button) exitWith {};

[ctrlParent _button, 1] call FUNC(confirmClose);
