#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The tile an op names, in the holder's view as this execution sees it (GVAR(cache), filled at the
 * holder's first use in the execution): the tile with that key at [block, col, row]; not exact - take
 * and move, not place - failing that the first tile with that key anywhere: an identical item is the
 * same item. A tile taken earlier in the phase has a count of 0 in the view and is never found.
 *
 * Given no entry, it hands back the view itself - the layout of fnc_getLayout ("entries", "blocks",
 * "overflow", ...) plus "open" for a grid without compartments (the ground, a kit) - which the ops keep
 * up to date as they change the holder: a take lowers its tile's count, a put adds the tile it placed.
 * Outside a phase nothing is kept: every call lays the holder out anew.
 *
 * Arguments:
 * 0: Holder <OBJECT or STRING>
 * 1: Entry, as an array (fnc_entryToArray) - [] for the view <ARRAY>
 * 2: Exact - only at its own cell <BOOL> (default: false)
 *
 * Return Value:
 * Entry - or the view -, an empty HashMap when it is not there <HASHMAP>
 *
 * Example:
 * [cursorObject, _entryArray, true] call einv_storage_fnc_findEntry;
 *
 * Public: No
 */

params [["_holder", objNull, [objNull, ""]], ["_entryArray", [], [[]]], ["_exact", false, [false]]];

private _isKey = _holder isEqualType "";

if (_isKey) then {
    if (_holder isEqualTo "") then {_holder = objNull};
} else {
    if (isNull _holder) then {_holder = objNull};
};

if (_holder isEqualTo objNull) exitWith {createHashMap};

// Objects are no HashMap keys. Should two holders ever share a netId (single player before Arma 2.18),
// the holder kept with the view tells them apart - the view is then simply laid out again.
private _id = if (_isKey) then {_holder} else {netId _holder};
private _cached = if (GVAR(executing)) then {GVAR(cache) getOrDefault [_id, createHashMap]} else {createHashMap};
private _view = createHashMap;

if ((_cached getOrDefault ["holder", objNull]) isEqualTo _holder) then {
    _view = _cached get "view";
} else {
    private _entries = if (_isKey) then {
        private _type = GVAR(holderTypes) getOrDefault [(_holder splitString ":") param [0, ""], createHashMap];

        [_holder] call (_type getOrDefault ["entries", {[]}])
    } else {
        [_holder] call FUNC(getContents)
    };

    if (isNil "_entries" || {!(_entries isEqualType [])}) then {
        _entries = [];
    };

    // The places as this phase changed them so far (fnc_readPlaces reads the execution's buffer first).
    _view = [_holder, _entries, false] call FUNC(getLayout);
    _view set ["open", _isKey || {([_holder] call FUNC(getBlocks)) isEqualTo []}];

    if (GVAR(executing)) then {
        GVAR(cache) set [_id, createHashMapFromArray [["holder", _holder], ["view", _view]]];
    };
};

if (_entryArray isEqualTo []) exitWith {_view};

_entryArray params [
    ["_class", "", [""]], "", "", "", "", "",
    ["_col", -1, [0]], ["_row", -1, [0]], "", "",
    ["_block", -1, [0]], ["_key", "", [""]]
];

if (_key isEqualTo "") then {
    _key = [[_entryArray] call FUNC(entryFromArray)] call FUNC(entryKey);
};

private _entries = _view getOrDefault ["entries", []];
private _fnc_same = {(_x getOrDefault ["count", 1]) > 0 && {(_x getOrDefault ["key", ""]) isEqualTo _key}};

private _index = _entries findIf {
    call _fnc_same
    && {(_x getOrDefault ["block", -2]) == _block}
    && {(_x getOrDefault ["col", -2]) == _col}
    && {(_x getOrDefault ["row", -2]) == _row}
};

if (_index < 0 && {!_exact}) then {
    _index = _entries findIf _fnc_same;
};

if (_index < 0) exitWith {createHashMap};

_entries select _index
