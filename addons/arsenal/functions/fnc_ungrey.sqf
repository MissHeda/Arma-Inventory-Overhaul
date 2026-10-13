#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * ACE greys the rows of its list that the open uniform, vest or backpack cannot take by weight, and
 * disables its "+" for them (ace_arsenal_fnc_updateRightPanel, the engine's canAdd). Cells are the only
 * limit here, so a greyed row whose item the grid would take - a free spot, or a pile of the same kind
 * (class and rounds) with room left, as einv_storage_fnc_hasSpace asks it for what fnc_addNew would put in -
 * is lit again, and so is the "+" of the row picked. Rows ACE leaves lit are left as they are:
 * what then finds no cell is taken back out with a message (fnc_reconcile). Items the box does not offer
 * (ACE's unique ones) and backpacks are left to ACE.
 *
 * Run after ACE's own look, a frame after its events (fnc_settle) and after a row is picked
 * (fnc_onOpened). One look at the grid per item size, not per row. Should ACE's list or arrow not be where
 * this addon expects them, nothing is changed and the RPT says so once.
 *
 * Arguments:
 * 0: ACE Arsenal's display <DISPLAY>
 * 1: Only the "+" of the row picked <BOOL> (default: false)
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display] call einv_arsenal_fnc_ungrey;
 *
 * Public: No
 */

disableSerialization;

params [["_display", displayNull, [displayNull]], ["_plusOnly", false, [false]]];

if (!GVAR(attached)) exitWith {};

(call FUNC(selected)) params ["", "_container"];

if (isNull _container) exitWith {};

private _list = _display displayCtrl ARSENAL_IDC_LIST;
private _plus = _display displayCtrl ARSENAL_IDC_PLUS;

if (isNull _list || {isNull _plus}) exitWith {
    if !("ungrey" in GVAR(missingSaid)) then {
        GVAR(missingSaid) pushBack "ungrey";
        WARNING("ACE Arsenal's list or its + arrow is not where this addon looks - rows stay greyed by weight.");
    };
};

private _asked = createHashMap;

// Whether one more of a class would be taken: asked as fnc_addNew asks it, with a magazine full. What
// stacks answers by its own pile, so it is asked per class; the rest only needs a free spot of its size,
// asked once per size.
private _fnc_fits = {
    params ["_class"];

    private _info = [_class] call EFUNC(items,getInfo);

    if ((_info getOrDefault ["kind", ""]) isEqualTo "backpack") exitWith {false};

    private _capacity = _info getOrDefault ["capacity", 0];
    private _which = if ((_info getOrDefault ["stack", 1]) > 1) then {
        toLowerANSI _class
    } else {
        str (_info getOrDefault ["size", [1, 1]])
    };
    private _known = _asked get _which;

    if (!isNil "_known") exitWith {_known};

    private _fits = [_container, createHashMapFromArray [
        ["class", _class], ["count", 1], ["ammo", _capacity], ["capacity", _capacity],
        ["attachments", []], ["container", objNull]
    ]] call EFUNC(storage,hasSpace);

    _asked set [_which, _fits];

    _fits
};

if (!_plusOnly) then {
    for "_row" from 0 to ((lnbSize _list) select 0) - 1 do {
        private _color = _list lnbColor [_row, 1];

        if ((_color param [3, 1]) >= 1 || {(_list lnbValue [_row, 2]) == 1}) then {continue};

        if ([_list lnbData [_row, 0]] call _fnc_fits) then {
            _color set [3, 1];
            _list lnbSetColor [[_row, 1], _color];
            _list lnbSetColor [[_row, 2], [1, 1, 1, 1]];
        };
    };
};

private _row = lnbCurSelRow _list;

if (_row < 0 || {ctrlEnabled _plus} || {(_list lnbValue [_row, 2]) == 1}) exitWith {};

if ([_list lnbData [_row, 0]] call _fnc_fits) then {
    _plus ctrlEnable true;
};
