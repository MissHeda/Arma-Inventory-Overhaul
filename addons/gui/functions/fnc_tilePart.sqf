#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * A part of the weapon lying in a container that the attachments view shows (fnc_weaponTile), as an entry like a worn slot's
 * (aio_storage_fnc_getSlot) - what is dragged out of its box (fnc_hotspotPress, fnc_startDrag): class, one of it, a magazine's
 * rounds, size, and the slot "tile_<part>" it comes from.
 *
 * Arguments:
 * 0: Slot, "tile_" and the part - "tile_optic", "tile_mag" <STRING>
 *
 * Return Value:
 * Entry, an empty HashMap when nothing is on that part <HASHMAP>
 *
 * Example:
 * ["tile_optic"] call aio_gui_fnc_tilePart;
 *
 * Public: No
 */

params [["_slot", "", [""]]];

private _target = GVAR(inspect) param [5, ""];

if !(_target isEqualType createHashMap) exitWith {createHashMap};

private _weapon = [_target] call FUNC(weaponTile);
private _index = ["", "muzzle", "rail", "optic", "mag", "mag2", "bipod"] find ((_slot splitString "_") select -1);

if (count _weapon == 0 || {_index < 1}) exitWith {createHashMap};

private _value = (_weapon getOrDefault ["attachments", []]) param [_index, ""];
private _class = if (_value isEqualType []) then {_value param [0, ""]} else {_value};

if !(_class isEqualType "" && {_class isNotEqualTo ""}) exitWith {createHashMap};

private _info = [_class] call EFUNC(items,getInfo);

(_info get "size") params ["_w", "_h"];

createHashMapFromArray [
    ["class", _class],
    ["count", 1],
    ["ammo", [0, _value param [1, 0]] select (_value isEqualType [])],
    ["capacity", _info get "capacity"],
    ["attachments", []],
    ["container", objNull],
    ["w", _w],
    ["h", _h],
    ["slot", _slot]
]
