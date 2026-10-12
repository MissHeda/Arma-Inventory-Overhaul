#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Fills a uniform, vest or backpack that was just added from a snapshot (fnc_snapshot): clears it, puts
 * everything back - magazines with their rounds, weapons with their attachments, the uniforms, vests
 * and backpacks in it each with what they held -, gives it its id again (fnc_tagNested) when it lies in
 * another container, and writes its places (fnc_writePlaces). Runs where the container it went into is
 * local - the authority of the new object's root -, so it may write them.
 *
 * Emptied with negative counts (fnc_clearCargo) first, so nothing ever ends up twice: the engine adds a
 * uniform, vest or backpack empty or with its default contents. Should those not go, what the snapshot
 * held goes loose into the container it lies in - or, worn, on top of what stayed - rather than being
 * dropped. Every part is put in with fnc_addPayload, which says what did not arrive; what did not
 * arrive anywhere is named in the RPT.
 *
 * Its id goes on first: what lies in it finds its root through it (fnc_rootOf) when its own places are
 * written. The id is put on the object, public, and fnc_tagNested of the container it lies in takes it
 * up at once - it keeps an id a container already carries, wherever the authority keeps ids.
 *
 * The variables the snapshot carries (GVAR(carryVariables), fnc_snapshot) are set on the new container
 * object, public, whatever else went wrong: they belong to the object, not to its cargo.
 *
 * Loose: what the snapshot holds goes in on top of what the container holds - nothing cleared, no id,
 * no places (fnc_addPayload, when it cannot tell which new object is the one that arrived).
 *
 * Arguments:
 * 0: Container <OBJECT>
 * 1: Snapshot <ARRAY>
 * 2: The container it lies in, objNull when worn <OBJECT> (default: objNull)
 * 3: Loose <BOOL> (default: false)
 *
 * Return Value:
 * Everything went into the container itself <BOOL>
 *
 * Example:
 * [_backpack, _snapshot, _box] call einv_storage_fnc_restore;
 *
 * Public: No
 */

params [
    ["_container", objNull, [objNull]],
    ["_snapshot", [], [[]]],
    ["_parent", objNull, [objNull]],
    ["_loose", false, [false]]
];

if (isNull _container || {_snapshot isEqualTo []}) exitWith {false};

// A snapshot made before 0.2.0 (or by hand, the Arsenal's empty one) has no places and no id.
_snapshot params [
    ["_items", [[], []], [[]]],
    ["_magazines", [], [[]]],
    ["_weapons", [], [[]]],
    ["_backpacks", [[], []], [[]]],
    ["_nested", [], [[]]],
    ["_places", [], [[]]],
    ["_vars", [], [[]]]
];
_places params [["_records", [], [[]]], ["_tag", [], [[]]]];

private _complete = true;
private _into = _container;

if (!_loose) then {
    // Who it is, before anything goes in. The class is the one it lies in its parent as; the snapshot's
    // only when the parent does not name it.
    if (!isNull _parent && {(_tag param [0, "", [""]]) isNotEqualTo ""}) then {
        private _class = (((everyContainer _parent) select {(_x select 1) isEqualTo _container}) param [0, []]) param [0, ""];

        if (_class isEqualTo "") then {
            _class = _tag param [1, "", [""]];
        };

        _container setVariable [QGVAR(tag), [_tag select 0, _class, _parent], true];

        // Taken up at once where the authority keeps ids, so its places below and what lies in it find
        // it - not only at the next normalise.
        [_parent] call FUNC(tagNested);
    };

    _complete = [_container] call FUNC(clearCargo);

    if (!_complete) then {
        if (isNull _parent) then {
            ERROR_1("Could not empty %1 to fill it again - what it held goes in on top of what stayed.",typeOf _container);
        } else {
            ERROR_2("Could not empty %1 to fill it again - what it held goes loose into %2.",typeOf _container,typeOf _parent);
            _into = _parent;
        };
    };
};

// What other mods keep on the container object itself (a TFAR long-range radio's frequencies): on the new
// one, public, on the machine that adds it. Not for a loose restore - that container is the one it lies in.
if (!_loose) then {
    {
        _x params [["_name", "", [""]], "_value"];

        if (_name isNotEqualTo "") then {
            _container setVariable [_name, _value, true];
        };
    } forEach _vars;
};

// The uniforms, vests and backpacks in it go in one at a time, each with what it held: fnc_addPayload
// finds the one new object and fills it. So many of their class do not go in again by kind.
private _skip = createHashMap;

{
    private _key = toLowerANSI (_x select 0);
    _skip set [_key, (_skip getOrDefault [_key, 0]) + 1];
} forEach _nested;

private _fnc_bulk = {
    params ["_class", "_count"];

    private _key = toLowerANSI _class;
    private _skipped = (_skip getOrDefault [_key, 0]) min _count;

    _skip set [_key, (_skip getOrDefault [_key, 0]) - _skipped];

    _count - _skipped
};

private _payloads = [];

_items params [["_itemClasses", [], [[]]], ["_itemCounts", [], [[]]]];

{
    private _count = [_x, _itemCounts param [_forEachIndex, 0]] call _fnc_bulk;

    if (_count > 0) then {
        _payloads pushBack ["item", _x, _count, []];
    };
} forEach _itemClasses;

_backpacks params [["_backpackClasses", [], [[]]], ["_backpackCounts", [], [[]]]];

{
    private _count = [_x, _backpackCounts param [_forEachIndex, 0]] call _fnc_bulk;

    for "_i" from 1 to _count do {
        _payloads pushBack ["backpack", _x, []];
    };
} forEach _backpackClasses;

// Magazines by class, each with its own rounds.
private _rounds = createHashMap;
private _order = [];

{
    _x params ["_class", "_ammo"];

    private _key = toLowerANSI _class;

    if !(_key in _rounds) then {
        _rounds set [_key, []];
        _order pushBack _class;
    };

    (_rounds get _key) pushBack _ammo;
} forEach _magazines;

{
    _payloads pushBack ["magazine", _x, _rounds get (toLowerANSI _x)];
} forEach _order;

{
    _payloads pushBack ["weapon", _x];
} forEach _weapons;

private _backpackKeys = _backpackClasses apply {toLowerANSI _x};

{
    _x params ["_class", "", "_inner"];

    if ((toLowerANSI _class) in _backpackKeys) then {
        _payloads pushBack ["backpack", _class, _inner];
    } else {
        _payloads pushBack ["item", _class, 1, _inner];
    };
} forEach _nested;

{
    private _rest = [_into, _x] call FUNC(addPayload);

    // Into the container it lies in rather than lost.
    if (_rest isNotEqualTo [] && {!isNull _parent} && {_into isNotEqualTo _parent}) then {
        _rest = [_parent, _rest] call FUNC(addPayload);
    };

    if (_rest isNotEqualTo []) then {
        _complete = false;
        ERROR_2("Could not put %1 into %2 - it is lost.",_rest,typeOf _into);
    };
} forEach _payloads;

// Where it lay inside, written where it is now - only when it is in there.
if (!_loose && {_into isEqualTo _container} && {_records isNotEqualTo []}) then {
    [_container, +_records] call FUNC(writePlaces);
};

_complete
