#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Everything a container holds, in a form fnc_restore can put back - and where it lies in there and
 * who it is: its places (fnc_readPlaces) and, for a uniform, vest or backpack lying in another
 * container, its id (fnc_tagNested). So a moved backpack keeps its inside arrangement and its id, and
 * the record written for the cell it is dropped on matches it the moment it lands (fnc_payloadKey).
 *
 * Uniforms, vests and backpacks lying in the container are containers of their own, with contents
 * the cargo commands would lose - they are read the same way, one level deeper, and kept with the
 * object they came from so a move can pick out exactly that one.
 *
 * The variables other mods keep on a container object (GVAR(carryVariables); TFAR keeps a long-range
 * radio's frequencies on the backpack itself) go with it, since the window makes a new container on every
 * move: the snapshot holds the ones that are set.
 *
 * The id is read the way every machine reads it, through the key of its tile (fnc_entryKey), so it
 * does not matter where the authority keeps it; a container that only carries one on itself so far
 * (fnc_restore, this frame) is read off the object.
 *
 * Arguments:
 * 0: Container <OBJECT>
 * 1: Its item class, when it lies in another container - the class everyContainer names <STRING>
 *    (default: "")
 *
 * Return Value:
 * [items [[classes], [counts]], magazines [[class, ammo], ...], weapons (weaponsItemsCargo),
 *  backpacks [[classes], [counts]], nested [[class, object, snapshot], ...],
 *  [places records [[key, col, row, w, h, block, rot], ...] (rot missing in older ones), tag [id, item class, objNull] or []],
 *  carried variables [[name, value], ...]] <ARRAY>
 *
 * Example:
 * [backpackContainer player] call einv_storage_fnc_snapshot;
 *
 * Public: No
 */

params [["_container", objNull, [objNull]], ["_itemClass", "", [""]]];

if (isNull _container) exitWith {[[[], []], [], [], [[], []], [], [[], []], []]};

private _nested = (everyContainer _container) apply {
    _x params ["_class", "_object"];

    [_class, _object, [_object, _class] call FUNC(snapshot)]
};

// Its id: first as every machine reads it - the tile's key is class|c<id> -, else the one put on the
// object here (fnc_restore) and not yet taken up by a normalise.
private _ownTag = _container getVariable [QGVAR(tag), []];

if (_itemClass isEqualTo "") then {
    _itemClass = _ownTag param [1, "", [""]];
};

private _uid = "";

if (_itemClass isNotEqualTo "") then {
    private _key = [createHashMapFromArray [
        ["class", _itemClass], ["count", 1], ["ammo", 0], ["capacity", 0], ["attachments", []], ["container", _container]
    ]] call FUNC(entryKey);
    private _at = _key find "|c";

    if (_at >= 0) then {
        _uid = _key select [_at + 2];
    };
};

if (_uid isEqualTo "") then {
    _uid = _ownTag param [0, "", [""]];
};

// The parent is left out: the item lies somewhere else once it lands, and fnc_restore names that.
private _tag = [];

if (_uid isNotEqualTo "") then {
    _tag = [_uid, _itemClass, objNull];
};

// A copy: the records are kept by the places' owner, and a payload travels and is stored on its own.
private _records = +(([_container] call FUNC(readPlaces)) param [1, [], [[]]]);

private _weapons = weaponsItemsCargo _container;

if (isNil "_weapons") then {_weapons = []};

// The variables that must survive a move. One that is not set is left out: getVariable of a missing name
// is nil, which an array cannot hold.
private _vars = [];

{
    private _value = _container getVariable _x;

    if (!isNil "_value") then {
        _vars pushBack [_x, _value];
    };
} forEach GVAR(carryVariables);

[
    getItemCargo _container,
    magazinesAmmoCargo _container,
    _weapons apply {[_x] call FUNC(normalizeWeapon)},
    getBackpackCargo _container,
    _nested,
    [_records, _tag],
    _vars
]
