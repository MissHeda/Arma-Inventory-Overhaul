#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Makes the wizard's top layer anew: a controls group over the whole screen that every popover is made
 * in (fnc_popover) - a dropdown's list, the Same as picker, the import box, a question like the one
 * before closing with unsaved changes. Hidden while no popover is open: a group takes the clicks over its
 * whole area.
 *
 * The engine draws a display's controls in the order they were made, and the one holding the focus over
 * all of them. A popover made on the display itself lay under the pane (aio_setup_root) as soon as the
 * pane held the focus - after every redraw its sink has it, and a click on a dropdown gives it to the
 * dropdown in the pane: the list and the closing question showed behind the wizard and could not be
 * clicked (Mia, 0.4.0). The layer is made after everything else (at the end of every step drawn,
 * fnc_showStep) and a popover takes the focus into it (fnc_popover).
 *
 * Arguments:
 * 0: Display <DISPLAY>
 *
 * Return Value:
 * The layer <CONTROL>
 *
 * Example:
 * [_display] call aio_setup_fnc_topLayer;
 *
 * Public: No
 */

disableSerialization;

params [["_display", displayNull, [displayNull]]];

// A popover open in the old layer goes with it.
call FUNC(closePopover);
ctrlDelete (uiNamespace getVariable [QGVAR(layer), controlNull]);

if (isNull _display) exitWith {
    uiNamespace setVariable [QGVAR(layer), controlNull];
    controlNull
};

// On the display itself, not through the kit's uiCreate: what that makes on a display the inventory's next
// build deletes (aio_gui_fnc_uiCreate).
private _layer = _display ctrlCreate ["AIO_Group", -1];
_layer ctrlSetPosition [safezoneX, safezoneY, safezoneW, safezoneH];
_layer ctrlCommit 0;
_layer ctrlShow false;

uiNamespace setVariable [QGVAR(layer), _layer];

_layer
