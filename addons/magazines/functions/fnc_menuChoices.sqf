#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The context menu's "Repack all <name>" row for a magazine in the player's own gear - ACE offers the same
 * action in the vanilla inventory's menu (fnc_hideCbaOption hides that one here). Only for the player's
 * own uniform, vest and backpack, and for the player's own weapon's magazine slots, with at least two
 * partly filled magazines of the class to repack; a magazine that is full or empty gets none, and a
 * magazine loaded in a weapon is never repacked itself, only offered the row for its kind.
 *
 * Arguments:
 * 0: Magazine class <STRING>
 * 1: Where it lies: its container, or the unit for a weapon's magazine slot <OBJECT>
 * 2: A tile's rounds, -1 for a slot <NUMBER> (default: -1)
 *
 * Return Value:
 * Choices for einv_gui_fnc_openMenu, [text, arguments, code] each <ARRAY>
 *
 * Example:
 * ["30Rnd_65x39_caseless_mag", vestContainer player, 12] call einv_magazines_fnc_menuChoices;
 *
 * Public: No
 */

params [["_class", "", [""]], ["_place", objNull, [objNull]], ["_ammo", -1, [0]]];

if (!([] call FUNC(isEnabled)) || {[] call FUNC(isBusy)}) exitWith {[]};

private _unit = EGVAR(gui,unit);

// Only the player's own uniform, vest and backpack - or the player's own weapon.
if !(_place isEqualTo _unit || {_place in [uniformContainer _unit, vestContainer _unit, backpackContainer _unit]}) exitWith {[]};

private _info = [_class] call EFUNC(items,getInfo);
private _capacity = _info get "capacity";

if ((_info get "kind") isNotEqualTo "magazine" || {_capacity < 2}) exitWith {[]};
if (getNumber (configFile >> "CfgMagazines" >> _class >> "ace_disableRepacking") == 1) exitWith {[]};

// A tile: only one that is not full and not empty. A slot: whatever is loaded - it stays out of it.
if (_ammo >= 0 && {_ammo <= 0 || {_ammo >= _capacity}}) exitWith {[]};
if (count ([_class] call FUNC(ownPartials)) < 2) exitWith {[]};

[[format [LLSTRING(Menu_RepackAll), _info get "name"], [_class], {_this call FUNC(startAll)}]]
