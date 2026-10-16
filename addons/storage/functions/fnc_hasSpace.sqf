#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether a container has a free spot for an entry in one of its compartments - for moves that do not
 * say where (Ctrl+click, the context menu): laid out once more with the entry added, from the places
 * everyone shares (fnc_readPlaces) - nothing is kept. The ground, and a grid with no object of its own (a
 * kit, "kit:" + lowercase class) that has no compartments, always have room: they grow. A kit that a rule
 * or its config gives a grid has the room of that grid (fnc_getBlocks), what it holds read through its
 * type (GVAR(holderTypes) "entries").
 *
 * A stackable entry first fills the partly filled tiles of its own key (fnc_entryKey: a magazine only
 * stacks with magazines of the same rounds) - the layout never merges into a tile; two tiles of a class
 * that are both partly filled (fnc_getContents, the places' counts) are two tiles, each with its room - and
 * only what is left over needs free spots, one per stack's worth. That is what a put without a cell does
 * (fnc_opPut), so the answer holds for Quick move, Take all and the plan.
 *
 * Arguments:
 * 0: Container, or the key of a grid with no object <OBJECT or STRING>
 * 1: Entry <HASHMAP>
 *
 * Return Value:
 * A spot is free <BOOL>
 *
 * Example:
 * [vestContainer player, _entry] call einv_storage_fnc_hasSpace;
 *
 * Public: No
 */

params [["_container", objNull, [objNull, ""]], ["_entry", createHashMap, [createHashMap]]];

// The type first: isNull fails on a key.
private _isKey = _container isEqualType "";

if (_isKey && {_container isEqualTo ""}) exitWith {false};
if (!_isKey && {isNull _container}) exitWith {false};
if (([_container] call FUNC(getBlocks)) isEqualTo []) exitWith {true};

private _class = _entry getOrDefault ["class", ""];
private _count = (_entry getOrDefault ["count", 1]) max 1;
private _stack = (([_class] call EFUNC(items,getInfo)) getOrDefault ["stack", 1]) max 1;
private _contents = if (_isKey) then {
    private _type = GVAR(holderTypes) getOrDefault [(_container splitString ":") param [0, ""], createHashMap];
    private _code = _type get "entries";
    private _listed = if (isNil "_code") then {[]} else {[_container] call _code};

    if (isNil "_listed" || {!(_listed isEqualType [])}) then {[]} else {_listed}
} else {
    [_container] call FUNC(getContents)
};
private _left = _count;

// What fits into piles of the same key that are not full yet.
if (_stack > 1) then {
    private _key = _entry getOrDefault ["key", ""];

    if (_key isEqualTo "") then {
        _key = [_entry] call FUNC(entryKey);
    };

    private _lower = toLowerANSI _class;

    {
        private _had = _x getOrDefault ["count", 1];

        if (
            _had < _stack && {toLowerANSI (_x getOrDefault ["class", ""]) isEqualTo _lower}
            && {([_x] call FUNC(entryKey)) isEqualTo _key}
        ) then {
            _left = _left - (_stack - _had);
        };
    } forEach _contents;
};

if (_left <= 0) exitWith {true};

// The rest needs a free spot for each stack's worth.
private _probes = [];

while {_left > 0} do {
    _probes pushBack createHashMapFromArray [["class", _class], ["count", _left min _stack]];
    _left = _left - _stack;
};

[_container, _contents + _probes, false] call FUNC(getLayout);

_probes findIf {_x getOrDefault ["overflow", true]} < 0
