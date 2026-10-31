#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Which compartment of a painted canvas a set of places has most in common with. The way an attribute (the
 * categories a compartment accepts, a single slot) and the picked compartment follow a compartment through
 * repainting (fnc_canvasBlocks, fnc_canvasPick): the compartments are numbered in reading order of their first cell, the
 * places that were once the compartment's are counted per compartment now, and the one with most wins - the first of
 * them on a tie. So a compartment split in two keeps its attributes on the larger part, and of two that grew
 * together the first to ask gets the merged one (the others ask for their next best, which is none when they had
 * only that one).
 *
 * Arguments:
 * 0: Per place the compartment it is in now, -1 for none <ARRAY of NUMBER>
 * 1: How many compartments there are <NUMBER>
 * 2: The places that were the compartment's <ARRAY of NUMBER>
 * 3: Compartments that are not to be chosen, already taken <ARRAY of NUMBER> (default: [])
 *
 * Return Value:
 * The compartment's number, -1 when none of its places is in a compartment that may be chosen <NUMBER>
 *
 * Example:
 * [[0, 0, -1, 1], 2, [1, 2, 3]] call aio_setup_fnc_canvasMatch; // 0
 *
 * Public: No
 */

params [["_label", [], [[]]], ["_count", 0, [0]], ["_cells", [], [[]]], ["_taken", [], [[]]]];

private _overlap = [];

for "_index" from 1 to _count do {
    _overlap pushBack 0;
};

{
    private _id = _label param [_x, -1];

    if (_id >= 0 && {_id < _count}) then {
        _overlap set [_id, (_overlap select _id) + 1];
    };
} forEach _cells;

private _best = -1;
private _most = 0;

{
    if (_x > _most && {!(_forEachIndex in _taken)}) then {
        _best = _forEachIndex;
        _most = _x;
    };
} forEach _overlap;

_best
