#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Selects nothing: Escape after the menu and the inspect card, a click on an empty cell, "Deselect" in
 * the menu.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Something was selected <BOOL>
 *
 * Example:
 * call aio_gui_fnc_clearSelection;
 *
 * Public: No
 */

if (GVAR(selection) isEqualTo []) exitWith {false};

GVAR(selection) = [];
GVAR(selectionSide) = "";
GVAR(selectionAnchor) = [];

[] call FUNC(drawSelection);

true
