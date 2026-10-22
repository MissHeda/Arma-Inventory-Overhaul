#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The containers a unit wears that something of a class may be put into, in the order to try them: the
 * uniform, vest and backpack the unit has, those with a compartment that is a slot for the item's category
 * (a magazine slot for a magazine, grid=2x2:ammo) first, the rest after them - each group in the order
 * uniform, vest, backpack. Inside a container the layout already prefers such a slot (fnc_blockOrder); this
 * puts the container that has one before a container that has only plain cells. Nothing is asked of the
 * cells here: a container with a slot may still be full, the room is fnc_hasRoom's question.
 *
 * Never a weapon, never the ground: a magazine goes into a weapon by fnc_weaponPart or the game's reload,
 * not by being put away.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Class of the item <STRING>
 *
 * Return Value:
 * Containers, the first to try first <ARRAY of OBJECTs>
 *
 * Example:
 * [player, "30Rnd_65x39_caseless_mag"] call einv_storage_fnc_unitTargets;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_class", "", [""]]];

if (isNull _unit) exitWith {[]};

private _groups = ([_class] call EFUNC(items,getInfo)) getOrDefault ["groups", ["misc"]];
private _slotted = [];
private _plain = [];

{
    private _box = _x get "container";

    // A compartment with attributes (a fifth element) that names categories and does not refuse this item.
    private _hasSlot = ([_box] call FUNC(getBlocks)) findIf {
        count _x > 4 && {(_x select 4) isNotEqualTo []} && {([_x, _groups] call FUNC(blockMode)) >= 0}
    } >= 0;

    if (_hasSlot) then {
        _slotted pushBack _box;
    } else {
        _plain pushBack _box;
    };
} forEach ([_unit] call FUNC(getSections));

_slotted + _plain
