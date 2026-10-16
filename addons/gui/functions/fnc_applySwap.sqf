#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Two tiles swap places for the window (the drop fnc_updateDrag showed in the accent colour, fnc_swapPlan
 * worked out): the dragged tile goes to the cell it was let go on, the tile that lay there to the cell the
 * dragged one came from. One transaction (fnc_sendMoves), so nothing is lost or doubled:
 *   - both in one container: a "placeMany" - op placeMany lifts both and puts them down together, refused
 *     as a whole when a cell is not free then;
 *   - in two containers: a move of the kind "exchange" - take the first, take the second, put the first
 *     where the second lay, put the second where the first lay, each at its own root's authority (one
 *     phase when both roots are the same, else the first's take, the second's take and put, the first
 *     root's put). Whatever an op did not consume settles back where it came from (einv_storage_fnc_settle).
 * The looks at a living person's gear are asked once more here, the machines that run the ops ask their
 * guards again.
 *
 * Arguments:
 * 0: The grid the dragged tile comes from <HASHMAP>
 * 1: The grid it was let go on <HASHMAP>
 * 2: The dragged tile <HASHMAP>
 * 3: The tile that lies there <HASHMAP>
 * 4: The cell the dragged one lands on, [col, row, compartment, width, height, rot] <ARRAY>
 * 5: The cell the other lands on, the same way <ARRAY>
 *
 * Return Value:
 * Asked for <BOOL>
 *
 * Example:
 * [_fromGrid, _toGrid, _entry, _tile, [2, 0, 0, 1, 1, 0], [0, 0, 0, 1, 1, 0]] call einv_gui_fnc_applySwap;
 *
 * Public: No
 */

params [
    ["_fromGrid", createHashMap, [createHashMap]], ["_toGrid", createHashMap, [createHashMap]],
    ["_entry", createHashMap, [createHashMap]], ["_other", createHashMap, [createHashMap]],
    ["_cellEntry", [], [[]]], ["_cellOther", [], [[]]]
];

private _from = _fromGrid getOrDefault ["container", objNull];
private _to = _toGrid getOrDefault ["container", objNull];

if (isNull _from || {isNull _to} || {count _entry == 0} || {count _other == 0}) exitWith {false};
if (_cellEntry isEqualTo [] || {_cellOther isEqualTo []}) exitWith {false};

// Either is on its way already, or was never searched.
if (
    _entry getOrDefault ["pending", false] || {_entry getOrDefault ["hidden", false]}
    || {_other getOrDefault ["pending", false]} || {_other getOrDefault ["hidden", false]}
) exitWith {false};

// Within one container nothing leaves it, so nothing else to ask; between two, the person's gear on either side.
private _why = "";

if (_from isNotEqualTo _to) then {
    _why = [_from, "items"] call FUNC(checkTouch);

    if (_why isEqualTo "") then {
        _why = [_to, "items"] call FUNC(checkTouch);
    };
};

if (_why isNotEqualTo "") exitWith {
    [_why] call FUNC(flashHint);

    false
};

// One container: both tiles laid down at once.
if (_from isEqualTo _to) exitWith {
    [[createHashMapFromArray [
        ["kind", "placeMany"], ["from", _from], ["tiles", [[_entry, _cellEntry], [_other, _cellOther]]]
    ]]] call FUNC(sendMoves)
};

// Two containers: the tile that lies at the target is the move's second half.
[[createHashMapFromArray [
    ["kind", "exchange"], ["from", _from], ["to", _to], ["entry", _entry], ["cell", _cellEntry],
    ["otherEntry", _other], ["otherCell", _cellOther]
]]] call FUNC(sendMoves)
