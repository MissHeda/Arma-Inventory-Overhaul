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

// Its 3D view's scene goes with it (fnc_inspect3D), and the window shows whole again where Modify had its hole (fnc_cutHole).
["stop"] call FUNC(inspect3D);
[uiNamespace getVariable [QGVAR(display), displayNull], [], []] call FUNC(cutHole);

ctrlDelete (uiNamespace getVariable [QGVAR(inspectGroup), controlNull]);
uiNamespace setVariable [QGVAR(inspectGroup), controlNull];
uiNamespace setVariable [QGVAR(inspectRect), []];
uiNamespace setVariable [QGVAR(hotspots), []];

_open
