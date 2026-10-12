#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whose living gear a slot owner or a container on the window is, if anybody's but the player's: the
 * person, and the person's uniform, vest or backpack it lies in. A uniform, vest or backpack opened
 * from inside another container (GVAR(opened)) belongs to the one it lies in, a few deep.
 *
 * The top container is handed back for every container - also the player's own or a crate - so
 * fnc_isShared can tell a vest lying in the player's backpack from one lying in a crate.
 *
 * Arguments:
 * 0: Slot owner or container <OBJECT>
 *
 * Return Value:
 * [living person other than the player, or objNull; top container, objNull for a unit] <ARRAY>
 *
 * Example:
 * [backpackContainer cursorObject] call einv_gui_fnc_personOf;
 *
 * Public: No
 */

params [["_object", objNull, [objNull]]];

if (isNull _object) exitWith {[objNull, objNull]};

if (_object isKindOf "CAManBase") exitWith {
    [[objNull, _object] select (alive _object && {_object isNotEqualTo GVAR(unit)}), objNull]
};

// A uniform, vest or backpack opened from inside another container: up to the one it lies in.
private _root = _object;

for "_i" from 1 to 8 do {
    private _index = GVAR(opened) findIf {(_x select 1) isEqualTo _root};

    if (_index < 0) exitWith {};

    private _parent = (GVAR(opened) select _index) param [2, objNull];

    if (isNull _parent) exitWith {};

    _root = _parent;
};

// The person the window is open on is known for sure - also when only their backpack is shown, which
// fnc_getSections never marks, or when they changed into a uniform marked with its last owner here.
// Anyone else's is asked of the mark or the engine (einv_storage_fnc_getOwner).
private _person = GVAR(person);

private _owner = if (!isNull _person && {_root in [uniformContainer _person, vestContainer _person, backpackContainer _person]}) then {
    _person
} else {
    ([_root] call EFUNC(storage,getOwner)) select 0
};

[[objNull, _owner] select (alive _owner && {_owner isNotEqualTo GVAR(unit)}), _root]
