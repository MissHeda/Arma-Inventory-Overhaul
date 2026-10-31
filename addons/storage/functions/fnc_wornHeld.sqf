#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether a unit's uniform, vest or backpack was swapped for another one lately, and for how much longer
 * its surplus is left alone. A worn container that is a different object than at the last look (a swap in
 * the window, a script) gets a fresh layout; the other containers are left exactly as they are for SWAP_HOLD
 * seconds - nothing moves between them, and nothing is put on the ground, because one was swapped
 * (fnc_requestMigrate, fnc_requestSweep).
 *
 * The hold is only for a swap of some of them. When every container the unit wears is a new object (a loadout,
 * ACE Arsenal's setUnitLoadout, a respawn) there is nothing left whose cells it could keep, so no hold starts.
 * It also ends early once something new came in after the swap - the unit carries more items or magazines than
 * at the swap (ACE's unload, a detached strobe or antenna, a pick-up): that new thing was never part of the swap,
 * and a minute with it on no cell is what the overflow sweep is there to prevent.
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
 * [player] call aio_storage_fnc_wornHeld;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

if (isNull _unit) exitWith {0};

private _worn = [uniformContainer _unit, vestContainer _unit, backpackContainer _unit];
private _seen = _unit getVariable [QGVAR(wornSeen), []];
private _counts = [count (items _unit), count (magazines _unit)];

if (_seen isNotEqualTo [] && {_seen isNotEqualTo _worn}) then {
    // A container worn now that is the same object as at the last look: its cells are what the hold keeps.
    private _kept = [0, 1, 2] findIf {
        private _now = _worn select _x;

        !isNull _now && {_now isEqualTo (_seen param [_x, objNull])}
    };

    if (_kept >= 0) then {
        _unit setVariable [QGVAR(swapAt), diag_tickTime];
        _unit setVariable [QGVAR(swapCounts), _counts];
    } else {
        _unit setVariable [QGVAR(swapAt), -1e9];
    };
};

_unit setVariable [QGVAR(wornSeen), _worn];

private _left = (SWAP_HOLD - (diag_tickTime - (_unit getVariable [QGVAR(swapAt), -1e9]))) max 0;

if (_left > 0) then {
    private _then = _unit getVariable [QGVAR(swapCounts), []];

    // Something came in since the swap: the hold is over.
    if (_then isEqualTypeArray [0, 0] && {(_counts select 0) > (_then select 0) || {(_counts select 1) > (_then select 1)}}) then {
        _unit setVariable [QGVAR(swapAt), -1e9];
        _left = 0;
    };
};

_left
