#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether the hotbar is switched on: the setting (the mission's choice) and a machine with a player - not
 * Eden, which has no player and runs none of the hotbar's startup.
 * Everything of the hotbar - its keys, its row in the window, its bar on the screen - asks this first.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * The hotbar is on <BOOL>
 *
 * Example:
 * call aio_hotbar_fnc_isActive;
 *
 * Public: No
 */

GVAR(enabled) && {hasInterface} && {!is3DEN}
