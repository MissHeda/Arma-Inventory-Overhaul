#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Asks the open window to look again at once whether what it shows is still what there is - on the
 * next frame rather than within the second (fnc_onFrame, fnc_getSignature). For changes the window
 * cannot see coming, such as a kit's contents or an option of another mod's context menu.
 *
 * Only a request: the window is built again when its signature changed, and never while a tile is
 * held - a rebuild would pull it from under the mouse. Nothing happens while no window is open.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call aio_gui_fnc_requestRebuild;
 *
 * Public: Yes
 */

GVAR(nextCheck) = 0;
GVAR(nextSignature) = 0;
