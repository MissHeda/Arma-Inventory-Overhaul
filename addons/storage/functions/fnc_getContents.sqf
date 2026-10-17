#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What a container holds, one entry per tile: a uniform's, vest's or backpack's container object, a
 * crate, a vehicle or a pile on the ground.
 *
 * Weapons and backpacks are each a tile of their own - every one may carry different attachments or
 * contents. So is every magazine, as each has its own rounds; only the ones that stack (grenades and
 * the like, einv_items_fnc_getInfo's "stack") share a tile, and only with the same rounds. Items are
 * counted together by class and split into tiles at their stack size - along the places' records of the
 * key when they carry counts: the n-th record of a key is the n-th tile of that key and holds as many as
 * its count says, so a stack of five and a stack of one of a class that stacks to ten are two tiles
 * (fnc_stackCounts reconciles them with what the cargo really holds, so nothing is lost or doubled when
 * the engine or a script changed the cargo meanwhile). Without counts - an older save - the pile is cut
 * into full stacks and a remainder, as it always was.
 *
 * Every entry gets the key of its record (fnc_entryKey). Every uniform, vest and backpack lying in the
 * container gets two marks on this machine: its item class (einv_storage_itemClass) - its container
 * object is only a Supply class, and its compartments go by the item (fnc_getBlocks) - and the
 * container it lies in (einv_storage_parent), so its root and the copy of its tag and places are found
 * from it (fnc_rootOf, fnc_readPlaces). Every machine that shows a nested container has read the one it
 * lies in first.
 *
 * A unit's uniform, vest or backpack under a Strict setting (fnc_opStrict) has a second source: the unit's
 * hidden holder (einv_storage_hidden, fnc_hiddenLists) keeps what the setting keeps out of the cargo. Its
 * things come after the cargo's, as tiles like any other, marked "strict" - so the window, the layout, the
 * room checks, the weight and the Arsenal panel see one container, and every machine the same one (the
 * holder is public). Taking such a tile out takes it out of the holder (fnc_removeEntry).
 *
 * Arguments:
 * 0: Container <OBJECT>
 *
 * Return Value:
 * Entries, weapons first, then backpacks, magazines and items <ARRAY of HASHMAPs>
 *   "class"       - class name <STRING>
 *   "count"       - how many share the tile, at least 1 <NUMBER>
 *   "ammo"        - rounds in a magazine, 0 for anything else <NUMBER>
 *   "capacity"    - rounds a full magazine holds, 0 for anything else <NUMBER>
 *   "attachments" - a weapon's weaponsItemsCargo entry, [] for anything else <ARRAY>
 *   "container"   - a uniform, vest or backpack's own container object, objNull for anything else <OBJECT>
 *   "key"         - the key of its record (fnc_entryKey) <STRING>
 *   "strict"      - it lies in the unit's hidden holder, not in the cargo (Strict mode) <BOOL>
 *
 * Example:
 * [backpackContainer player] call einv_storage_fnc_getContents;
 *
 * Public: No
 */

params [["_container", objNull, [objNull]]];

if (isNull _container) exitWith {[]};

// Uniforms, vests and backpacks lying in here hold things of their own. The engine names their
// container objects by class but does not say which item is which, so the n-th of a class gets the
// n-th container of that class - which one is which does not matter: each is keyed by its own id.
private _inside = createHashMap;

{
    _x params ["_class", "_object"];

    // Marks for whoever lays it out or asks for its root on this machine (fnc_getBlocks, fnc_rootOf).
    _object setVariable [QGVAR(itemClass), _class];
    _object setVariable [QGVAR(parent), _container];

    private _key = toLowerANSI _class;
    private _objects = _inside get _key;

    if (isNil "_objects") then {
        _objects = [];
        _inside set [_key, _objects];
    };

    _objects pushBack _object;
} forEach (everyContainer _container);

// Copies of the nested ones' tags, for those whose tag on the object does not reach this machine
// (fnc_tagNested) - read once for all of them.
private _nested = [];

if (isMultiplayer && {count _inside > 0}) then {
    private _top = [_container, objNull, "top"] call FUNC(rootOf);

    _nested = _top getVariable [QGVAR(nested), []];
};

private _entries = [];

// Set while the hidden holder's things are added (Strict mode), below.
private _hiddenMark = false;

private _fnc_add = {
    params ["_class", "_count", "_ammo", "_attachments"];

    private _object = objNull;
    private _objects = _inside get (toLowerANSI _class);

    if (!isNil "_objects" && {_objects isNotEqualTo []}) then {
        _object = _objects deleteAt 0;
    };

    private _entry = createHashMapFromArray [
        ["class", _class],
        ["count", _count],
        ["ammo", _ammo],
        ["capacity", ([_class] call EFUNC(items,getInfo)) get "capacity"],
        ["attachments", _attachments],
        ["container", _object],
        ["strict", _hiddenMark]
    ];

    _entry set ["key", [_entry, _nested] call FUNC(entryKey)];
    _entries pushBack _entry;
};

// The counts the places' records carry, key -> the count of each record of that key in order (-1 for
// one without a count). Read when the first stackable pile asks.
private _recordCounts = createHashMap;
private _recordsRead = false;

// Splits a pile of one kind into tiles of at most its stack size - along the records of its key, when
// the places have any (fnc_stackCounts). The hidden holder's piles are cut plainly: they have no records
// of their own to follow.
private _fnc_addStacked = {
    params ["_class", "_count", "_ammo"];

    private _info = [_class] call EFUNC(items,getInfo);
    private _stack = (_info get "stack") max 1;
    private _counts = [];

    // Only a pile of a class that stacks can lie in several tiles, and only one with no container object
    // of its own (a uniform or vest keeps one tile each).
    if (_stack > 1 && {!_hiddenMark} && {_count > 0} && {(_inside getOrDefault [toLowerANSI _class, []]) isEqualTo []}) then {
        if (!_recordsRead) then {
            _recordsRead = true;

            {
                if (_x isEqualType [] && {(_x select [0, 6]) isEqualTypeArray ["", 0, 0, 0, 0, 0]}) then {
                    private _recordKey = _x select 0;
                    private _list = _recordCounts get _recordKey;

                    if (isNil "_list") then {
                        _list = [];
                        _recordCounts set [_recordKey, _list];
                    };

                    _list pushBack (_x param [7, -1]);
                };
            } forEach (([_container] call FUNC(readPlaces)) select 1);
        };

        if (count _recordCounts > 0) then {
            private _probe = createHashMapFromArray [
                ["class", _class], ["ammo", _ammo], ["capacity", _info get "capacity"], ["attachments", []], ["container", objNull]
            ];
            private _given = _recordCounts get ([_probe, _nested] call FUNC(entryKey));

            if (!isNil "_given") then {
                _counts = [_count, _stack, _given] call FUNC(stackCounts);
            };
        };
    };

    if (_counts isEqualTo []) then {
        while {_count > 0} do {
            _counts pushBack (_count min _stack);
            _count = _count - _stack;
        };
    };

    {
        [_class, _x, _ammo, []] call _fnc_add;
    } forEach _counts;
};

private _weapons = weaponsItemsCargo _container;

if (isNil "_weapons") then {_weapons = []};

{
    [_x select 0, 1, 0, [_x] call FUNC(normalizeWeapon)] call _fnc_add;
} forEach _weapons;

(getBackpackCargo _container) params [["_backpacks", [], [[]]], ["_backpackCounts", [], [[]]]];

{
    for "_i" from 1 to (_backpackCounts select _forEachIndex) do {
        [_x, 1, 0, []] call _fnc_add;
    };
} forEach _backpacks;

// Magazines keep the engine's order. A stacking one joins the pile of its class and rounds that came
// first; [class, rounds, count] per pile.
private _magazines = [];
private _piles = createHashMap;

{
    _x params ["_class", "_ammo"];

    if ((([_class] call EFUNC(items,getInfo)) get "stack") > 1) then {
        private _key = format ["%1|%2", toLowerANSI _class, _ammo];
        private _index = _piles get _key;

        if (isNil "_index") then {
            _piles set [_key, count _magazines];
            _magazines pushBack [_class, _ammo, 1];
        } else {
            private _pile = _magazines select _index;
            _pile set [2, (_pile select 2) + 1];
        };
    } else {
        _magazines pushBack [_class, _ammo, 1];
    };
} forEach (magazinesAmmoCargo _container);

{
    _x params ["_class", "_ammo", "_count"];
    [_class, _count, _ammo] call _fnc_addStacked;
} forEach _magazines;

// The engine usually lists every item class once, but nothing promises it - add them up by class.
(getItemCargo _container) params [["_items", [], [[]]], ["_itemCounts", [], [[]]]];

private _itemOrder = [];
private _itemTotals = createHashMap;

{
    private _key = toLowerANSI _x;
    private _total = _itemTotals get _key;

    if (isNil "_total") then {
        _itemOrder pushBack _x;
        _total = 0;
    };

    _itemTotals set [_key, _total + (_itemCounts select _forEachIndex)];
} forEach _items;

{
    [_x, _itemTotals get (toLowerANSI _x), 0] call _fnc_addStacked;
} forEach _itemOrder;

// ---------------------------------------------------------------------------
// The hidden holder (Strict mode): what a setting keeps out of one of a unit's three containers lies on the
// unit (fnc_hiddenLists), and shows as the container's own tiles - after the cargo's, marked "strict".
// Magazines by their rounds, grenades and items stacked like the cargo's.
// ---------------------------------------------------------------------------
([_container] call FUNC(getOwner)) params ["_owner", "_kindName"];

if (!isNull _owner && {_kindName isNotEqualTo ""} && {!isNil {_owner getVariable QGVAR(hidden)}}) then {
    _hiddenMark = true;

    {
        _x params ["_class", "_count", "_ammo"];

        [_class, _count, _ammo max 0] call _fnc_addStacked;
    } forEach ((([_owner] call FUNC(hiddenLists)) select 0) select (USE_KINDS find _kindName));

    _hiddenMark = false;
};

_entries
