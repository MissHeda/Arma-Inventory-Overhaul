#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What happens to the tiles dragged together (GVAR(dragGroup)) if they are let go over a cell of a grid:
 *
 *   "keep" - they keep their arrangement: all come from one compartment, and every tile's cell - the
 *            hovered cell less the grabbed tile's offset, plus its own offset from the grabbed tile - lies
 *            inside the hovered compartment on cells that are free or lifted by this drag; into another
 *            holder none of them may be a backpack for a backpack
 *   "pack" - otherwise, over a grid: they are packed into the hovered container, largest first, the
 *            hovered compartment first, those that fit moving and the rest staying (einv_storage_fnc_plan)
 *   "kit"  - over an open kit's window or a kit's tile: the kit takes each one or not (einv_compat_efak)
 *   "none" - into a dragged container or one that lies in it, or into a living person's container the
 *            player may not put into: nothing moves, the reason says why
 *
 * Asked again for every cell the mouse comes to; the answer is kept for the drag in GVAR(dragRoom) under
 * "group|<grid index>|<col>|<row>", as are the answers of the kits.
 *
 * Arguments:
 * 0: Index of the hovered grid <NUMBER>
 * 1: The hovered cell, [col, row] <ARRAY>
 *
 * Return Value:
 * [mode, data, fitting, total, reason] <ARRAY>
 *   mode    - "keep", "pack", "kit" or "none"
 *   data    - keep: [[grid index, tile index, col, row], ...] where each goes; pack: [assigned, left] as
 *             einv_storage_fnc_plan answers; kit: [index of the kit's tile in the grid, -1 for the grid
 *             itself]; none: []
 *   fitting - how many go
 *   total   - how many are dragged
 *   reason  - why not, as fnc_flashHint reads it, "" when some go
 *
 * Example:
 * [3, [2, 1]] call einv_gui_fnc_groupMode;
 *
 * Public: No
 */

disableSerialization;

params [["_targetIndex", -1, [0]], ["_cell", [], [[]]]];

private _key = format ["group|%1|%2|%3", _targetIndex, _cell param [0, 0], _cell param [1, 0]];
private _kept = GVAR(dragRoom) get _key;

if (!isNil "_kept") exitWith {_kept};

private _grids = uiNamespace getVariable [QGVAR(grids), []];
private _target = _grids param [_targetIndex, createHashMap];
private _group = GVAR(dragGroup);
private _total = count _group;

private _fnc_done = {
    params ["_mode", "_data", "_fitting", ["_reason", ""]];

    private _answer = [_mode, _data, _fitting, _total, _reason];

    GVAR(dragRoom) set [_key, _answer];

    _answer
};

if (count _target == 0 || {_total == 0}) exitWith {
    ["none", [], 0, "Failed"] call _fnc_done
};

// The tiles and the grids they lie on.
private _tiles = _group apply {
    private _grid = _grids param [_x select 0, createHashMap];

    [_grid, (_grid getOrDefault ["tiles", []]) param [_x select 1, createHashMap]]
};

private _to = _target getOrDefault ["container", objNull];
private _toKit = _target getOrDefault ["kit", ""];
private _holder = _target getOrDefault ["holder", objNull];

// ----- A kit's tile, or a kit's window -----
private _kitTile = -1;
private _kit = _toKit;

if (!isNil QEFUNC(compat_efak,canDrop)) then {
    private _underIndex = [_target, _cell] call FUNC(tileAt);
    private _under = (_target getOrDefault ["tiles", []]) param [_underIndex, createHashMap];

    if (
        _underIndex >= 0
        && {_group findIf {_x isEqualTo [_targetIndex, _underIndex]} < 0}
        && {!(_under getOrDefault ["hidden", false])}
        && {[_under getOrDefault ["class", ""]] call EFUNC(compat_efak,isKit)}
    ) then {
        _kitTile = _underIndex;
        _kit = _under get "class";
    };
};

if (_kit isNotEqualTo "") exitWith {
    if (isNil QEFUNC(compat_efak,canDrop)) exitWith {["none", [], 0, "Failed"] call _fnc_done};

    private _fitting = 0;
    private _why = "";

    {
        _x params ["_grid", "_tile"];

        private _from = [_grid getOrDefault ["container", objNull], ""];

        // On a kit's tile the kit asks where that tile lies; on its window's grid it is the grid itself.
        private _answer = if (_kitTile >= 0) then {
            [_from, _kit, _tile, -1, [], [_to, _toKit]] call EFUNC(compat_efak,canDrop)
        } else {
            [_from, _kit, _tile, -1, []] call EFUNC(compat_efak,canDrop)
        };

        _answer params [["_fits", false], ["_reason", ""]];

        if (_fits) then {
            _fitting = _fitting + 1;
        } else {
            if (_why isEqualTo "") then {
                _why = [_reason, "Failed"] select (_reason isEqualTo "");
            };
        };
    } forEach _tiles;

    // The kit has to take every one: it is "one move", not a part of them.
    ["kit", [_kitTile], _fitting, ["", _why] select (_fitting < _total)] call _fnc_done
};

// ----- Into itself: a dragged uniform, vest or backpack, or anything lying in one -----
private _itself = false;

if ((_holder isEqualType "" && {_holder isNotEqualTo ""}) || {_holder isEqualType objNull && {!isNull _holder}}) then {
    _itself = _tiles findIf {
        private _inside = (_x select 1) getOrDefault ["container", objNull];

        !isNull _inside && {[_holder, _inside] call EFUNC(storage,liesIn)}
    } >= 0;
};

if (_itself) exitWith {
    ["none", [], 0, "IntoItself"] call _fnc_done
};

// ----- A living person's container the player may not put into, or who is out of reach by now -----
private _touch = [_to, "items"] call FUNC(checkTouch);

if (_touch isNotEqualTo "") exitWith {
    ["none", [], 0, _touch] call _fnc_done
};

// ----- Keep the arrangement -----
// Possible when all come from one compartment: one grid among the tiles.
GVAR(press) params ["_sourceIndex", "_tileIndex", "", "_grab"];
_grab params ["_grabCol", "_grabRow"];

private _sources = [];

{
    _sources pushBackUnique (_x select 0);
} forEach _group;

private _grabbed = ((_grids param [_sourceIndex, createHashMap]) getOrDefault ["tiles", []]) param [_tileIndex, createHashMap];
private _keepCells = [];
private _keepOk = count _sources == 1 && {count _grabbed > 0};

// A compartment that takes only some categories or is a single slot (einv_storage_fnc_blockMode) is not a place to keep an arrangement in:
// the tiles are packed by the plan, which asks every compartment what it takes.
if (_keepOk && {(_target getOrDefault ["accepts", []]) isNotEqualTo [] || {_target getOrDefault ["single", false]}}) then {
    _keepOk = false;
};

if (_keepOk) then {
    // Where the grabbed tile would lie, and every other tile at its offset from it.
    private _baseCol = (_cell select 0) - _grabCol - (_grabbed get "col");
    private _baseRow = (_cell select 1) - _grabRow - (_grabbed get "row");
    private _cols = _target get "cols";
    // Of a paged compartment only the rows that show: the arrangement lands on the page, never past it.
    private _rows = _target getOrDefault ["rowTo", _target get "rows"];
    private _rowsFrom = _target getOrDefault ["rowFrom", 0];
    private _block = _target getOrDefault ["block", 0];

    // The cells a move under way goes to count as taken, as for a single tile (fnc_updateDrag).
    private _busy = [];

    {
        _y params ["", ["_movedTo", [], [[]]]];

        {
            _x params [["_toHolder", objNull], ["_toBlock", 0], ["_toCol", 0], ["_toRow", 0], ["_toW", 1], ["_toH", 1]];

            if (_toHolder isEqualTo _holder && {_toBlock == _block}) then {
                _busy pushBack [_toCol, _toRow, _toW, _toH];
            };
        } forEach _movedTo;
    } forEach GVAR(inFlight);

    {
        _x params ["", "_tile"];

        private _col = _baseCol + (_tile get "col");
        private _row = _baseRow + (_tile get "row");
        private _w = _tile get "w";
        private _h = _tile get "h";

        // A shaped item (size=xx/x-) takes only its own cells, as it lies (einv_storage_fnc_overlaps).
        private _mask = [_col, _row, _w, _h, _tile getOrDefault ["holes", []]];

        // Inside the compartment, and none of its cells on a shaped compartment's holes.
        if (_col < 0 || {_row < _rowsFrom} || {_col + _w > _cols} || {_row + _h > _rows} || {[_target, _col, _row, _w, _h, _mask select 4] call FUNC(hitsHole)}) exitWith {
            _keepOk = false;
        };

        // Free: no tile of this grid lies there but those lifted by this drag, and no move is going there.
        private _clash = false;

        {
            private _other = _x;
            private _otherIndex = _forEachIndex;

            if (
                (_group findIf {_x isEqualTo [_targetIndex, _otherIndex]}) < 0
                && {[_mask, [_other get "col", _other get "row", _other get "w", _other get "h", _other getOrDefault ["holes", []]]] call EFUNC(storage,overlaps)}
            ) exitWith {
                _clash = true;
            };
        } forEach (_target getOrDefault ["tiles", []]);

        if (!_clash) then {
            _clash = _busy findIf {[_mask, _x] call EFUNC(storage,overlaps)} >= 0;
        };

        if (_clash) exitWith {
            _keepOk = false;
        };

        _keepCells pushBack [(_group select _forEachIndex) select 0, (_group select _forEachIndex) select 1, _col, _row];
    } forEach _tiles;

    // Into another holder none of them may be a backpack for a backpack; the cells were checked above.
    private _sourceHolder = (_grids param [_sources select 0, createHashMap]) getOrDefault ["holder", objNull];

    if (_keepOk && {_holder isNotEqualTo _sourceHolder}) then {
        _keepOk = !isNull _to && {(_tiles findIf {[_to, _x select 1] call EFUNC(storage,backpackIntoBackpack)}) < 0};
    };
};

if (_keepOk) exitWith {
    ["keep", _keepCells, _total] call _fnc_done
};

// ----- Pack them into the hovered container -----
private _items = _tiles apply {
    _x params ["_grid", "_tile"];

    _tile set ["holder", _grid getOrDefault ["holder", objNull]];
    _tile set ["root", _grid getOrDefault ["root", objNull]];

    _tile
};

if (isNull _to) exitWith {
    ["none", [], 0, "Failed"] call _fnc_done
};

private _planOptions = createHashMapFromArray [["start", [_holder, _target getOrDefault ["block", 0]]], ["lifted", _items]];
([_items, [[_holder, _target getOrDefault ["root", objNull]]], _planOptions] call EFUNC(storage,plan)) params ["_assigned", "_left"];

["pack", [_assigned, _left], count _assigned, ["NoRoom", ""] select (_assigned isNotEqualTo [])] call _fnc_done
