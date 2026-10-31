#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether a reload is under way that a new one has to wait for: the player's weapon is in the middle of a
 * magazine reload (weaponState entry 6 above 0 - the engine's own answer, also for a reload this mod started
 * by the game's action), or ACE's "is reloading" flag (ace_common_isReloading) is set - but not for ever. ACE
 * sets the flag in its KeyDown handler whenever the reload key is pressed and clears it after the animation's
 * time; a flag left behind made every later reload do nothing (after taking a magazine out of a weapon by
 * dragging it out, say). So it is believed for RELOAD_BUSY_MAX seconds from the first time it was seen set; a
 * flag that outlived that is ignored until it has been seen cleared once. The hotbar, AIME's menu and the
 * reload undo's follow-up wait on it. The reload key's guard does not: ACE sets the flag for that very press.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * A reload is under way <BOOL>
 *
 * Example:
 * if (call aio_storage_fnc_reloadBusy) exitWith {};
 *
 * Public: Yes
 */

private _unit = missionNamespace getVariable ["ACE_player", player];

if (!isNull _unit && {((weaponState _unit) param [6, 0]) > 0}) exitWith {true};

if !(missionNamespace getVariable ["ace_common_isReloading", false]) exitWith {
    GVAR(reloadBusySince) = 0;

    false
};

// First seen set: from now on it is believed for a while.
if (GVAR(reloadBusySince) == 0) then {
    GVAR(reloadBusySince) = diag_tickTime;
};

// Seen set for too long: left behind. The stamp stays (it is not 0), so the flag is not believed again before
// it was seen cleared.
if (GVAR(reloadBusySince) < 0 || {diag_tickTime - GVAR(reloadBusySince) > RELOAD_BUSY_MAX}) exitWith {
    if (GVAR(reloadBusySince) > 0) then {
        GVAR(reloadBusySince) = -1;

        INFO("ACE's reloading flag has been set for too long - ignored until it was cleared once.");
    };

    false
};

true
