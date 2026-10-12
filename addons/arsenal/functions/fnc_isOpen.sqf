#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether the Enhanced Arsenal's window is open. For missions and mods that want to leave the player alone
 * while it is; ACE's own window is told apart by ace_arsenal_camera, which is set while either is open.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Open <BOOL>
 *
 * Example:
 * call einv_arsenal_fnc_isOpen;
 *
 * Public: Yes
 */

missionNamespace getVariable [QGVAR(isOpen), false]
