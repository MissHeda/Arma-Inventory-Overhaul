#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Closes the open popover (fnc_popover), if there is one, and hides the top layer it lay in
 * (fnc_topLayer) - shown, its group would take the clicks meant for the wizard. Never from inside one of
 * its own controls' events - through fnc_defer, as the widgets do.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * A popover was open <BOOL>
 *
 * Example:
 * call aio_setup_fnc_closePopover;
 *
 * Public: No
 */

private _controls = uiNamespace getVariable [QGVAR(popover), []];

{ctrlDelete _x} forEach _controls;
uiNamespace setVariable [QGVAR(popover), []];
(uiNamespace getVariable [QGVAR(layer), controlNull]) ctrlShow false;
uiNamespace setVariable [QGVAR(importEdit), controlNull];

// Text areas that were on it are gone with it.
uiNamespace setVariable [QGVAR(editAreas), (uiNamespace getVariable [QGVAR(editAreas), []]) select {!isNull _x}];

// The cursor would otherwise stay with a deleted control - or go to a text field on the wizard.
if (_controls isNotEqualTo []) then {
    ctrlSetFocus (uiNamespace getVariable [QGVAR(sink), controlNull]);
};

_controls isNotEqualTo []
