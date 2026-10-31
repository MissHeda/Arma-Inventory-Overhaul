#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Notes that the player's overflow is to be looked at (fnc_sweepTick -> fnc_requestSweep): what lies on no
 * cell of the uniform, vest or backpack goes to another worn container, else onto the ground. Every trigger
 * ends here - the cheap loadout watch (fnc_sweepTick), CBA's polled loadout event, the engine's Take and
 * InventoryClosed, a loadout set, a new unit, the open window that shows an overflow tile - and a burst of
 * them is one sweep: the earliest due time stays, nothing is looked at twice.
 *
 * Two floors keep the sweep from running too early. The one a loadout or a new unit sets (the top-up and
 * the places of the loadout come first, fnc_onLoadoutSet) holds every sweep until then; the one a pass that
 * put nothing down sets (GVAR(sweepQuiet)) holds back only the next try to put something on the ground -
 * fnc_requestSweep looks at it there, so a move into another worn container's free cell is never delayed by
 * it. Both only delay.
 *
 * Only on a machine with a player, not in Eden. Cheap enough to call from every trigger: it sets a number.
 *
 * Arguments:
 * 0: Wait before it runs, seconds <NUMBER> (default: SWEEP_DELAY)
 * 1: Nothing is swept before that wait is over - a loadout was set, the unit is new <BOOL> (default: false)
 * 2: A new unit or a loadout set: its first sweep ignores the hold after a swapped container (fnc_wornHeld) - all
 *    three containers are new objects then, which is no swap of one <BOOL> (default: false)
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call einv_storage_fnc_queueSweep;
 *
 * Public: No
 */

params [["_wait", SWEEP_DELAY, [0]], ["_floor", false, [false]], ["_fresh", false, [false]]];

if (is3DEN || {!hasInterface}) exitWith {};

private _now = diag_tickTime;

if (_floor) then {
    GVAR(sweepNotBefore) = GVAR(sweepNotBefore) max (_now + _wait);
};

if (_fresh) then {
    GVAR(sweepFresh) = true;
};

// The hold after a pass that put nothing down is the ground's only (fnc_requestSweep): a move into a free cell of
// another worn container is never held back by it.
private _at = (_now + _wait) max GVAR(sweepNotBefore);

// Already waiting: the earlier time stays.
if (GVAR(sweepDue) < 0 || {_at < GVAR(sweepDue)}) then {
    GVAR(sweepDue) = _at;
};
