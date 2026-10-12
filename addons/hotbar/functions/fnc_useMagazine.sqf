#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Reloads the weapon in the hands with a magazine of the slot's class - the fullest one of that class
 * the unit carries - with the game's own reload action and its animation. A round for the grenade
 * launcher goes into the launcher. A magazine that does not fit the weapon in the hands is refused: no
 * weapon is swapped behind the player's back.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Class <STRING>
 * 2: Slot index - not used <NUMBER>
 *
 * Return Value:
 * [done, text] - what is loaded, or why not <ARRAY>
 *
 * Example:
 * [player, "30Rnd_65x39_caseless_mag", 0] call einv_hotbar_fnc_useMagazine;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_class", "", [""]]];

if (!isNull objectParent _unit && {!(_unit call CBA_fnc_canUseWeapon)}) exitWith {[false, LLSTRING(Reason_NotHere)]};
if (missionNamespace getVariable ["ace_common_isReloading", false]) exitWith {[false, LLSTRING(Reason_Busy)]};
if (!([_unit] call FUNC(canAct))) exitWith {[false, LLSTRING(Reason_NotNow)]};

// The weapon in the hands: a rifle, a pistol or a launcher - not the binocular, not nothing.
private _weapon = currentWeapon _unit;
private _which = [primaryWeapon _unit, handgunWeapon _unit, secondaryWeapon _unit] find _weapon;

if (_weapon isEqualTo "" || {_which < 0}) exitWith {[false, LLSTRING(Reason_NoWeapon)]};

private _base = ["primary", "handgun", "launcher"] select _which;

// Where it goes on that weapon: the magazine, or the second muzzle's - the grenade launcher's.
private _part = [_unit, _base, _class] call EFUNC(storage,partFor);

if (_part isEqualTo "") exitWith {[false, LLSTRING(Reason_WrongWeapon)]};

private _muzzle = _weapon;

if (_part isEqualTo (_base + "_mag2")) then {
    {
        private _candidate = _x;

        if (_candidate isNotEqualTo "this" && {((compatibleMagazines [_weapon, _candidate]) findIf {_x == _class}) >= 0}) exitWith {
            _muzzle = _candidate;
        };
    } forEach getArray (configFile >> "CfgWeapons" >> _weapon >> "muzzles");
};

// The fullest one of the class that is not loaded.
private _mags = (magazinesAmmoFull _unit) select {(_x select 0) == _class && {!(_x select 2)} && {(_x select 1) > 0}};

if (_mags isEqualTo []) exitWith {[false, LLSTRING(Reason_NoneLeft)]};

private _best = _mags select 0;

{
    if ((_x select 1) > (_best select 1)) then {
        _best = _x;
    };
} forEach _mags;

// The reload action wants the magazine by its id and its creator, which the list carries behind the
// rounds (seven entries). A game that does not give them cannot be told which magazine.
if (count _best < 7) exitWith {
    WARNING_1("magazinesAmmoFull gives no magazine id: %1",_best);

    [false, LLSTRING(Reason_NotNow)]
};

_unit action ["LoadMagazine", _unit, _unit, _best select 6, _best select 5, _weapon, _muzzle];

[true, format [LLSTRING(Message_Reload), [_class] call EFUNC(gui,itemName), _best select 1]]
