#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Which part of one of a unit's weapons an item goes on: the magazine slot (or the second muzzle's,
 * a grenade launcher's) for a magazine the weapon takes, the attachment slot of its kind for an
 * attachment that fits it. Lets a magazine or attachment be dropped on the weapon itself.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Weapon slot - "primary", "handgun" or "launcher" <STRING>
 * 2: Item class <STRING>
 *
 * Return Value:
 * Slot id as in fnc_getSlot - e.g. "primary_mag" - or "" when it goes on no part of that weapon <STRING>
 *
 * Example:
 * [player, "primary", "30Rnd_65x39_caseless_mag"] call einv_storage_fnc_partFor;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_base", "", [""]], ["_class", "", [""]]];

if (isNull _unit || {_class isEqualTo ""}) exitWith {""};

private _kind = ([_class] call EFUNC(items,getInfo)) get "kind";

private _parts = switch (true) do {
    case (_kind in ["muzzle", "optic", "rail", "bipod"]): {[_kind]};
    case (_kind in ["magazine", "grenade"]): {["mag", "mag2"]};
    default {[]};
};

private _index = _parts findIf {[_unit, format ["%1_%2", _base, _x], _class] call FUNC(slotAccepts)};

if (_index < 0) exitWith {""};

format ["%1_%2", _base, _parts select _index]
