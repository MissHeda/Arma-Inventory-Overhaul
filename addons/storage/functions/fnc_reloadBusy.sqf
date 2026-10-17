#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether a reload is under way that a new one has to wait for - ACE's "is reloading" flag
 * (ace_common_isReloading) - but not for ever. The flag is set when a reload starts and cleared when the
 * game says it is done; a reload that did nothing (a weapon with no magazine, a magazine the engine refused)
 * says nothing, and the flag could stay set. The reload key's guard, the hotbar and AIME's menu all wait on
 * it, so a flag left behind made every later reload do nothing - after taking a magazine out of a weapon by
 * dragging it out, say. So it is believed for RELOAD_BUSY_MAX seconds from the first time it was seen set; a
 * flag that outlived that is ignored until it has been seen cleared once.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * A reload is under way <BOOL>
 *
 * Example:
 * if (call einv_storage_fnc_reloadBusy) exitWith {};
 *
 * Public: Yes
 */

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
