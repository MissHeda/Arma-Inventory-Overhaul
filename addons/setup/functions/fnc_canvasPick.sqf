#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The picked compartment of a painted canvas (the Paint way of the Containers step, fnc_drawCellEditor). The pick is kept as
 * the places the compartment had when it was picked (GVAR(cellPick)), so it follows the compartment through repainting
 * rather than staying on a number: it is the compartment now that has most of those places (fnc_canvasMatch). With none left,
 * or nothing picked yet, the first compartment is picked.
 *
 * Needs the canvas's compartments, which fnc_canvasBlocks leaves in it when it is asked to (its second argument).
 *
 * Arguments:
 * 0: Painted canvas, after fnc_canvasBlocks with sync <HASHMAP>
 * 1: The places of the compartment that was picked <ARRAY of NUMBER> (default: [])
 *
 * Return Value:
 * [index of the picked compartment, its places] - [-1, []] while nothing is painted <ARRAY>
 *
 * Example:
 * [_canvas, [3, 4]] call einv_setup_fnc_canvasPick; // [1, [3, 4, 5]]
 *
 * Public: No
 */

params [["_canvas", createHashMap, [createHashMap]], ["_cells", [], [[]]]];

private _parts = _canvas getOrDefault ["parts", []];

if (_parts isEqualTo []) exitWith {[-1, []]};

private _index = [_canvas getOrDefault ["label", []], count _parts, _cells] call FUNC(canvasMatch);

if (_index < 0) then {
    _index = 0;
};

[_index, +(_parts select _index)]
