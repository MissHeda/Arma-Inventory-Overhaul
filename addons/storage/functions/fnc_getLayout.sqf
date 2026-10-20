#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Where each entry lies in a holder: in which of its compartments (fnc_getBlocks) and on which cell,
 * upright or turned a quarter. Every entry gets "block", "col", "row", "w", "h" (as it lies), "holes"
 * (the cells of its box a shaped item does not take, as it lies, einv_items_fnc_footprintAs),
 * "rotated" and "overflow" set on it, and "key" where it had none (fnc_entryKey) - the entry HashMaps
 * change in place. A shaped item takes only its own cells: something else may lie in the corner an L
 * leaves open (fnc_cellsFree, fnc_takeCells).
 *
 * A pure function of the holder's places (fnc_readPlaces), its entries and the rules: every machine
 * draws the same picture from the same data, and nothing is written here - the authority persists the
 * picture when the records drifted from the cargo (fnc_normalize). Nothing in it depends on the order
 * the engine lists cargo in for items that look different, on the machine or on time.
 *
 *   1. exact - the n-th record of a key goes to the n-th entry of that key (fnc_getContents gives
 *      entries of one key in a fixed order: a split stack full tiles first), when its size matches
 *      the way round it says, its compartment exists and its cells are free. Records are taken in their
 *      order, so of two that claim the same cells the first wins everywhere.
 *   2. kin - every record still unused, in order, goes to the first unplaced entry of the same kind
 *      (fnc_layoutKey; entries sorted by key and index) whose size matches it either way round, when its
 *      cells are free: a repacked magazine, a radio that got its instance class, a kit made ready stay
 *      where they lay.
 *   3. first fit - the rest, in the order asked for (argument 4; largest first, then category, kind, key
 *      and index, when none is): compartment after compartment, row by row, upright, else turned a
 *      quarter (a square box only when it is a shape that turned takes other cells).
 * A record is [key, col, row, w, h, block, rot], rot 1 when it lies turned a quarter clockwise. One
 * written before rot existed has six elements: it lies turned when its width is not the upright one. The
 * record of a tile of a class that stacks also has its count as an eighth element; the layout does not
 * read it (fnc_getContents does, fnc_stackCounts), it writes the count of every such tile it placed.
 * A compartment may accept only some categories (a fifth element of its block, fnc_blockMode; grid=2x2:ammo|grenade):
 * no record, kin or first fit puts an entry there that is in none of them, so it lies in another compartment or is
 * overflow, whatever an older record says. A single slot (a sixth element, grid=1x1:grenade:one) holds one tile whatever its
 * size: the tile takes the compartment whole (fnc_slotOf) - its record is [key, 0, 0, the compartment's columns and rows,
 * its block, 0] and the entry has "single" true, the window draws the item scaled into the slot -, and a record in a slot
 * is kept for any entry the slot accepts, its own size aside.
 * An entry no compartment has room for - the engine took it from a script or another mod - is
 * "overflow": shown apart, never lost. The ground and a grid with no object of its own (a kit of
 * Enhanced First Aid Kits, einv_compat_efak) have no compartments: one STORAGE_COLS wide that grows with
 * what lies there, always a row more than it needs. A kit that a rule or its config gives a grid has the
 * compartments of that grid instead (fnc_getBlocks, GVAR(holderTypes) "blocks").
 *
 * Arguments:
 * 0: Holder - a container, or the key of a grid with no object ("kit:" + lowercase class) <OBJECT or
 *    STRING>
 * 1: Entries (fnc_getContents) <ARRAY>
 * 2: Unused - kept for its callers, which pass whether to keep the layout; nothing is ever kept here
 *    <ANY> (default: nil)
 * 3: Places to lay out from instead of the holder's own: [revision, records] or just the records
 *    <ARRAY> (default: fnc_readPlaces)
 * 4: The order the first fit lays the rest out in - what a Sort asks for (fnc_opSort), one of SORT_MODES:
 *    "size" largest first, then category, kind, key and index; "name" by name; "weight" heaviest first
 *    (what the tile weighs, fnc_getMass), then by name; "type" weapons, ammo, gear, medical and the rest,
 *    each by kind, then largest first, then by name. Entries equal in all of it go by key and index, so
 *    the same contents come out the same on every machine. Anything else is "size" <STRING>
 *    (default: "size")
 *
 * Return Value:
 * HashMap <HASHMAP>
 *   "entries"  - all of them, placed
 *   "blocks"   - the compartments [[cols, rows, holes, pos], ...] (fnc_blocksFor) - the open grid's
 *                with the rows it needs now
 *   "overflow" - the entries with no room
 *   "records"  - one per placed entry, canonical (fnc_readPlaces): [key, col, row, w, h, block, rot], with
 *                the count of a stackable tile as an eighth element. A
 *                holder of another type that lists nothing keeps the records it was laid out from: a
 *                kit whose contents have not arrived yet would otherwise lose its arrangement
 *   "drift"    - the records laid out from are not exactly "records" - the authority should persist
 *                these (fnc_normalize)
 *   "revision" - the revision of the places laid out from, -1 for records given without one
 *
 * Example:
 * private _container = backpackContainer player;
 * [_container, [_container] call einv_storage_fnc_getContents] call einv_storage_fnc_getLayout;
 *
 * Public: No
 */

params [["_holder", objNull, [objNull, ""]], ["_entries", [], [[]]], "", "_given", ["_sortBy", "size", [""]]];

// A key has no compartments and no object; isNull would fail on it.
private _isKey = _holder isEqualType "";
private _valid = if (_isKey) then {_holder isNotEqualTo ""} else {!isNull _holder};

private _places = [0, []];

if (isNil "_given") then {
    if (_valid) then {_places = [_holder] call FUNC(readPlaces)};
} else {
    if !(_given isEqualType []) then {_given = []};

    _places = if (_given isEqualTypeArray [0, []]) then {_given} else {[-1, _given]};
};

_places params ["_revision", "_in"];

// A key's compartments are those its type gives (fnc_getBlocks): none for an open grid.
private _blocks = if (_valid) then {[_holder] call FUNC(getBlocks)} else {[]};
private _open = _blocks isEqualTo [];

// Compartments that accept only some categories or hold one item of any size (grid=2x2:ammo, grid=1x1:grenade:one). Almost no
// container has one, so none of the checks below is made for the rest.
private _special = _blocks findIf {count _x > 4} >= 0;
private _groupsOf = [];             // per entry: its categories (getInfo "groups")

if (_open) then {
    _blocks = [[STORAGE_COLS, 1e6, [], []]];
};

// Per compartment, one array of booleans per row, true where something lies - or where a shaped
// compartment has a hole, so nothing is ever placed on one (fnc_seedTaken). Rows are only added once
// something lies in them, so every row past the end is free.
private _taken = [_blocks] call FUNC(seedTaken);

private _fnc_isFree = {
    params ["_block", "_col", "_row", "_w", "_h", ["_holes", []]];

    if (_block < 0 || {_block >= count _blocks}) exitWith {false};

    (_blocks select _block) params ["_cols", "_rows"];

    if (_col < 0 || {_row < 0} || {_col + _w > _cols} || {_row + _h > _rows}) exitWith {false};

    [_taken select _block, _col, _row, _w, _h, _holes] call FUNC(cellsFree)
};

private _fnc_take = {
    params ["_block", "_col", "_row", "_w", "_h", ["_holes", []]];

    [_taken select _block, (_blocks select _block) select 0, _col, _row, _w, _h, _holes] call FUNC(takeCells);
};

// The holes of an entry as it lies: its own upright, its turned ones turned (rot 1).
private _fnc_holes = {
    params ["_index", "_rot"];

    ([_infos select _index, _rot] call EFUNC(items,footprintAs)) select 2
};

// The way round a record says for an entry: its rot, or for a record from before rot its size - turned
// when it is not as wide as the entry upright.
private _fnc_rot = {
    params ["_rot", "_entry", "_w"];

    if (_rot isEqualTo 0 || {_rot isEqualTo 1}) exitWith {_rot};

    parseNumber (_w != (_entry get "w"))
};

// A record's size fits an entry the way round it says: upright as the rules size it, or turned a
// quarter.
private _fnc_sizeFits = {
    params ["_entry", "_w", "_h", "_rot"];

    private _upW = _entry get "w";
    private _upH = _entry get "h";

    ([[_upW, _upH], [_upH, _upW]] select (_rot == 1)) isEqualTo [_w, _h]
};

// What the compartment makes of an entry (fnc_blockMode): -1 it refuses it, 0 it takes it as it is, 1 it is a single slot
// that takes it whole (fnc_slotOf). A compartment without attributes takes everything, as it always did.
private _fnc_modeOf = {
    params ["_index", "_block"];

    if (!_special || {_block < 0} || {_block >= count _blocks}) exitWith {0};

    [_blocks select _block, _groupsOf select _index] call FUNC(blockMode)
};

// Whether a single slot has nothing in it yet.
private _fnc_slotFree = {
    params ["_block"];

    ([_blocks select _block] call FUNC(slotOf)) params ["_col", "_row", "_w", "_h", "_holes"];

    [_taken select _block, _col, _row, _w, _h, _holes] call FUNC(cellsFree)
};

// Puts an entry down. In a single slot it takes the whole compartment, whatever its own size is: its box and holes are the
// slot's, it lies upright, and "single" says so (the window draws the item scaled into the slot, and lifts it at its own size).
private _fnc_put = {
    params ["_index", "_block", "_col", "_row", "_w", "_h", "_rot", ["_slot", false]];

    private _entry = _entries select _index;
    private _holes = [_index, _rot] call _fnc_holes;

    if (_slot) then {
        ([_blocks select _block] call FUNC(slotOf)) params ["", "", "_slotW", "_slotH", "_slotHoles"];

        _col = 0;
        _row = 0;
        _w = _slotW;
        _h = _slotH;
        _rot = 0;
        _holes = _slotHoles;
        _entry set ["single", true];
    };

    [_block, _col, _row, _w, _h, _holes] call _fnc_take;

    _entry set ["rotated", _rot == 1];
    _entry set ["holes", _holes];
    _entry set ["w", _w];
    _entry set ["h", _h];
    _entry set ["block", _block];
    _entry set ["col", _col];
    _entry set ["row", _row];
};

// ---------------------------------------------------------------------------
// The entries: upright size, key, and per key the index of each in the order they came.
// ---------------------------------------------------------------------------
private _byKey = createHashMap;     // key -> entry indices, in order
private _meta = [];                 // per entry: [key, index within its key, kind (fnc_layoutKey), category]
private _infos = [];                // per entry: what einv_items_fnc_getInfo gives for its class

{
    private _entry = _x;
    private _class = _entry getOrDefault ["class", ""];
    private _info = [_class] call EFUNC(items,getInfo);

    (_info get "size") params ["_w", "_h"];

    _infos pushBack _info;
    _entry set ["w", _w];
    _entry set ["h", _h];
    _entry set ["holes", (_info getOrDefault ["footprint", [_w, _h, []]]) param [2, []]];
    _entry set ["rotated", false];
    _entry set ["overflow", false];
    _entry set ["single", false];
    _groupsOf pushBack (_info getOrDefault ["groups", ["misc"]]);

    private _key = _entry getOrDefault ["key", ""];

    if (_key isEqualTo "") then {
        _key = [_entry] call FUNC(entryKey);
        _entry set ["key", _key];
    };

    private _list = _byKey get _key;

    if (isNil "_list") then {
        _list = [];
        _byKey set [_key, _list];
    };

    _list pushBack _forEachIndex;
    _meta pushBack [_key, count _list - 1, [_class] call FUNC(layoutKey), _info get "category"];
} forEach _entries;

private _placed = _entries apply {false};
private _used = _in apply {false};

// ---------------------------------------------------------------------------
// 1. Exact: the n-th record of a key to the n-th entry of that key.
// ---------------------------------------------------------------------------
private _seen = createHashMap;

{
    if (_x isEqualType [] && {(_x select [0, 6]) isEqualTypeArray ["", 0, 0, 0, 0, 0]}) then {
        _x params ["_key", "_col", "_row", "_w", "_h", "_block", ["_given", -1]];

        private _n = _seen getOrDefault [_key, 0];

        _seen set [_key, _n + 1];

        private _index = (_byKey getOrDefault [_key, []]) param [_n, -1];

        if (_index >= 0) then {
            private _entry = _entries select _index;
            private _rot = [_given, _entry, _w] call _fnc_rot;
            private _mode = [_index, _block] call _fnc_modeOf;

            // A compartment that refuses it keeps no record of it; a single slot takes it whole, the record's size aside.
            if (_mode == 1) then {
                if ([_block] call _fnc_slotFree) then {
                    [_index, _block, 0, 0, 0, 0, 0, true] call _fnc_put;
                    _placed set [_index, true];
                    _used set [_forEachIndex, true];
                };
            } else {
                if (
                    _mode == 0 && {[_entry, _w, _h, _rot] call _fnc_sizeFits}
                    && {[_block, _col, _row, _w, _h, [_index, _rot] call _fnc_holes] call _fnc_isFree}
                ) then {
                    [_index, _block, _col, _row, _w, _h, _rot] call _fnc_put;
                    _placed set [_index, true];
                    _used set [_forEachIndex, true];
                };
            };
        };
    };
} forEach _in;

// ---------------------------------------------------------------------------
// 2. Kin: records still unused to unplaced entries of the same kind. The class of a record is the part
// of its key before the first "|".
// ---------------------------------------------------------------------------
private _kinOf = createHashMap;     // kind -> [[key, index within key, entry index], ...]

{
    if !(_placed select _forEachIndex) then {
        _x params ["_key", "_n", "_kind"];

        private _list = _kinOf get _kind;

        if (isNil "_list") then {
            _list = [];
            _kinOf set [_kind, _list];
        };

        _list pushBack [_key, _n, _forEachIndex];
    };
} forEach _meta;

if (count _kinOf > 0) then {
    {
        _y sort true;
    } forEach _kinOf;

    {
        if (!(_used select _forEachIndex) && {_x isEqualType []} && {(_x select [0, 6]) isEqualTypeArray ["", 0, 0, 0, 0, 0]}) then {
            _x params ["_key", "_col", "_row", "_w", "_h", "_block", ["_given", -1]];

            private _candidates = _kinOf getOrDefault [[(_key splitString "|") param [0, ""]] call FUNC(layoutKey), []];

            // Kin may differ in shape within the same box: each candidate is asked with its own holes.
            if (_candidates isNotEqualTo []) then {
                private _rot = 0;
                private _slot = false;
                private _at = _candidates findIf {
                    private _candidate = _x select 2;

                    _rot = [_given, _entries select _candidate, _w] call _fnc_rot;

                    private _mode = [_candidate, _block] call _fnc_modeOf;

                    // A single slot takes any of them whole; a compartment that refuses one is no place for it.
                    _slot = _mode == 1;

                    !(_placed select _candidate) && {_mode >= 0} && {
                        if (_slot) then {
                            [_block] call _fnc_slotFree
                        } else {
                            [_entries select _candidate, _w, _h, _rot] call _fnc_sizeFits
                            && {[_block, _col, _row, _w, _h, [_candidate, _rot] call _fnc_holes] call _fnc_isFree}
                        }
                    }
                };

                if (_at >= 0) then {
                    private _index = (_candidates select _at) select 2;

                    [_index, _block, _col, _row, _w, _h, _rot, _slot] call _fnc_put;
                    _placed set [_index, true];
                    _used set [_forEachIndex, true];
                };
            };
        };
    } forEach _in;
};

// ---------------------------------------------------------------------------
// 3. First fit, in the order asked for: by default largest first, then by category, kind, key and index.
// Whatever the order, entries that tie in all of it end up by key and index - so the same contents always
// come out the same.
// ---------------------------------------------------------------------------
private _order = [];

if !(_sortBy in SORT_MODES) then {
    _sortBy = "size";
};

// The name a tile sorts by, as the machine that lays it out reads it: a Sort writes the result to the
// places, and everyone reads it from there.
private _fnc_nameOf = {
    params ["_index"];

    toLowerANSI ((_infos select _index) getOrDefault ["name", ""])
};

// Weapons first, then what goes into them, then what is worn, then medical items, then the rest - indexed
// by CATEGORY_MISC to CATEGORY_MEDICAL.
private _typeRank = [4, 2, 0, 1, 3];

{
    if !(_placed select _forEachIndex) then {
        private _index = _forEachIndex;

        (_meta select _index) params ["_key", "_n", "_kind", "_category"];

        private _area = (_x get "w") * (_x get "h");

        // The entry's own index is the last element of every row: the loop below reads it from there.
        _order pushBack (switch (_sortBy) do {
            case "name": {[[_index] call _fnc_nameOf, _key, _n, _index]};
            case "weight": {[-([[_x]] call FUNC(getMass)), [_index] call _fnc_nameOf, _key, _n, _index]};
            case "type": {
                [
                    _typeRank param [_category, 4], (_infos select _index) getOrDefault ["kind", ""], -_area,
                    [_index] call _fnc_nameOf, _key, _n, _index
                ]
            };
            default {[-_area, _category, _kind, _key, _n, _index]};
        });
    };
} forEach _entries;

_order sort true;

private _overflow = [];

// The first free spot for that size and those holes in the compartments of one tier (fnc_blockOrder), compartment after
// compartment, row by row. Cells are only ever taken from here on, so a cell that was not free for a shape never is again:
// every search remembers per shape and compartment where it found its spot, and the next one for that shape starts there
// instead of at the top - a crate of hundreds of tiles is laid out in one pass over its cells, not once per tile.
private _resume = createHashMap;    // shape -> per compartment the first cell (row * cols + col) still worth a look

private _fnc_find = {
    params ["_w", "_h", "_holes", "_entryIndex", "_order"];

    private _spot = [];
    private _shape = format ["%1x%2", _w, _h] + (["", str _holes] select (_holes isNotEqualTo []));
    private _from = _resume get _shape;

    if (isNil "_from") then {
        _from = _blocks apply {0};
        _resume set [_shape, _from];
    };

    private _plain = _holes isEqualTo [];

    {
        private _block = _x;

        (_blocks select _block) params ["_cols", "_rows"];

        // A single slot is one spot, whole, when it is empty (a compartment that refuses the entry is not in the order).
        if (_special && {_entryIndex >= 0}) then {
            if (([_entryIndex, _block] call _fnc_modeOf) == 1) then {
                if ([_block] call _fnc_slotFree) then {
                    _spot = [_block, 0, 0, true];

                    break;
                };

                continue;
            };
        };

        if (_cols < _w) then {continue};

        private _grid = _taken select _block;

        // The open grid: past its last row everything is free, so looking one row further always ends.
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

// The compartments to look through for an entry, in tiers: the compartments whose category lock includes one of its
// categories, then the unrestricted ones (fnc_blockOrder). Each tier is tried upright, then turned, before the next.
private _tierCache = createHashMap;
private _plainTiers = [[]];

{
    (_plainTiers select 0) pushBack _forEachIndex;
} forEach _blocks;

private _fnc_tiers = {
    params ["_index"];

    if (!_special) exitWith {_plainTiers};

    private _groups = _groupsOf select _index;
    private _key = str _groups;
    private _tiers = _tierCache get _key;

    if (isNil "_tiers") then {
        private _order = [_blocks, _groups] call FUNC(blockOrder);
        private _locked = _order select {count (_blocks select _x) > 4 && {((_blocks select _x) select 4) isNotEqualTo []}};

        _tiers = [_locked, _order - _locked] select {_x isNotEqualTo []};
        _tierCache set [_key, _tiers];
    };

    _tiers
};

{
    private _index = _x select -1;
    private _entry = _entries select _index;
    private _w = _entry get "w";
    private _h = _entry get "h";
    private _holes = [_index, 0] call _fnc_holes;
    private _turnedHoles = [_index, 1] call _fnc_holes;
    private _canTurn = _w != _h || {_holes isNotEqualTo _turnedHoles};
    private _spot = [];

    // Upright, else turned a quarter as a player would - a shape turns with it, and one in a square box is tried turned
    // too when that takes other cells -, in the preferred compartments first.
    {
        _spot = [_w, _h, _holes, _index, _x] call _fnc_find;

        if (_spot isEqualTo [] && {_canTurn}) then {
            _spot = [_h, _w, _turnedHoles, _index, _x] call _fnc_find;

            if (_spot isNotEqualTo []) then {
                _entry set ["w", _h];
                _entry set ["h", _w];
                _entry set ["rotated", true];
                _entry set ["holes", _turnedHoles];
                _w = _entry get "w";
                _h = _entry get "h";
                _holes = _turnedHoles;
            };
        };

        if (_spot isNotEqualTo []) exitWith {};
    } forEach ([_index] call _fnc_tiers);

    if (_spot isEqualTo []) then {
        _entry set ["overflow", true];
        _overflow pushBack _entry;
    } else {
        _spot params ["_block", "_col", "_row", ["_slot", false]];

        // A single slot takes the entry whole, upright, whatever turn the search was in.
        if (_slot) then {
            ([_blocks select _block] call FUNC(slotOf)) params ["_slotCol", "_slotRow", "_slotW", "_slotH", "_slotHoles"];

            _col = _slotCol;
            _row = _slotRow;
            _w = _slotW;
            _h = _slotH;
            _holes = _slotHoles;
            _entry set ["w", _w];
            _entry set ["h", _h];
            _entry set ["holes", _holes];
            _entry set ["rotated", false];
            _entry set ["single", true];
        };

        [_block, _col, _row, _w, _h, _holes] call _fnc_take;
        _entry set ["block", _block];
        _entry set ["col", _col];
        _entry set ["row", _row];
    };
} forEach _order;

// The open grid shows the rows it uses, one more to put things in, and never fewer than three.
if (_open) then {
    _blocks = [[STORAGE_COLS, (count (_taken select 0) + 1) max 3, [], []]];
};

// Lined up in a row of their own under the compartments, each in its own cell span.
private _col = 0;
{
    _x set ["block", -1];
    _x set ["col", _col];
    _x set ["row", 0];
    _col = _col + (_x get "w");
} forEach _overflow;

// ---------------------------------------------------------------------------
// The records of this picture, canonical: by key, and within a key in the entries' order - the same
// order fnc_writePlaces keeps. A holder of another type that lists nothing keeps the records it was laid
// out from: a kit of Enhanced First Aid Kits lists nothing until that mod synced its contents here, and
// its arrangement must not be thrown away for a list that is only not there yet.
// ---------------------------------------------------------------------------
// A stackable tile of a container also carries how many it holds (the record's eighth element): two tiles
// of one class stay two, each with its own count (fnc_stackCounts, fnc_getContents). A tile of the hidden
// holder, a kit's tile and every tile of a class that does not stack have none.
private _source = if (_isKey && {_entries isEqualTo []}) then {
    (_in select {_x isEqualType [] && {(_x select [0, 6]) isEqualTypeArray ["", 0, 0, 0, 0, 0]}}) apply {_x select [0, 8]}
} else {
    private _records = [];

    {
        if !(_x get "overflow") then {
            private _record = [_x get "key", _x get "col", _x get "row", _x get "w", _x get "h", _x get "block", parseNumber (_x get "rotated")];

            if (!_isKey && {((_infos select _forEachIndex) getOrDefault ["stack", 1]) > 1} && {!(_x getOrDefault ["strict", false])}) then {
                _record pushBack (_x getOrDefault ["count", 1]);
            };

            _records pushBack _record;
        };
    } forEach _entries;

    _records
};

private _groups = createHashMap;
private _keys = [];

{
    private _key = _x select 0;
    private _group = _groups get _key;

    if (isNil "_group") then {
        _group = [];
        _groups set [_key, _group];
        _keys pushBack _key;
    };

    _group pushBack _x;
} forEach _source;

_keys sort true;

private _out = [];

{
    _out append (_groups get _x);
} forEach _keys;

// Nothing to persist for no holder. A record from before rot says the same as one with the rot its size
// gives: no drift for that alone, so older places are not all written again at once. The same goes for a
// record without a count where the picture has one that nobody changed: a tile of a stackable class that
// never was apart reads the same either way.
private _padded = _in apply {
    if (_x isEqualType [] && {count _x == 6} && {_x isEqualTypeArray ["", 0, 0, 0, 0, 0]}) then {
        private _size = ([((_x select 0) splitString "|") param [0, ""]] call EFUNC(items,getInfo)) getOrDefault ["size", [1, 1]];

        _x + [parseNumber ((_x select 3) != (_size select 0))]
    } else {
        _x
    };
};

{
    if (_x isEqualType [] && {count _x == 7} && {_forEachIndex < count _out}) then {
        private _counted = _out select _forEachIndex;

        if (count _counted == 8 && {(_counted select [0, 7]) isEqualTo _x}) then {
            _padded set [_forEachIndex, _counted];
        };
    };
} forEach +_padded;

private _drift = _valid && {_padded isNotEqualTo _out};

createHashMapFromArray [
    ["entries", _entries],
    ["blocks", _blocks],
    ["overflow", _overflow],
    ["records", _out],
    ["drift", _drift],
    ["revision", _revision]
]
