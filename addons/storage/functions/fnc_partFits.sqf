#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether an attachment or a magazine fits a part of a weapon - the weapon only, not whose it is or where it lies: the check for
 * a weapon that lies in a container (op "fit", fnc_opFit; the window's attachments view and a part dropped on a weapon's tile).
 * A worn weapon's part goes through fnc_slotAccepts instead.
 *   muzzle, optic, rail, bipod - in CBA's compatible items of that kind (101, 201, 301, 302)
 *   mag  - a magazine of the weapon's own muzzle: CBA's compatible magazines of the weapon, but those of a second muzzle
 *   mag2 - a magazine of the second muzzle that loads them (a grenade launcher)
 *
 * Arguments:
 * 0: Weapon class <STRING>
 * 1: Part - "muzzle", "optic", "rail", "bipod", "mag" or "mag2" <STRING>
 * 2: Item class <STRING>
 *
 * Return Value:
 * Fits <BOOL>
 *
 * Example:
 * ["arifle_MX_F", "optic", "optic_Aco"] call aio_storage_fnc_partFits;
 *
 * Public: No
 */

params [["_weapon", "", [""]], ["_part", "", [""]], ["_class", "", [""]]];

private _config = configFile >> "CfgWeapons" >> _weapon;

if (_class isEqualTo "" || {!isClass _config}) exitWith {false};

private _item = toLowerANSI _class;
private _type = ["muzzle", "optic", "rail", "bipod"] find _part;

if (_type >= 0) exitWith {
    _item in (([_weapon, [101, 201, 301, 302] select _type] call CBA_fnc_compatibleItems) apply {toLowerANSI _x})
};

if !(_part in ["mag", "mag2"]) exitWith {false};

// The second muzzle that loads magazines.
private _second = (getArray (_config >> "muzzles")) select {
    _x != "this" && {_x != "safe"} && {isClass (_config >> _x)} && {(getArray (_config >> _x >> "magazines")) isNotEqualTo []}
};
private _secondMagazines = if (_second isEqualTo []) then {[]} else {
    ([_config >> (_second select 0)] call CBA_fnc_compatibleMagazines) apply {toLowerANSI _x}
};

if (_part isEqualTo "mag2") exitWith {_item in _secondMagazines};

private _all = ([_weapon] call CBA_fnc_compatibleMagazines) apply {toLowerANSI _x};

_item in _all && {!(_item in _secondMagazines)}
