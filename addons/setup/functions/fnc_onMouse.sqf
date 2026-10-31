#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The wizard's display: the mouse moved or rests on it - every frame while it is open, in Eden and over
 * the menus too. Runs what the widgets queued (fnc_defer), and lets every text area grow with its text,
 * so its group scrolls down to the last line (fnc_fitEditArea) - whatever put the text there, typing,
 * pasting or a script - the way CBA's export window keeps its box the size of its text.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call aio_setup_fnc_onMouse;
 *
 * Public: No
 */

disableSerialization;

call FUNC(runDeferred);

{
    if (!isNull _x) then {
        [_x] call FUNC(fitEditArea);
    };
} forEach (uiNamespace getVariable [QGVAR(editAreas), []]);
