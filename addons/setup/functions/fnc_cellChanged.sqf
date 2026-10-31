#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The Containers step's cells changed without the editor being drawn again (fnc_drawCellEditor): the
 * total of cells and compartments under the drawing, red past the limits (MAX_CELLS, MAX_BLOCKS) or
 * with no cell at all, and "This is how it looks" beside it (fnc_drawPreview), at once. The editor
 * calls it too when it is drawn, so both say the same.
 *
 * Its controls and place come from uiNamespace QGVAR(cellTotals) and QGVAR(previewArgs), which the
 * editor sets; what is gone is left alone.
 *
 * Arguments:
 * 0: Compartments [[cols, rows, holes, pos], ...] <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [[[3, 2, []], [2, 2, [3]]]] call aio_setup_fnc_cellChanged;
 *
 * Public: No
 */

disableSerialization;

params [["_blocks", [], [[]]]];

private _cells = 0;

{
    _cells = _cells + (_x select 0) * (_x select 1) - count (_x param [2, []]);
} forEach _blocks;

private _totals = uiNamespace getVariable [QGVAR(cellTotals), controlNull];

if (!isNull _totals) then {
    _totals ctrlSetText format [LLSTRING(Cont_Totals), _cells, MAX_CELLS, count _blocks, MAX_BLOCKS];
    _totals ctrlSetTextColor ([
        GVAR(theme) getOrDefault ["text2", [0.78, 0.78, 0.78, 1]], GVAR(theme) getOrDefault ["loss", [0.941, 0.333, 0.353, 1]]
    ] select (_cells < 1 || {_cells > MAX_CELLS} || {count _blocks > MAX_BLOCKS}));
};

(uiNamespace getVariable [QGVAR(previewArgs), []]) params [["_display", displayNull], ["_box", controlNull], ["_rect", []]];

if (!isNull _box) then {
    [_display, _box, _rect, GVAR(theme), _blocks] call FUNC(drawPreview);
};
