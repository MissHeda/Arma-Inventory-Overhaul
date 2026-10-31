#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The player's overflow sweep, every SWEEP_TICK seconds (XEH_postInit): runs the sweep when it is due
 * (fnc_queueSweep -> fnc_requestSweep) and, once a second (SWEEP_WATCH), compares a cheap signature of what the
 * player's uniform, vest and backpack hold - the load of each and the number of items and magazines the unit
 * carries - with the last one. Nothing raises an event for a script's addItem or addItemToUniform (ACE's pick-up,
 * a mod's action), CBA's polled loadout event is the main trigger and this is the net under it: a change here
 * queues a sweep that runs SWEEP_DELAY later, so an add the grid has no room for is on the ground a moment
 * after, whatever added it.
 *
 * The signature is five numbers from commands that only count (no loadout array is built), about a tenth of a
 * millisecond a second for a full kit; between the checks, and with nothing due, a call is two comparisons.
 * The first signature of a unit is only noted: a new unit is swept by its own trigger (the unit event, a
 * few seconds after it arrived).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call aio_storage_fnc_sweepTick;
 *
 * Public: No
 */

// Switched off with the rest of the surplus pass: no watch, nothing due.
if !(missionNamespace getVariable [QGVAR(migrate), true]) exitWith {
    GVAR(sweepDue) = -1;

    // Once in the RPT (issue #23): an overflow tile then stays red, by design.
    if (GVAR(sweepTrace) isNotEqualTo "off") then {
        GVAR(sweepTrace) = "off";

        INFO("Overflow sweep: off (setting aio_storage_migrate).");
    };
};

private _now = diag_tickTime;

if (_now >= GVAR(sweepWatchAt)) then {
    GVAR(sweepWatchAt) = _now + SWEEP_WATCH;

    private _unit = player;

    if (!isNull _unit && {alive _unit}) then {
        private _signature = ([uniformContainer _unit, vestContainer _unit, backpackContainer _unit] apply {
            if (isNull _x) then {0} else {loadAbs _x}
        }) + [count (items _unit), count (magazines _unit)];

        if (GVAR(sweepSignature) isEqualTo []) then {
            // The first one of this unit: noted, nothing to compare with.
            GVAR(sweepSignature) = _signature;
        } else {
            if (_signature isNotEqualTo GVAR(sweepSignature)) then {
                GVAR(sweepSignature) = _signature;

                [] call FUNC(queueSweep);
            };
        };
    };
};

if (GVAR(sweepDue) >= 0 && {_now >= GVAR(sweepDue)}) then {
    GVAR(sweepDue) = -1;

    [] call FUNC(requestSweep);
};
