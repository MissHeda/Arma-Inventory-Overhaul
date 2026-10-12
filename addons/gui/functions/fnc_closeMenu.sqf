#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Closes the context menu (fnc_openMenu), if one is open.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * A menu was open <BOOL>
 *
 * Example:
 * call einv_gui_fnc_closeMenu;
 *
 * Public: No
 */

private _controls = uiNamespace getVariable [QGVAR(menu), []];

{ctrlDelete _x} forEach _controls;
uiNamespace setVariable [QGVAR(menu), []];

_controls isNotEqualTo []
