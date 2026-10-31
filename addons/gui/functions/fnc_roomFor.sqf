#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Whether a container has room for a tile - the quick move key's question (fnc_quickMove), asked again at every
 * repeat of the key while it is held. aio_storage_fnc_hasSpace answers it exactly but lays the whole container out
 * anew each time, and a held key asks three containers per tile.
 *
 * Here the container is laid out once and the answer is kept with the container's signature (the places' revision and the
 * number of items, magazines, weapons and backpacks it holds): which cells are taken, how many are free, and how
 * many the moves waiting for it will take (fnc_queueMoves is told nothing - the queue is read when the picture is
 * made). A plain rectangular item then needs one look for a free spot of its size in those cells, upright or turned a
 * quarter, and the free cells less the waiting ones to cover it; with a reserve asked for, the cells it will take
 * are counted as waiting at once, so the next tile of a held key does not find the room the last one is going to
 * fill. The authority still decides when the move arrives (a move that finds no room there says NoRoom).
 *
 * What the cells cannot tell is asked of aio_storage_fnc_hasSpace and the answer kept for this signature and tile
 * (one question per kind of tile and per change of the container, however long the key is held): a tile that
 * stacks (it may join a pile that has room), a shaped one, and any tile for which no free spot is found (so a
 * container that looks full is never taken for full without the exact answer - only room counted out by what
 * waits is refused here). A container with no compartments of its own takes everything, as hasSpace says.
 *
 * Arguments:
 * 0: The container <OBJECT>
 * 1: The tile (its class, key and count) <HASHMAP>
 * 2: Count the room the tile takes as taken for the next ask <BOOL> (default: false)
 *
 * Return Value:
 * There is room <BOOL>
 *
 * Example:
 * [backpackContainer player, _tile, true] call aio_gui_fnc_roomFor;
 *
 * Public: No
 */

params [["_container", objNull, [objNull]], ["_tile", createHashMap, [createHashMap]], ["_reserve", false, [false]]];

if (isNull _container) exitWith {false};

// Where the container stands in the cache, with the signature it was worked out for.
private _signature = [
    ([_container] call EFUNC(storage,readPlaces)) select 0,
    count (itemCargo _container), count (magazineCargo _container), count (weaponCargo _container), count (backpackCargo _container)
];

private _at = GVAR(roomCache) findIf {(_x select 0) isEqualTo _container};
private _state = [];

if (_at >= 0) then {
    _state = GVAR(roomCache) select _at;
};

if (_state isEqualTo [] || {(_state select 1) isNotEqualTo _signature}) then {
    // Laid out anew: the cells taken, those free, what the moves waiting for this container will take, and the
    // exact answers kept so far (they hold for this signature only).
    private _layout = [_container, [_container] call EFUNC(storage,getContents)] call EFUNC(storage,getLayout);
    private _blocks = _layout getOrDefault ["blocks", []];
    private _taken = [_blocks] call EFUNC(storage,seedTaken);
    private _free = 0;

    {
        _x params ["_cols", "_rows", ["_holes", []]];

        _free = _free + _cols * _rows - count _holes;
    } forEach _blocks;

    {
        if (_x getOrDefault ["overflow", false]) then {continue};

        private _block = _x getOrDefault ["block", -1];

        if (_block < 0 || {_block >= count _taken}) then {continue};

        private _w = _x getOrDefault ["w", 1];
        private _h = _x getOrDefault ["h", 1];
        private _holes = _x getOrDefault ["holes", []];

        [_taken select _block, (_blocks select _block) select 0, _x getOrDefault ["col", 0], _x getOrDefault ["row", 0], _w, _h, _holes] call EFUNC(storage,takeCells);
        _free = _free - (_w * _h - count _holes);
    } forEach (_layout getOrDefault ["entries", []]);

    private _waiting = 0;

    {
        private _move = _x get "move";

        if ((_move getOrDefault ["to", objNull]) isEqualTo _container) then {
            private _entry = _move getOrDefault ["entry", createHashMap];

            _waiting = _waiting + (_entry getOrDefault ["w", 1]) * (_entry getOrDefault ["h", 1]);
        };
    } forEach GVAR(handQueue);

    _state = [_container, _signature, _blocks, _taken, _free, _waiting, createHashMap];

    if (_at >= 0) then {
        GVAR(roomCache) set [_at, _state];
    } else {
        // Containers that are gone leave the cache.
        GVAR(roomCache) = GVAR(roomCache) select {!isNull (_x select 0)};
        GVAR(roomCache) pushBack _state;
    };
};

_state params ["", "", "_blocks", "_taken", "_free", "_waiting", "_exact"];

// A container with no compartments takes everything (hasSpace).
if (_blocks isEqualTo []) exitWith {true};

private _class = _tile getOrDefault ["class", ""];
private _info = [_class] call EFUNC(items,getInfo);
private _upright = _info getOrDefault ["footprint", [1, 1, []]];
private _turned = _info getOrDefault ["footprintTurned", _upright];
private _stack = (_info getOrDefault ["stack", 1]) max 1;

// The exact answer, asked once per kind of tile (and count) for as long as the container is as it is.
private _fnc_exact = {
    private _key = _tile getOrDefault ["key", ""];

    if (_key isEqualTo "") then {
        _key = [_tile] call EFUNC(storage,entryKey);
    };

    private _name = str [_key, _tile getOrDefault ["count", 1]];
    private _answer = _exact getOrDefault [_name, 2];

    if (_answer isEqualTo 2) then {
        _answer = [_container, _tile] call EFUNC(storage,hasSpace);
        _exact set [_name, _answer];
    };

    _answer
};

// A tile that stacks may join a pile, a shaped one lies on cells the plain look does not know, and a compartment that
// accepts only some categories or holds one item of any size (aio_storage_fnc_blockMode) is not a matter of free cells.
if (
    _stack > 1 || {(_upright select 2) isNotEqualTo []} || {(_turned select 2) isNotEqualTo []}
    || {_blocks findIf {count _x > 4} >= 0}
) exitWith {
    call _fnc_exact
};

// A free spot of the tile's size in some compartment, upright and then turned a quarter.
private _fits = false;

{
    _x params ["_w", "_h", "_holes"];

    {
        _x params ["_cols", "_rows"];

        private _grid = _taken select _forEachIndex;

        for "_row" from 0 to (_rows - _h) do {
            for "_col" from 0 to (_cols - _w) do {
                if ([_grid, _col, _row, _w, _h, _holes] call EFUNC(storage,cellsFree)) exitWith {
                    _fits = true;
                };
            };

            if (_fits) exitWith {};
        };

        if (_fits) exitWith {};
    } forEach _blocks;

    if (_fits) exitWith {};
} forEach ([_upright, _turned] select {(_x select 0) > 0});

// Nowhere to be seen: the exact answer decides, so room is never refused on the cells' word alone.
if (!_fits) exitWith {
    call _fnc_exact
};

private _cells = (_upright select 0) * (_upright select 1);

// Room there is, but the moves waiting for the container will fill it.
if (_free - _waiting < _cells) exitWith {false};

if (_reserve) then {
    _state set [5, _waiting + _cells];
};

true
