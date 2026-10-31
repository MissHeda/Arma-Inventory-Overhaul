#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Schedules the update of the local player's virtual load (fnc_updateVirtualLoad) for the next frame - and,
 * with the new load in place, of the tier it puts the player in (fnc_updateTier).
 *
 * What changes the load comes in bursts - a respawn raises both the unit and the loadout event, an
 * arsenal raises a loadout event per item - and each update may broadcast. Collapsing a burst into
 * one update keeps that to a single broadcast.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call aio_weight_fnc_queueVirtualLoad;
 *
 * Public: No
 */

if (!hasInterface || {GVAR(queued)}) exitWith {};

GVAR(queued) = true;

[{
    GVAR(queued) = false;
    [ACE_player] call FUNC(updateVirtualLoad);
    [ACE_player] call FUNC(updateTier);
}] call CBA_fnc_execNextFrame;
