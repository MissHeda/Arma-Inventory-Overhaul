#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * "Open radio" on a radio TFAR has not made the player's own yet - the vanilla radio in the radio slot, or a
 * radio still a prototype. TFAR swaps those for radios of their own every few seconds; this asks it to now
 * (TFAR_fnc_requestRadios, as a changed loadout would) and opens the radio that comes back in the radio slot
 * as soon as there is one.
 *
 * TFAR's server does not always answer (the beta waits for a CBA variable that newer CBA no longer sets, and
 * then never instances a radio): after three seconds a TFAR prototype is opened as it is - TFAR keeps the
 * settings of a radio by its class, a prototype's too - and the vanilla radio, which has no dialog of its own,
 * gets the hint that it is not ready, the RPT why.
 *
 * Arguments:
 * 0: The prototype's class <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["TFAR_anprc152"] call einv_compat_tfar_fnc_openPrototype;
 *
 * Public: No
 */

params [["_class", "", [""]]];

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
    [_class],
    3,
    {
        params ["_class"];

        if (getText (configFile >> "CfgWeapons" >> _class >> "tf_dialog") isNotEqualTo "") exitWith {
            [_class] call FUNC(open);
        };

        WARNING_1("TFAR made no radio of %1 - its server did not answer the radio request; the vanilla radio has no dialog of its own",_class);
        ["NotReady"] call EFUNC(gui,flashHint);
    }
] call CBA_fnc_waitUntilAndExecute;
