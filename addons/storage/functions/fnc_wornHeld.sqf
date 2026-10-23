#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether a unit's uniform, vest or backpack was swapped for another one lately, and for how much longer
 * its surplus is left alone. A worn container that is a different object than at the last look (a swap in
 * the window, a script, an arsenal, a loadout) gets a fresh layout; the other containers are left exactly
 * as they are for SWAP_HOLD seconds - nothing moves between them, and nothing is put on the ground,
 * because one was swapped (fnc_requestMigrate, fnc_requestSweep).
 *
 * It also takes the look: the worn containers it saw are kept on the unit (local variable), so the next
 * call knows what changed. Whoever asks first after a change notes it, the other finds it noted.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * Seconds left of the hold, 0 for none <NUMBER>
 *
 * Example:
 * [player] call einv_storage_fnc_wornHeld;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

if (isNull _unit) exitWith {0};

private _worn = [uniformContainer _unit, vestContainer _unit, backpackContainer _unit];
private _seen = _unit getVariable [QGVAR(wornSeen), []];

if (_seen isNotEqualTo [] && {_seen isNotEqualTo _worn}) then {
    _unit setVariable [QGVAR(swapAt), diag_tickTime];
};

_unit setVariable [QGVAR(wornSeen), _worn];

(SWAP_HOLD - (diag_tickTime - (_unit getVariable [QGVAR(swapAt), -1e9]))) max 0
