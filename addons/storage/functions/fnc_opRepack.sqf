#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Op "repack": magazines of one class share their rounds out anew (aio_magazines) - each listed magazine
 * leaves its container with exactly the rounds it had and comes back with the rounds it has now, an
 * emptied one stays out (ACE leaves empties out too). Everything lies under the phase's root, so it runs
 * where those containers are local, in one go, and a ground pile that holds only these magazines is never
 * seen empty.
 *
 * Checked where it happens, because on a server the request comes from a client: one kind of magazine
 * that may be repacked, each of them partly filled before, none over full after, whole rounds, and not a
 * round more or less than there was. Every magazine has to be still where it was said to be, with those
 * rounds ("Gone" when not - somebody took one meanwhile, nothing changed). Each is taken out by its rounds
 * and read off the cargo before and after; one that would not come out puts everything back ("Failed").
 *
 * The places follow: the record of a magazine that lies alone on its tile leaves with it and comes back
 * with the key of its new rounds (class|m<rounds>) at the same cell, the size it lay in. A tile that stands
 * for several magazines keeps its record, and the new magazine of such a pile lies wherever the layout
 * finds room (fnc_getLayout).
 *
 * Arguments:
 * 0: Args, [parts] - each part [container, class, rounds before, rounds after, cell [col, row, compartment,
 *    w, h]], in the order the new magazines go back in <ARRAY>
 * 1: Context - "requester", "where", "txId", "root", "settlement" (aio_storage_fnc_execute) <HASHMAP>
 *
 * Return Value:
 * [status, produced, extra] <ARRAY>
 *   status - "" done, else why not ("Gone", "Failed", a guard's reason or a reason already in words)
 *   produced - always [], nothing leaves the containers
 *   extra - [] for nothing
 *
 * Example:
 * [[[[_crate, "30Rnd_65x39_caseless_mag", 9, 4, [0, 0, 0, 1, 1]], [_crate, "30Rnd_65x39_caseless_mag", 25, 30, [1, 0, 0, 1, 1]]]], _context] call aio_storage_fnc_opRepack;
 *
 * Public: No
 */

params [["_args", [], [[]]], ["_context", createHashMap, [createHashMap]]];

_args params [["_parts", [], [[]]]];

if (_parts isEqualTo []) exitWith {["Failed", [], []]};

private _class = (_parts select 0) param [1, "", [""]];
private _key = toLowerANSI _class;
private _config = configFile >> "CfgMagazines" >> _class;
private _capacity = getNumber (_config >> "count");

// One kind of magazine, each partly filled before, none over full after, whole rounds, and not a round more
// or less than there was.
private _valid = (_class isNotEqualTo "") && {isClass _config} && {_capacity > 1} && {getNumber (_config >> "ace_disableRepacking") != 1};
private _sumBefore = 0;
private _sumAfter = 0;

{
    _x params [["_container", objNull, [objNull]], ["_partClass", "", [""]], ["_before", -1, [0]], ["_after", -1, [0]], ["_cell", [], [[]]]];

    if (
        isNull _container || {toLowerANSI _partClass isNotEqualTo _key}
        || {_before < 1} || {_before >= _capacity} || {_after < 0} || {_after > _capacity}
        || {floor _before != _before} || {floor _after != _after}
        || {count _cell < 3}
    ) exitWith {
        _valid = false;
    };

    _sumBefore = _sumBefore + _before;
    _sumAfter = _sumAfter + _after;
} forEach _parts;

if (!_valid || {_sumBefore != _sumAfter}) exitWith {
    ERROR_1("Repack of %1 turned down - it does not add up.",_class);
    ["Failed", [], []]
};

// The rounds of this kind in a container, as the engine lists them.
private _fnc_rounds = {
    params ["_container"];

    ((magazinesAmmoCargo _container) select {toLowerANSI (_x select 0) isEqualTo _key}) apply {_x select 1}
};

// Every container involved, with its magazines of this kind as they are now. Objects are no HashMap keys, so
// a list.
private _containers = [];

{
    private _container = _x select 0;

    if (_containers findIf {(_x select 0) isEqualTo _container} < 0) then {
        _containers pushBack [_container, [_container] call _fnc_rounds];
    };
} forEach _parts;

// Every magazine still where it was said to be, with its rounds - else one was taken meanwhile.
private _there = true;

{
    _x params ["_container", "_rounds"];

    private _left = +_rounds;

    {
        if ((_x select 0) isEqualTo _container) then {
            private _index = _left find (_x select 2);

            if (_index < 0) exitWith {
                _there = false;
            };

            _left deleteAt _index;
        };
    } forEach _parts;

    if (!_there) exitWith {};
} forEach _containers;

if (!_there) exitWith {["Gone", [], []]};

// ----- Where each one lies, read before the cargo changes -----
// The tile of a part, in the view as this execution sees it: found at its cell by the key of its rounds, else
// the first of that key nobody claimed. [entry, alone] - alone when the tile stands for this one magazine.
private _tiles = [];

{
    _x params ["_container", "", "_before", "", "_cell"];

    private _view = [_container, []] call FUNC(findEntry);
    private _tileKey = format ["%1|m%2", _key, _before];
    private _entries = _view getOrDefault ["entries", []];
    private _fnc_free = {
        (_x getOrDefault ["count", 1]) > 0 && {!(_x getOrDefault ["claimed", false])} && {(_x getOrDefault ["key", ""]) isEqualTo _tileKey}
    };

    private _at = _entries findIf {
        call _fnc_free
        && {(_x getOrDefault ["block", -2]) == (_cell param [2, 0])}
        && {(_x getOrDefault ["col", -2]) == (_cell select 0)}
        && {(_x getOrDefault ["row", -2]) == (_cell select 1)}
    };

    if (_at < 0) then {
        _at = _entries findIf _fnc_free;
    };

    if (_at < 0) then {
        _tiles pushBack [createHashMap, false];
    } else {
        private _entry = _entries select _at;

        _entry set ["claimed", true];

        // A pile of several, or a magazine in the overflow row, has no record of its own to move.
        _tiles pushBack [_entry, (_entry getOrDefault ["count", 1]) == 1 && {!(_entry getOrDefault ["overflow", false])}];
    };
} forEach _parts;

{
    (_x select 0) deleteAt "claimed";
} forEach _tiles;

// The records of the magazines that lie alone leave with them.
{
    _x params ["_entry", "_alone"];

    if (_alone) then {
        [(_parts select _forEachIndex) select 0, _entry, []] call FUNC(setPlace);
    };
} forEach _tiles;

// ----- Out, one by one, each read off the cargo before and after -----
// Exactly that magazine gone: one fewer of the kind, one fewer with those rounds (fnc_removeEntry's way).
private _out = true;

{
    _x params ["_container", "", "_before"];

    private _was = [_container] call _fnc_rounds;

    _container addMagazineAmmoCargo [_class, -1, _before];

    private _now = [_container] call _fnc_rounds;

    if (count _now != count _was - 1 || {({_x == _before} count _now) != ({_x == _before} count _was) - 1}) exitWith {
        _out = false;
    };
} forEach _parts;

if (!_out) exitWith {
    // Back to how it was: whatever left a container goes back in, and the records with it.
    {
        _x params ["_container", "_rounds"];

        private _missing = +_rounds;

        {
            private _index = _missing find _x;

            if (_index >= 0) then {
                _missing deleteAt _index;
            };
        } forEach ([_container] call _fnc_rounds);

        {
            _container addMagazineAmmoCargo [_class, 1, _x];
        } forEach _missing;
    } forEach _containers;

    {
        _x params ["_entry", "_alone"];

        if (_alone) then {
            [(_parts select _forEachIndex) select 0, _entry, [
                _entry get "col", _entry get "row", _entry getOrDefault ["block", 0], _entry get "w", _entry get "h",
                parseNumber (_entry getOrDefault ["rotated", false])
            ], true] call FUNC(setPlace);
        };
    } forEach _tiles;

    ERROR_1("Repack of %1: a magazine would not come out - nothing was changed.",_class);
    ["Failed", [], []]
};

// ----- In again with their new rounds, in the order given -----
// An emptied magazine stays out. The record of one that lay alone comes back at its cell with the key of its
// new rounds - the magazine went back in last, so it is the last of its key in the cargo now (fnc_setPlace).
{
    _x params ["_container", "", "", "_after"];

    if (_after > 0) then {
        _container addMagazineAmmoCargo [_class, 1, _after];

        private _tile = _tiles select _forEachIndex;

        if (_tile select 1) then {
            private _entry = _tile select 0;
            private _cell = [
                _entry get "col", _entry get "row", _entry getOrDefault ["block", 0], _entry get "w", _entry get "h",
                parseNumber (_entry getOrDefault ["rotated", false])
            ];

            [_container, createHashMapFromArray [["key", format ["%1|m%2", _key, _after]], ["w", _entry get "w"], ["h", _entry get "h"]], _cell, true] call FUNC(setPlace);
        };
    };
} forEach _parts;

["", [], []]
