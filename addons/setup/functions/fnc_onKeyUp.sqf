#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Display key up: handed to the open step (GVAR(stepKey), with up true) - Return in particular, which a
 * text field swallows on the way down. In a text field the keys stay the field's.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: DIK code <NUMBER>
 * 2: Shift held <BOOL>
 * 3: Ctrl held <BOOL>
 * 4: Alt held <BOOL>
 *
 * Return Value:
 * Key handled <BOOL>
 *
 * Example:
 * [_display, 28, false, false, false] call aio_setup_fnc_onKeyUp;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_key", ["_shift", false], ["_ctrl", false], ["_alt", false]];

if (ctrlType (focusedCtrl _display) == CTRL_TYPE_EDIT) exitWith {false};

// An open popover is answered first (fnc_onKeyDown).
if ((uiNamespace getVariable [QGVAR(popover), []]) isNotEqualTo []) exitWith {false};

private _handled = [_key, _shift, _ctrl, _alt, true] call GVAR(stepKey);

!isNil "_handled" && {_handled isEqualType true} && {_handled}
