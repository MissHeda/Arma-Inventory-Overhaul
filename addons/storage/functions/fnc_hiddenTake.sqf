#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Takes out of the hidden holder what a hidden tile of a unit's container stands for (fnc_removeEntry for an
 * entry marked "strict"): the owner and kind of the container (fnc_getOwner), the holder's list of that kind,
 * the entry of that class with those rounds (an item: by class alone, fnc_hiddenAmmo), at most as many as
 * are there - and hands the payload on. The holder is written back public at once (fnc_hiddenWrite).
 *
 * Nothing can be lost or doubled here: the list is this mod's own, and what leaves it is exactly what the
 * payload says. Runs where the ops run, on the unit's owner.
 *
 * Arguments:
 * 0: Container - one of the unit's uniform, vest or backpack <OBJECT>
 * 1: Class <STRING>
 * 2: How many, -1 for all of the entry <NUMBER> (default: -1)
 * 3: Rounds of the tile, ignored for an item <NUMBER> (default: 0)
 *
 * Return Value:
 * Payload (fnc_hiddenPayload), [] when the holder has none <ARRAY>
 *
 * Example:
 * [backpackContainer player, "HandGrenade", 1, 1] call aio_storage_fnc_hiddenTake;
 *
 * Public: No
 */

params [["_container", objNull, [objNull]], ["_class", "", [""]], ["_count", -1, [0]], ["_ammo", 0, [0]]];

if (isNull _container || {_class isEqualTo ""}) exitWith {[]};

([_container] call FUNC(getOwner)) params ["_unit", "_kindName"];

if (isNull _unit || {_kindName isEqualTo ""}) exitWith {[]};

private _index = USE_KINDS find _kindName;
private _data = [_unit] call FUNC(hiddenLists);
private _list = (_data select 0) select _index;
private _wanted = [_class, _ammo] call FUNC(hiddenAmmo);
private _key = toLowerANSI _class;
private _at = _list findIf {toLowerANSI (_x select 0) isEqualTo _key && {(_x select 2) == _wanted}};

if (_at < 0) exitWith {[]};

private _entry = _list select _at;
private _have = _entry select 1;

if (_count < 1 || {_count > _have}) then {
    _count = _have;
};

if (_count >= _have) then {
    _list deleteAt _at;
} else {
    _entry set [1, _have - _count];
};

if (_list isEqualTo []) then {
    (_data select 1) set [_index, objNull];
};

[_unit, _data] call FUNC(hiddenWrite);

[_class, _count, _wanted] call FUNC(hiddenPayload)
