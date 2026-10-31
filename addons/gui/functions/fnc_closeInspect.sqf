#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Closes the inspect card (fnc_drawInspect) - its cross, or Escape. Where it stood is kept for the next
 * one.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * A card was open <BOOL>
 *
 * Example:
 * call aio_gui_fnc_closeInspect;
 *
 * Public: No
 */

disableSerialization;

private _open = GVAR(inspect) isNotEqualTo [];

GVAR(inspect) = [];
GVAR(inspectMove) = [];

ctrlDelete (uiNamespace getVariable [QGVAR(inspectGroup), controlNull]);
uiNamespace setVariable [QGVAR(inspectGroup), controlNull];
uiNamespace setVariable [QGVAR(inspectRect), []];

_open
