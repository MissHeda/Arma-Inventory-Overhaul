#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Notes whether any of the three "Use items from ..." settings limits something: GVAR(useActive). Everything
 * that asks where an item may be used from looks at that first and has nothing to do, at no cost, while all
 * three are on Everything. And whether any of them is on Strict: GVAR(strictActive), read by what routes
 * items into the hidden holder (fnc_hiddenRoute). Run by each of the settings when it is set or changed -
 * then every unit here that carries a holder, and the player's own, are noted for a look (fnc_hiddenSweep,
 * fnc_queueMigrate): a setting switched to Strict hides, one switched away gives back (fnc_opStrict).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Whether something is limited <BOOL>
 *
 * Example:
 * [] call aio_storage_fnc_useRefresh;
 *
 * Public: No
 */

GVAR(useActive) = (USE_KINDS findIf {([_x] call FUNC(useMode)) isNotEqualTo USE_ALL}) >= 0;
GVAR(strictActive) = (USE_KINDS findIf {([_x] call FUNC(useMode)) isEqualTo USE_STRICT}) >= 0;

if (!is3DEN) then {
    call FUNC(hiddenSweep);

    if (hasInterface) then {
        [missionNamespace getVariable ["ACE_player", player]] call FUNC(queueMigrate);
    };
};

GVAR(useActive)
