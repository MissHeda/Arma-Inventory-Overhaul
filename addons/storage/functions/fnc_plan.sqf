#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Works out where several things go when they are moved together: for every item the first target, in the
 * order given, that has a free spot for it in one of its compartments (as fnc_hasSpace asks it) - and the
 * cell it takes there. Largest first, so a rucksack does not get the cells a handful of bandages have taken.
 * Free cells are the only limit: what the items weigh decides nothing here.
 *
 * Nothing is changed and nothing is asked of any machine but this one: each target is laid out from what
 * this machine reads of it now (fnc_getContents, fnc_getLayout), and what is planned into it counts for the
 * items after - 25 bandages never all plan the same cell. The authority runs the same layout on the same
 * synced data, so a plan only fails when someone changed the holder meanwhile; then the put falls back to
 * the first fit ("Put elsewhere") or bounces, and settlement takes over (fnc_settle).
 *
 * An item never goes into a target that is the container it is (a backpack tile) or lies in it
 * (fnc_liesIn). "ground" as a target always has room and takes no cell.
 *
 * A stackable tile first fills the stacks of its key in a target that are not full - what a put without a
 * cell does (fnc_opPut) - and only what is left over takes a spot, one tile's worth; what fits into the
 * stacks that are there is assigned with the cell [] (the put joins them). The tiles planned into a target
 * count for the ones after, so a class that is moved in pieces fills the partial stacks first. A tile that
 * stays in the holder it lies in joins nothing there (it is laid down, not put) and always takes a spot.
 *
 * Arguments:
 * 0: Items, entries as the window's tiles are - "class", "count", "key", "block", "col", "row", and
 *    "holder" for where they lie now (anything else they carry stays on them) <ARRAY of HASHMAPs>
 * 1: Targets in the order they are tried, [holder, root] each - a container, or "ground" <ARRAY>
 * 2: Options (default: empty) <HASHMAP>
 *    "start"  - [holder, compartment]: that compartment of that target is tried first
 *    "lifted" - items treated as gone from where they lie, as they are dragged away (default: none)
 *    "order"  - "size" (largest first, default) or "given"
 *
 * Return Value:
 * [assigned, left] <ARRAY>
 *   assigned - [[item, holder, root, cell], ...] in the order they were planned; cell is [col, row,
 *              compartment], with [.., width, height, 1] when it lies turned (rot 1, a quarter
 *              clockwise), [] for the ground and for a stack that joins others without a cell of its
 *              own <ARRAY>
 *   left     - the items no target had room for <ARRAY>
 *
 * Example:
 * [_items, [[backpackContainer player, player]]] call einv_storage_fnc_plan;
 *
 * Public: No
 */

params [["_items", [], [[]]], ["_targets", [], [[]]], ["_options", createHashMap, [createHashMap]]];

private _order = _options getOrDefault ["order", "size"];
private _start = _options getOrDefault ["start", []];
private _lifted = _options getOrDefault ["lifted", []];

if (_items isEqualTo [] || {_targets isEqualTo []}) exitWith {[[], +_items]};

// Whether an entry of a layout is one of the lifted items: the same tile where it lies now.
private _fnc_isLifted = {
    params ["_entry", "_holder"];

    _lifted findIf {
        (_x getOrDefault ["holder", objNull]) isEqualTo _holder
        && {(_x getOrDefault ["key", ""]) isEqualTo (_entry getOrDefault ["key", ""])}
        && {(_x getOrDefault ["block", 0]) == (_entry getOrDefault ["block", 0])}
        && {(_x getOrDefault ["col", -1]) == (_entry getOrDefault ["col", -1])}
        && {(_x getOrDefault ["row", -1]) == (_entry getOrDefault ["row", -1])}
    } >= 0
};

// ---------------------------------------------------------------------------
// A target as the planning sees it, made when the first item asks for it:
//   ["ground"]  or  ["none"] for a holder that is neither the ground nor a container
//   ["grid", holder, root, blocks, open, taken, isBackpack, rooms, resume, tiers]
// taken is per compartment a list of rows of booleans, true where something lies or a shaped compartment
// has a hole; rows past the end are free. rooms is, per key of a stackable class, how much room each of
// its tiles that is not full has left, in the order of the tiles - what a put fills first. resume remembers per shape and
// compartment where the last search found its spot (cells are only ever taken, so the next one starts there), tiers the
// compartments to look through for an item's categories (fnc_blockOrder).
// ---------------------------------------------------------------------------
private _states = _targets apply {[]};

// A shaped item (size=xx/x-) takes only its own cells, holes as it lies (einv_items_fnc_footprintAs).
private _fnc_mark = {
    params ["_state", "_block", "_col", "_row", "_w", "_h", ["_holes", []]];

    [(_state select 5) select _block, ((_state select 3) select _block) select 0, _col, _row, _w, _h, _holes] call FUNC(takeCells);
};

private _fnc_isFree = {
    params ["_state", "_block", "_col", "_row", "_w", "_h", ["_holes", []]];

    ((_state select 3) select _block) params ["_cols", "_rows"];

    if (_col < 0 || {_row < 0} || {_col + _w > _cols} || {!(_state select 4) && {_row + _h > _rows}}) exitWith {false};

    [(_state select 5) select _block, _col, _row, _w, _h, _holes] call FUNC(cellsFree)
};

private _fnc_state = {
    params ["_index"];

    private _known = _states select _index;

    if (_known isNotEqualTo []) exitWith {_known};

    (_targets select _index) params [["_holder", objNull], ["_root", objNull]];

    private _state = ["none"];

    if (_holder isEqualType "" && {_holder isEqualTo "ground"}) then {
        _state = ["ground"];
    };

    if (_holder isEqualType objNull && {!isNull _holder}) then {
        private _contents = [_holder] call FUNC(getContents);
        private _layout = [_holder, _contents] call FUNC(getLayout);
        private _blocks = _layout get "blocks";
        private _open = ([_holder] call FUNC(getBlocks)) isEqualTo [];

        // A shaped compartment's holes are taken from the start (fnc_seedTaken).
        _state = ["grid", _holder, _root, _blocks, _open, [_blocks] call FUNC(seedTaken), getNumber (configOf _holder >> "isBackpack") == 1, createHashMap, createHashMap, createHashMap];

        // What lies there, less what is lifted away: its cells are taken. Most targets have nothing lifted from them.
        private _liftedHere = _lifted findIf {(_x getOrDefault ["holder", objNull]) isEqualTo _holder} >= 0;

        {
            if (_liftedHere && {[_x, _holder] call _fnc_isLifted}) then {continue};

            if (!(_x getOrDefault ["overflow", false]) && {(_x getOrDefault ["block", -1]) >= 0}) then {
                [_state, _x get "block", _x get "col", _x get "row", _x get "w", _x get "h", _x getOrDefault ["holes", []]] call _fnc_mark;

                // A stack that is not full: what a put onto this holder fills first.
                private _tileStack = (([_x getOrDefault ["class", ""]] call EFUNC(items,getInfo)) getOrDefault ["stack", 1]) max 1;
                private _tileCount = _x getOrDefault ["count", 1];

                if (_tileStack > 1 && {_tileCount < _tileStack} && {!(_x getOrDefault ["strict", false])}) then {
                    private _tileKey = _x getOrDefault ["key", ""];
                    private _rooms = (_state select 7) getOrDefault [_tileKey, []];

                    _rooms pushBack (_tileStack - _tileCount);
                    (_state select 7) set [_tileKey, _rooms];
                };
            };
        } forEach (_layout get "entries");
    };

    _states set [_index, _state];

    _state
};

// Whether a single slot has nothing in it yet (fnc_slotOf).
private _fnc_slotFree = {
    params ["_state", "_block"];

    ([((_state select 3) select _block)] call FUNC(slotOf)) params ["_col", "_row", "_w", "_h", "_holes"];

    [(_state select 5) select _block, _col, _row, _w, _h, _holes] call FUNC(cellsFree)
};

// The first free spot for a size and its holes, in the compartments given (in that order): [compartment, col, row], [] for none.
private _fnc_find = {
    params ["_state", "_w", "_h", "_holes", "_order", "_groups"];

    private _spot = [];
    private _blocks = _state select 3;
    private _open = _state select 4;
    private _shape = format ["%1x%2", _w, _h] + (["", str _holes] select (_holes isNotEqualTo []));
    private _from = (_state select 8) get _shape;

    if (isNil "_from") then {
        _from = _blocks apply {0};
        (_state select 8) set [_shape, _from];
    };

    private _plain = _holes isEqualTo [];

    {
        private _block = _x;

        (_blocks select _block) params ["_cols", "_rows"];

        // A compartment that refuses the item is not in the order (fnc_blockOrder); a single slot is one spot, whole, when it is empty.
        if (count (_blocks select _block) > 4 && {([_blocks select _block, _groups] call FUNC(blockMode)) == 1}) then {
            if ([_state, _block] call _fnc_slotFree) then {
                _spot = [_block, 0, 0, true];

                break;
            };

            continue;
        };

        if (_cols < _w) then {continue};

        private _grid = (_state select 5) select _block;

        // The open grid has no end: looking one row past the last one taken always finds room.
        private _lastRow = if (_open) then {count _grid} else {_rows - _h};
        private _start = _from select _block;

        for "_row" from (floor (_start / _cols)) to _lastRow do {
            private _line = _grid param [_row, []];

            for "_col" from ((_start - _row * _cols) max 0) to (_cols - _w) do {
                // A taken first cell rules out any box that has one there (a hole of a shape may lie on it).
                if (_plain && {_line isNotEqualTo []} && {_line select _col}) then {continue};

                if ([_grid, _col, _row, _w, _h, _holes] call FUNC(cellsFree)) exitWith {
                    _spot = [_block, _col, _row];
                    _from set [_block, _row * _cols + _col];
                };
            };

            if (_spot isNotEqualTo []) exitWith {};
        };

        if (_spot isNotEqualTo []) exitWith {};

        _from set [_block, (_lastRow + 1) * _cols];
    } forEach _order;

    _spot
};

// The compartments to look through for an item, in tiers: the one asked for first (the options' "start") and those whose
// category lock includes one of its categories, then the unrestricted ones (fnc_blockOrder). Each tier is tried upright, then
// turned, before the next.
private _fnc_tiers = {
    params ["_state", "_first", "_groups"];

    private _key = str [_first, _groups];
    private _tiers = (_state select 9) get _key;

    if (isNil "_tiers") then {
        private _blocks = _state select 3;
        private _order = [_blocks, _groups, _first] call FUNC(blockOrder);
        private _locked = _order select {_x == _first || {count (_blocks select _x) > 4 && {((_blocks select _x) select 4) isNotEqualTo []}}};

        _tiers = [_locked, _order - _locked] select {_x isNotEqualTo []};
        (_state select 9) set [_key, _tiers];
    };

    _tiers
};

// ---------------------------------------------------------------------------
// The items, largest first (then category, class, and the order they came in - so the same items always
// plan the same way).
// ---------------------------------------------------------------------------
private _sequence = [];

{
    private _info = [_x getOrDefault ["class", ""]] call EFUNC(items,getInfo);

    (_info getOrDefault ["size", [1, 1]]) params ["_w", "_h"];

    _sequence pushBack ([
        [_forEachIndex, 0, "", _forEachIndex],
        [-(_w * _h), _info getOrDefault ["category", 0], toLowerANSI (_x getOrDefault ["class", ""]), _forEachIndex]
    ] select (_order isEqualTo "size"));
} forEach _items;

_sequence sort true;

private _assigned = [];
private _left = [];

{
    private _item = _items select (_x select 3);
    private _class = _item getOrDefault ["class", ""];
    private _info = [_class] call EFUNC(items,getInfo);

    (_info getOrDefault ["footprint", [1, 1, []]]) params ["_w", "_h", ["_holes", []]];

    private _turnedHoles = (_info getOrDefault ["footprintTurned", [_h, _w, []]]) param [2, []];
    private _isBackpack = (_info getOrDefault ["kind", ""]) isEqualTo "backpack";
    private _groups = _info getOrDefault ["groups", ["misc"]];
    private _stackSize = (_info getOrDefault ["stack", 1]) max 1;
    private _inside = _item getOrDefault ["container", objNull];
    private _done = false;

    {
        private _state = [_forEachIndex] call _fnc_state;
        private _kind = _state select 0;

        if (_kind isEqualTo "none") then {continue};

        // The ground always has room and needs no cell.
        if (_kind isEqualTo "ground") exitWith {
            _assigned pushBack [_item, "ground", (_targets select _forEachIndex) param [1, objNull], []];
            _done = true;
        };

        _state params ["", "_holder", "_root", "", "", "", "_holderIsBackpack", "_rooms"];

        // Not into itself, nor into anything lying in it.
        if (!isNull _inside && {_holder isEqualTo _inside || {[_holder, _inside] call FUNC(liesIn)}}) then {continue};

        // A backpack never goes into a backpack.
        if (_isBackpack && {_holderIsBackpack}) then {continue};

        // A stackable tile first fills the stacks of its key that are not full there (what its put does); only
        // what is left over needs a spot of its own, one tile's worth.
        private _remaining = (_item getOrDefault ["count", 1]) max 1;
        private _fills = [];
        private _itemKey = _item getOrDefault ["key", ""];

        if (_stackSize > 1 && {isNull _inside}) then {
            if (_itemKey isEqualTo "") then {
                _itemKey = [_item] call FUNC(entryKey);
            };

            // One that stays in the holder it lies in is laid down there (op placeMany), never put: it joins
            // nothing and needs a cell of its own.
            if ((_item getOrDefault ["holder", objNull]) isEqualTo _holder) exitWith {};

            {
                if (_remaining > 0 && {_x > 0}) then {
                    private _fill = _remaining min _x;

                    _fills pushBack [_forEachIndex, _fill];
                    _remaining = _remaining - _fill;
                };
            } forEach (_rooms getOrDefault [_itemKey, []]);
        };

        // The rooms the tile fills are used up, and what opens beyond them is room for what comes after.
        private _fnc_fill = {
            if (_fills isEqualTo [] && {_remaining >= _stackSize}) exitWith {};

            private _list = +(_rooms getOrDefault [_itemKey, []]);

            {
                _list set [_x select 0, (_list select (_x select 0)) - (_x select 1)];
            } forEach _fills;

            if (_stackSize > 1 && {isNull _inside} && {_remaining > 0} && {_remaining < _stackSize}) then {
                _list pushBack (_stackSize - _remaining);
            };

            _rooms set [_itemKey, _list];
        };

        // All of it fits into stacks that are there: no cell.
        if (_remaining <= 0) exitWith {
            call _fnc_fill;
            _assigned pushBack [_item, _holder, _root, []];
            _done = true;
        };

        private _firstBlock = if (_start isNotEqualTo [] && {(_start select 0) isEqualTo _holder}) then {_start param [1, -1]} else {-1};
        private _turned = false;
        private _spot = [];

        {
            _spot = [_state, _w, _h, _holes, _x, _groups] call _fnc_find;

            // Fits nowhere upright: turned a quarter, as a player would - a shape turns with it, and one in a
            // square box is tried turned too when that takes other cells.
            if (_spot isEqualTo [] && {_w != _h || {_holes isNotEqualTo _turnedHoles}}) then {
                _spot = [_state, _h, _w, _turnedHoles, _x, _groups] call _fnc_find;
                _turned = _spot isNotEqualTo [];
            };

            if (_spot isNotEqualTo []) exitWith {};
        } forEach ([_state, _firstBlock, _groups] call _fnc_tiers);

        if (_spot isEqualTo []) then {continue};

        _spot params ["_block", "_col", "_row", ["_slot", false]];

        private _cellW = [_w, _h] select _turned;
        private _cellH = [_h, _w] select _turned;
        private _cellHoles = [_holes, _turnedHoles] select _turned;

        // A single slot takes it whole, upright (fnc_slotOf); the cell is the slot's, the size is not asked.
        if (_slot) then {
            ([(_state select 3) select _block] call FUNC(slotOf)) params ["", "", "_slotW", "_slotH", "_slotHoles"];

            _cellW = _slotW;
            _cellH = _slotH;
            _cellHoles = _slotHoles;
            _turned = false;
        };

        [_state, _block, _col, _row, _cellW, _cellH, _cellHoles] call _fnc_mark;
        call _fnc_fill;

        _assigned pushBack [_item, _holder, _root, [[_col, _row, _block], [_col, _row, _block, _cellW, _cellH, 1]] select _turned];
        _done = true;
    } forEach _targets;

    if (!_done) then {
        _left pushBack _item;
    };
} forEach _sequence;

[_assigned, _left]
