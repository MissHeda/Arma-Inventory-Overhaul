#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Changes where an entry lies in its holder's places (fnc_readPlaces): moves it to another cell, takes
 * it out, or puts a new one in - on the holder's authority only.
 *
 * A record is [key, col, row, w, h, block, rot] - always written with rot, 0 upright or 1 turned a
 * quarter clockwise - and, for a tile of a class that stacks in a container, the count it holds as an
 * eighth element (a new record takes the entry's "count"; a record that moves keeps its own); a cell that
 * does not say it lies the way the entry lies when it keeps the entry's size, else as its size says (turned when not as wide as the item upright). The places keep one record
 * per entry, keyed by fnc_entryKey: the n-th of a key for the n-th entry of
 * that key. An entry is found by its key and the cell it lies on now. Taking one out of the middle
 * removes its record too - left in, the entries after it would each take the record before theirs and
 * jump. An entry that lies where the layout put it without a record of its own (first fit, or on a
 * record of its kind - fnc_getLayout) gets the picture's records first, so moving it moves exactly it.
 *
 * While a phase runs here (fnc_execute) the change goes into the execution's buffer, written once when
 * the phase ends; outside a phase - the Arsenal, Eden - it is written at once (fnc_writePlaces), which
 * refuses on any machine but the authority.
 *
 * A grid with no object of its own is given by its key ("kit:" + lowercase class, einv_compat_efak).
 *
 * Arguments:
 * 0: Holder - a container, or the key of a grid with no object <OBJECT or STRING>
 * 1: Entry, with its "class" (or "key"), "block", "col", "row", "w", "h" <HASHMAP>
 * 2: New cell [col, row, compartment] - with [.., width, height] when it lies turned there, and
 *    [.., rot] to say which way round (1 turned a quarter clockwise) - or [] to take the record out
 *    <ARRAY>
 * 3: Add a new record for an entry the holder did not have before <BOOL> (default: false)
 *
 * Return Value:
 * None
 *
 * Example:
 * [backpackContainer player, _entry, [2, 0, 0]] call einv_storage_fnc_setPlace;
 *
 * Public: No
 */

params [["_holder", objNull, [objNull, ""]], ["_entry", createHashMap, [createHashMap]], ["_cell", [], [[]]], ["_new", false, [false]]];

// The type first: isNull fails on a key.
private _isKey = _holder isEqualType "";

if ((_isKey && {_holder isEqualTo ""}) || {!_isKey && {isNull _holder}}) exitWith {};

private _key = _entry getOrDefault ["key", ""];

if (_key isEqualTo "") then {
    _key = [_entry] call FUNC(entryKey);
};

if (_key isEqualTo "") exitWith {};

private _w = _entry getOrDefault ["w", 1];
private _h = _entry getOrDefault ["h", 1];
private _rot = parseNumber (_entry getOrDefault ["rotated", false]);
private _sizeKept = true;

// Turned while it was dragged (R): it lies in the size the cell brings.
if (count _cell >= 5) then {
    _sizeKept = [_cell select 3, _cell select 4] isEqualTo [_w, _h];
    _w = _cell select 3;
    _h = _cell select 4;
};

// Which way round: as the cell says; else as the entry lies while the size is its own; else by the size -
// a square box (a shaped item in one) only turns when the cell says so.
if ((_cell param [5, -1]) in [0, 1]) then {
    _rot = _cell select 5;
} else {
    if (!_sizeKept || {!("rotated" in _entry)}) then {
        private _class = _entry getOrDefault ["class", (_key splitString "|") param [0, ""]];

        _rot = parseNumber (_w != ((([_class] call EFUNC(items,getInfo)) getOrDefault ["size", [_w, _h]]) select 0));
    };
};

// What a running phase changed so far comes first (fnc_readPlaces) - a copy, changed here.
private _records = ([_holder] call FUNC(readPlaces)) select 1;
private _changed = false;

if (_new) then {
    // A new entry is the last of its key in the cargo, so its record goes last of its key - which the
    // canonical order keeps (fnc_writePlaces).
    if (_cell isNotEqualTo []) then {
        private _record = [_key, _cell select 0, _cell select 1, _w, _h, _cell param [2, 0], _rot];

        // A tile of a class that stacks says how many it holds, a stack of its own beside any other of the
        // class (fnc_getContents, fnc_stackCounts).
        private _count = _entry getOrDefault ["count", -1];
        private _class = _entry getOrDefault ["class", (_key splitString "|") param [0, ""]];

        if (
            !_isKey && {_count isEqualType 0} && {_count >= 1} && {(_entry getOrDefault ["attachments", []]) isEqualTo []}
            && {!(_entry getOrDefault ["strict", false])}
            && {isNull (_entry getOrDefault ["container", objNull])}
            && {(([_class] call EFUNC(items,getInfo)) getOrDefault ["stack", 1]) > 1}
        ) then {
            _record pushBack (floor (_count min ([_holder, _class] call FUNC(stackFor))));
        };

        _records pushBack _record;
        _changed = true;
    };
} else {
    private _fnc_find = {
        _records findIf {
            _x isEqualType [] && {count _x >= 6}
            && {(_x select 0) isEqualTo _key}
            && {(_x select 1) isEqualTo (_entry getOrDefault ["col", -1])}
            && {(_x select 2) isEqualTo (_entry getOrDefault ["row", -1])}
            && {(_x select 5) isEqualTo (_entry getOrDefault ["block", -1])}
        }
    };

    private _index = call _fnc_find;

    // It lies where the layout put it without a record of its own: the picture's records, then again.
    if (_index < 0) then {
        private _entries = [];

        if (_isKey) then {
            private _type = GVAR(holderTypes) getOrDefault [(_holder splitString ":") param [0, ""], createHashMap];
            private _code = _type get "entries";

            if (!isNil "_code") then {
                _entries = [_holder] call _code;
            };

            if (isNil "_entries" || {!(_entries isEqualType [])}) then {_entries = []};
        } else {
            _entries = [_holder] call FUNC(getContents);
        };

        _records = ([_holder, _entries, nil, [0, _records]] call FUNC(getLayout)) get "records";
        _index = call _fnc_find;
    };

    if (_index >= 0) then {
        if (_cell isEqualTo []) then {
            _records deleteAt _index;
        } else {
            private _record = [_key, _cell select 0, _cell select 1, _w, _h, _cell param [2, 0], _rot];

            // It moves; how many it holds stays.
            private _was = _records select _index;

            if (count _was >= 8) then {
                _record pushBack (_was select 7);
            };

            _records set [_index, _record];
        };

        _changed = true;
    };
};

if (!_changed) exitWith {};

[_holder, _records] call FUNC(setRecords);
