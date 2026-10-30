#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * "Open radio" on a radio TFAR has not made the player's own yet - the vanilla radio in the radio slot, or a
 * radio still a prototype. TFAR swaps those for radios of their own every few seconds; this asks it to now
 * (TFAR_fnc_requestRadios, as a changed loadout would) and opens the radio that comes back in the radio slot,
 * as soon as there is one. Nothing within five seconds: the hint says it is not ready.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call einv_compat_tfar_fnc_openPrototype;
 *
 * Public: No
 */

TFAR_lastLoadoutChange = diag_tickTime;
false call TFAR_fnc_requestRadios;

[
    {
        private _active = call TFAR_fnc_activeSwRadio;

        !isNil "_active" && {_active isEqualType ""} && {_active call TFAR_fnc_isRadio}
    },
    {
        [call TFAR_fnc_activeSwRadio] call FUNC(open);
    },
    [],
    5,
    {
        ["NotReady"] call EFUNC(gui,flashHint);
    }
] call CBA_fnc_waitUntilAndExecute;
