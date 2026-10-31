#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether the window is the plain inventory. The Arsenal and later editor windows attach to the same
 * window with a table of hooks (GVAR(hooks)); with none, this is the inventory itself. Everything that
 * only belongs to the inventory asks: the boxes of what lies nearby, selecting several tiles, group drags, and the hotbar row and keys.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * No hooks are attached <BOOL>
 *
 * Example:
 * call aio_gui_fnc_isInventoryMode;
 *
 * Public: No
 */

count (missionNamespace getVariable [QGVAR(hooks), createHashMap]) == 0
