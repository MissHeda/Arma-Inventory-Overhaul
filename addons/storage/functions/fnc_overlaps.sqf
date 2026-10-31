#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether two things lying on one grid share a cell. Their boxes have to meet, and where they do a cell
 * that one of them leaves open (a shaped item, size=xx/x-, aio_items_fnc_footprintAs) is no clash: a
 * small item may lie in the corner of an L. For the checks that compare tiles with each other rather
 * than with rows of taken cells (a kit's cells, aio_compat_efak; the window's drag footprint).
 *
 * Arguments:
 * 0: One: [col, row, w, h, holes] as it lies, holes the indices row * w + col, may be left out <ARRAY>
 * 1: The other, the same way <ARRAY>
 *
 * Return Value:
 * They share a cell <BOOL>
 *
 * Example:
 * [[0, 0, 2, 2, [3]], [1, 1, 1, 1]] call aio_storage_fnc_overlaps; // false: the 1x1 lies in the L's corner
 *
 * Public: No
 */

params [["_one", [], [[]]], ["_other", [], [[]]]];

_one params [["_colA", 0], ["_rowA", 0], ["_wA", 1], ["_hA", 1], ["_holesA", []]];
_other params [["_colB", 0], ["_rowB", 0], ["_wB", 1], ["_hB", 1], ["_holesB", []]];

private _left = _colA max _colB;
private _right = (_colA + _wA) min (_colB + _wB);
private _top = _rowA max _rowB;
private _bottom = (_rowA + _hA) min (_rowB + _hB);

if (_left >= _right || {_top >= _bottom}) exitWith {false};
if (_holesA isEqualTo [] && {_holesB isEqualTo []}) exitWith {true};

// Where the boxes meet, cell by cell: a clash is a cell both of them take.
private _clash = false;

for "_r" from _top to (_bottom - 1) do {
    for "_c" from _left to (_right - 1) do {
        if (
            !(((_r - _rowA) * _wA + _c - _colA) in _holesA)
            && {!(((_r - _rowB) * _wB + _c - _colB) in _holesB)}
        ) exitWith {
            _clash = true;
        };
    };

    if (_clash) exitWith {};
};

_clash
