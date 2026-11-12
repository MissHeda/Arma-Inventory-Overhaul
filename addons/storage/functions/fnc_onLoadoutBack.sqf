#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The weapon on the back that a loadout carries (fnc_onLoadoutGet, key "aio_secondPrimary") is put on the unit's
 * back with the Two Primary Weapons mod that is loaded (fnc_setSecondPrimary) - a loadout saved with an empty back
 * leaves it empty. Where the unit is local, a frame after the loadout so that mod sees the new gear first; otherwise
 * it goes to the unit's machine in an event (aio_storage_loadoutBack), checked here first, and is set there.
 *
 * What came over the network or from a profile is not trusted: a weapon or part this game does not know is left out,
 * a magazine's rounds are kept within its capacity. With an ACE Arsenal open, what that arsenal does not have is left
 * out as well, as ACE leaves it out of the rest of the loadout: the weapon itself - the back stays empty - or a part.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Weapon as weaponsItems gives it, or [] <ARRAY>
 * 2: Checked already and a frame later - the call this function makes itself <BOOL> (default: false)
 *
 * Return Value:
 * None
 *
 * Example:
 * [player, ["arifle_MX_F", "", "", "", ["30Rnd_65x39_caseless_mag", 30], [], ""]] call aio_storage_fnc_onLoadoutBack;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_weapon", [], [[]]], ["_ready", false, [false]]];

if (isNull _unit || {is3DEN}) exitWith {};

if (_ready) exitWith {
    [_unit, _weapon] call FUNC(setSecondPrimary);
};

// With an ACE Arsenal open: only what that arsenal has (its flat list, ACE 3.16 and later; without it nothing is
// second-guessed). By name as ACE keeps it, else in any case of letters.
private _flat = missionNamespace getVariable [QACEGVAR(arsenal,virtualItemsFlat), nil];
private _arsenal = !isNull findDisplay 1127001
    && {!isNil "_flat"} && {_flat isEqualType createHashMap} && {count _flat > 0};

private _fnc_has = {
    !_arsenal || {_this in _flat} || {(toLowerANSI _this) in _flat} || {
        private _class = _this;
        (keys _flat) findIf {_x isEqualType "" && {_x == _class}} >= 0
    }
};

private _checked = [];
private _class = _weapon param [0, "", [""]];

if (_class isNotEqualTo "" && {isClass (configFile >> "CfgWeapons" >> _class)} && {_class call _fnc_has}) then {
    _checked = [_weapon] call FUNC(normalizeWeapon);

    // The attachments: muzzle, rail, optic, bipod.
    {
        private _part = _checked select _x;

        if !(_part isEqualType "" && {_part isNotEqualTo ""} && {isClass (configFile >> "CfgWeapons" >> _part)} && {_part call _fnc_has}) then {
            _checked set [_x, ""];
        };
    } forEach [1, 2, 3, 6];

    // The magazines: [class, rounds], the rounds within the magazine's capacity.
    {
        private _magazine = _checked select _x;
        private _mag = if (_magazine isEqualType []) then {_magazine param [0, ""]} else {""};

        if (!(_mag isEqualType "") || {_mag isEqualTo ""} || {!isClass (configFile >> "CfgMagazines" >> _mag)} || {!(_mag call _fnc_has)}) then {
            _checked set [_x, []];
        } else {
            private _rounds = _magazine param [1, 0];
            private _capacity = getNumber (configFile >> "CfgMagazines" >> _mag >> "count");

            if !(_rounds isEqualType 0) then {_rounds = _capacity};

            _checked set [_x, [_mag, (floor _rounds) max 0 min _capacity]];
        };
    } forEach [4, 5];
} else {
    if (_class isNotEqualTo "") then {
        INFO_1("A loadout's weapon on the back was left out - %1 is unknown or not in the arsenal.",_class);
    };
};

// Checked here, where the arsenal is open; set where the unit is local - the event calls this again there.
if (!local _unit) exitWith {
    [QGVAR(loadoutBack), [_unit, _checked], _unit] call CBA_fnc_targetEvent;
};

[{_this call FUNC(onLoadoutBack)}, [_unit, _checked, true]] call FUNC(nextFrame);
