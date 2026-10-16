#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Whether the dragged tile may swap places with the one it lies on (Tarkov's behaviour), and where each
 * of the two would go. Asked by fnc_updateDrag for a footprint over taken cells, where the drop would
 * be refused as "NoRoom" otherwise; the answer is kept per footprint for the drag (dragRoom "swap|..."),
 * so it is worked out once per hovered tile, not per frame.
 *
 * A swap is a plain tile-on-tile drop only. The dragged tile lands where the footprint lies, which
 * must cover the cells of exactly one other tile (the rest of it on free cells, or on cells the dragged
 * tile leaves itself); that tile goes to the cell the dragged one came from, as it lies, else turned a
 * quarter - its corner on the dragged one's corner - and must find that spot free too (cells the
 * dragged tile and, on one grid, the other tile leave count as free, but the dragged tile's new cells
 * do not). Whole stacks only (the caller passes nothing for part of one), two different classes (the
 * same class would only merge, as the cargo does), neither of them a tile that was not searched or is
 * on its way. Not for a kit's grid, ACE's list, a slot's item or the Arsenal's staging space, and not
 * where the pile on the ground would be left empty by the tile that leaves it (the engine deletes an
 * empty pile). Magazines of a kind that repack, kits and everything else that has its own answer for a
 * drop on its tile never get here (fnc_updateDrag asks them first).
 *
 * The rules that apply to any move apply to both: a backpack never into a backpack, nothing into itself
 * (einv_storage_fnc_liesIn), a living person's gear only as the settings say (fnc_checkTouch), another
 * player's kit stays where it is (einv_compat_efak_fnc_checkTile). Free cells are the only room there
 * is - weight refuses nothing.
 *
 * Arguments:
 * 0: Index of the grid under the mouse <NUMBER>
 * 1: Column the footprint's corner lies on <NUMBER>
 * 2: Row <NUMBER>
 * 3: Width of what is held as it is held <NUMBER>
 * 4: Height <NUMBER>
 * 5: Which way round it is held, 1 turned a quarter clockwise <NUMBER>
 * 6: Which tile lies on each cell of that grid, as fnc_updateDrag keeps it ("cells|n") <ARRAY>
 * 7: The same for the grid the tile comes from <ARRAY>
 *
 * Return Value:
 * [reason, plan] - reason "" when they swap, else why not ("NoRoom" when it is no swap at all); plan
 * [index of the other tile, the cell the dragged one lands on, the cell the other lands on], each cell
 * [col, row, compartment, width, height, rot] as op place takes it, [] without a swap <ARRAY>
 *
 * Example:
 * [_targetIndex, 2, 1, 1, 2, 0, _underTarget, _underSource] call einv_gui_fnc_swapPlan;
 *
 * Public: No
 */

params [
    ["_targetIndex", -1, [0]], ["_col", 0, [0]], ["_row", 0, [0]], ["_w", 1, [0]], ["_h", 1, [0]], ["_rot", 0, [0]],
    ["_underTarget", [], [[]]], ["_underSource", [], [[]]]
];

private _none = ["NoRoom", []];

private _entry = uiNamespace getVariable [QGVAR(dragEntry), createHashMap];
private _grids = uiNamespace getVariable [QGVAR(grids), []];

GVAR(press) params [["_sourceIndex", -1, [0]], ["_tileIndex", -1, [0]], "", "", "", ["_slotSource", [], [[]]]];

if (_slotSource isNotEqualTo [] || {count _entry == 0}) exitWith {_none};

private _target = _grids param [_targetIndex, createHashMap];
private _source = _grids param [_sourceIndex, createHashMap];

if (count _target == 0 || {count _source == 0}) exitWith {_none};

// Containers only: a kit decides for itself, ACE's list has nothing behind its rows.
if (
    (_target getOrDefault ["kit", ""]) isNotEqualTo "" || {(_source getOrDefault ["kit", ""]) isNotEqualTo ""}
    || {(_target getOrDefault ["source", ""]) isNotEqualTo ""} || {(_source getOrDefault ["source", ""]) isNotEqualTo ""}
) exitWith {_none};

private _to = _target getOrDefault ["container", objNull];
private _from = _source getOrDefault ["container", objNull];

if (isNull _to || {isNull _from}) exitWith {_none};

// The Arsenal's staging space is told one class at a time (einv_arsenal_fnc_onDrop).
if ((_to getVariable [QEGVAR(storage,localOnly), false]) || {_from getVariable [QEGVAR(storage,localOnly), false]}) exitWith {_none};

private _sameHolder = _from isEqualTo _to;
private _sameGrid = _targetIndex == _sourceIndex;
private _toBlock = _target getOrDefault ["block", 0];
private _fromBlock = _source getOrDefault ["block", 0];

// The same compartment shown twice would hide one tile's cells from the other's answer.
if (_sameHolder && {!_sameGrid} && {_toBlock == _fromBlock}) exitWith {_none};

// ----- Where the dragged tile lands: its footprint, over exactly one other tile -----
private _holesHeld = ([_entry getOrDefault ["class", ""], _rot] call EFUNC(items,footprintAs)) select 2;
private _cols = _target get "cols";

if (_col < 0 || {_row < 0} || {_col + _w > _cols} || {_row + _h > (_target get "rows")}) exitWith {_none};
if ([_target, _col, _row, _w, _h, _holesHeld] call FUNC(hitsHole)) exitWith {_none};

private _lifted = [-1, _tileIndex] select _sameGrid;
private _indexB = -1;
private _blocked = false;

for "_r" from 0 to (_h - 1) do {
    for "_c" from 0 to (_w - 1) do {
        if (!((_r * _w + _c) in _holesHeld)) then {
            private _under = _underTarget param [(_row + _r) * _cols + _col + _c, -1];

            if (_under >= 0 && {_under != _lifted}) then {
                if (_indexB < 0) then {
                    _indexB = _under;
                } else {
                    if (_under != _indexB) then {
                        _blocked = true;
                    };
                };
            };
        };
    };
};

if (_blocked || {_indexB < 0}) exitWith {_none};

private _tileB = (_target get "tiles") param [_indexB, createHashMap];

if (count _tileB == 0 || {_tileB getOrDefault ["hidden", false]} || {_tileB getOrDefault ["pending", false]}) exitWith {_none};

private _classA = _entry getOrDefault ["class", ""];
private _classB = _tileB getOrDefault ["class", ""];

// The same class only merges.
if (toLowerANSI _classA isEqualTo toLowerANSI _classB) exitWith {_none};

// A move under way already goes to cells of its own (fnc_drawPending outlines them).
private _fnc_flying = {
    params ["_grid", "_cellCol", "_cellRow", "_cellW", "_cellH", "_cellHoles"];

    if (count GVAR(inFlight) == 0) exitWith {false};

    private _holder = _grid getOrDefault ["holder", _grid getOrDefault ["container", objNull]];
    private _block = _grid getOrDefault ["block", 0];
    private _mask = [_cellCol, _cellRow, _cellW, _cellH, _cellHoles];
    private _hit = false;

    // A HashMap: _x is the request id, _y its record - the cells it goes to second.
    {
        if (((_y param [1, []]) findIf {
            _x params [["_toHolder", objNull], ["_toBlock", 0], ["_toCol", 0], ["_toRow", 0], ["_toW", 1], ["_toH", 1]];

            _toHolder isEqualTo _holder && {_toBlock == _block}
            && {[_mask, [_toCol, _toRow, _toW, _toH]] call EFUNC(storage,overlaps)}
        }) >= 0) exitWith {
            _hit = true;
        };
    } forEach GVAR(inFlight);

    _hit
};

if ([_target, _col, _row, _w, _h, _holesHeld] call _fnc_flying) exitWith {_none};

// ----- Where the other tile lands: the cell the dragged one comes from -----
// Free when nothing lies there but the dragged tile (and, on one grid, the other tile itself), and
// where the dragged tile now lands on that same compartment, not on its cells.
private _fnc_fits = {
    params ["_grid", "_under", "_ignore", "_cellCol", "_cellRow", "_cellW", "_cellH", "_cellHoles"];

    private _gridCols = _grid get "cols";

    if (_cellCol < 0 || {_cellRow < 0} || {_cellCol + _cellW > _gridCols} || {_cellRow + _cellH > (_grid get "rows")}) exitWith {false};
    if ([_grid, _cellCol, _cellRow, _cellW, _cellH, _cellHoles] call FUNC(hitsHole)) exitWith {false};

    private _free = true;

    for "_r" from 0 to (_cellH - 1) do {
        for "_c" from 0 to (_cellW - 1) do {
            private _tile = _under param [(_cellRow + _r) * _gridCols + _cellCol + _c, -1];

            if (!((_r * _cellW + _c) in _cellHoles) && {_tile >= 0} && {!(_tile in _ignore)}) exitWith {
                _free = false;
            };
        };

        if (!_free) exitWith {};
    };

    _free
};

private _ignoreSource = [_tileIndex];

if (_sameGrid) then {
    _ignoreSource pushBack _indexB;
};

private _originCol = _entry getOrDefault ["col", 0];
private _originRow = _entry getOrDefault ["row", 0];
private _holesB = _tileB getOrDefault ["holes", []];
private _rotB = parseNumber (_tileB getOrDefault ["rotated", false]);
private _candidates = [[_tileB get "w", _tileB get "h", _holesB, _rotB]];

// Turned a quarter, when that takes other cells.
([_classB, 1 - _rotB] call EFUNC(items,footprintAs)) params ["_turnW", "_turnH", "_turnHoles"];

if (_turnW != (_tileB get "w") || {_turnH != (_tileB get "h")} || {_turnHoles isNotEqualTo _holesB}) then {
    _candidates pushBack [_turnW, _turnH, _turnHoles, 1 - _rotB];
};

private _cellB = [];

{
    _x params ["_cellW", "_cellH", "_cellHoles", "_cellRot"];

    private _clash = _sameHolder && {_toBlock == _fromBlock} && {
        [[_originCol, _originRow, _cellW, _cellH, _cellHoles], [_col, _row, _w, _h, _holesHeld]] call EFUNC(storage,overlaps)
    };

    if (
        !_clash
        && {[_source, _underSource, _ignoreSource, _originCol, _originRow, _cellW, _cellH, _cellHoles] call _fnc_fits}
        && {!([_source, _originCol, _originRow, _cellW, _cellH, _cellHoles] call _fnc_flying)}
    ) exitWith {
        _cellB = [_originCol, _originRow, _fromBlock, _cellW, _cellH, _cellRot];
    };
} forEach _candidates;

if (_cellB isEqualTo []) exitWith {_none};

// ----- The rules of any move, for both ways -----
private _reason = "";

if (!_sameHolder) then {
    // The engine deletes a pile that has nothing left in it: the tile that leaves it cannot be the last.
    if (
        (([_to] call EFUNC(storage,isGroundHolder)) && {count (_target get "tiles") <= 1})
        || {([_from] call EFUNC(storage,isGroundHolder)) && {count (_source get "tiles") <= 1}}
    ) then {
        _reason = "NoRoom";
    };

    if (_reason isEqualTo "") then {
        _reason = [_from, "items"] call FUNC(checkTouch);
    };

    if (_reason isEqualTo "") then {
        _reason = [_to, "items"] call FUNC(checkTouch);
    };

    if (
        _reason isEqualTo ""
        && {([_to, _entry] call EFUNC(storage,backpackIntoBackpack)) || {[_from, _tileB] call EFUNC(storage,backpackIntoBackpack)}}
    ) then {
        _reason = "NoBackpack";
    };

    // A uniform, vest or backpack into what lies in it - either of them.
    private _insideA = _entry getOrDefault ["container", objNull];
    private _insideB = _tileB getOrDefault ["container", objNull];

    if (
        _reason isEqualTo ""
        && {(!isNull _insideA && {_to isEqualTo _insideA || {[_to, _insideA] call EFUNC(storage,liesIn)}})
            || {!isNull _insideB && {_from isEqualTo _insideB || {[_from, _insideB] call EFUNC(storage,liesIn)}}}}
    ) then {
        _reason = "IntoItself";
    };

    // Another living player's kit stays where it is (einv_compat_efak).
    if (_reason isEqualTo "" && {!isNil QEFUNC(compat_efak,checkTile)}) then {
        _reason = [_classA, _from] call EFUNC(compat_efak,checkTile);

        if (_reason isEqualTo "") then {
            _reason = [_classB, _to] call EFUNC(compat_efak,checkTile);
        };
    };
};

if (_reason isNotEqualTo "") exitWith {[_reason, []]};

["", [_indexB, [_col, _row, _toBlock, _w, _h, _rot], _cellB]]
