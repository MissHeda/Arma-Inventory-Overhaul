#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Selects every tile of a holder that can be selected - searched, not under way, on a grid of a column -
 * in reading order: Ctrl+A with the mouse over a section, and "Select all in" in the menu.
 *
 * Arguments:
 * 0: Holder - the section's container <OBJECT>
 *
 * Return Value:
 * Something is selected now <BOOL>
 *
 * Example:
 * [cursorObject] call aio_gui_fnc_selectSection;
 *
 * Public: No
 */

params [["_holder", objNull, [objNull, ""]]];

private _grids = uiNamespace getVariable [QGVAR(grids), []];
private _order = [];
private _refs = [];
private _side = "";

{
    private _grid = _x;

    if (
        (_grid getOrDefault ["holder", objNull]) isNotEqualTo _holder || {_grid getOrDefault ["virtual", true]}
        || {_grid getOrDefault ["overflow", false]} || {(_grid getOrDefault ["window", ""]) isNotEqualTo ""}
        || {(_grid getOrDefault ["side", ""]) isEqualTo ""}
    ) then {continue};

    _side = _grid get "side";

    {
        if (_x getOrDefault ["hidden", false] || {_x getOrDefault ["pending", false]} || {_x getOrDefault ["offPage", false]}) then {continue};

        private _key = _x getOrDefault ["key", ""];

        if (_key isEqualTo "") then {
            _key = [_x] call EFUNC(storage,entryKey);
        };

        private _block = _grid getOrDefault ["block", 0];
        private _row = _x getOrDefault ["row", 0];
        private _col = _x getOrDefault ["col", 0];

        _order pushBack [_block, _row, _col, _refs pushBack [_holder, _key, _block, _col, _row]];
    } forEach (_grid getOrDefault ["tiles", []]);
} forEach _grids;

if (_order isEqualTo []) exitWith {false};

_order sort true;

GVAR(selection) = _order apply {_refs select (_x select 3)};
GVAR(selectionSide) = _side;
GVAR(selectionAnchor) = GVAR(selection) select 0;

[] call FUNC(drawSelection);

true
