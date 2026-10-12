#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * A plain click on one of the soldier's slots, filled or empty: the catalog shows what belongs there and
 * the slot becomes the target, with a ring round it. Again on it, the target is cleared. A second click on
 * the same slot within a double click's time is taken for the second half of a double click and does
 * nothing: the window tells no double click on a filled slot.
 *
 * Arguments:
 * 0: Index of the slot in the window's slots <NUMBER>
 *
 * Return Value:
 * Handled <BOOL>
 *
 * Example:
 * [3] call einv_arsenal_fnc_onSlotClick;
 *
 * Public: No
 */

params [["_index", -1, [0]]];

private _record = (uiNamespace getVariable [QEGVAR(gui,slots), []]) param [_index, []];
private _slot = _record param [5, ""];

if (_slot isEqualTo "" || {(_record param [6, objNull]) isNotEqualTo GVAR(center)}) exitWith {false};

private _column = uiNamespace getVariable [QGVAR(column), createHashMap];
private _now = diag_tickTime;
private _last = _column getOrDefault ["slotClick", ["", -1]];

_column set ["slotClick", [_slot, _now]];

// The second click of a double click.
if ((_last select 0) isEqualTo _slot && {_now - (_last select 1) < 0.35}) exitWith {true};

if (GVAR(targetSlot) isEqualTo _slot) then {
    GVAR(targetSlot) = "";
} else {
    private _where = [_slot] call FUNC(categoryForSlot);

    // A slot the catalog has nothing for is no target.
    if (_where isEqualTo []) exitWith {};

    GVAR(targetSlot) = _slot;
    [_where select 1, _where select 2] call FUNC(showCategory);
};

[uiNamespace getVariable [QEGVAR(gui,display), displayNull]] call FUNC(drawTargets);

true
