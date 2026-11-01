#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Puts an attachment or magazine on one of a unit's weapons, or takes it off - each weapon slot has
 * its own pair of commands. A magazine goes on with its own rounds, into the muzzle it belongs to.
 *
 * The second primary on the back (fnc_secondPrimary) is no weapon the engine knows on the unit: its parts are
 * changed in the weapon the two-primary mod keeps, and the weapon put back on the back with them
 * (fnc_setSecondPrimary).
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Weapon slot - "primary", "handgun", "launcher" or "primary2" <STRING>
 * 2: Put on (true) or take off (false) <BOOL>
 * 3: Class <STRING>
 * 4: Rounds, for a magazine put on <NUMBER> (default: -1)
 * 5: Second muzzle, for a magazine put on <BOOL> (default: false)
 *
 * Return Value:
 * None
 *
 * Example:
 * [player, "primary", true, "optic_Aco"] call aio_storage_fnc_weaponPart;
 *
 * Public: No
 */

params ["_unit", "_base", "_on", "_class", ["_ammo", -1], ["_second", false]];

if (_class isEqualTo "") exitWith {};

private _weapon = (([_unit] call FUNC(getEquipment)) getOrDefault [_base, []]) param [0, ""];

if (_weapon isEqualTo "") exitWith {};

if (_base isEqualTo "primary2") exitWith {
    private _back = +(([_unit] call FUNC(secondPrimary)) select 1);

    if (_back isEqualTo []) exitWith {};

    private _kind = ([_class] call EFUNC(items,getInfo)) get "kind";

    if (_on) then {
        if (_kind in ["magazine", "grenade"]) then {
            if (_ammo < 0) then {
                _ammo = getNumber (configFile >> "CfgMagazines" >> _class >> "count");
            };

            _back set [[4, 5] select _second, [_class, _ammo]];
        } else {
            private _index = ["muzzle", "rail", "optic", "bipod"] find _kind;

            if (_index >= 0) then {
                _back set [[1, 2, 3, 6] select _index, _class];
            };
        };
    } else {
        // Off: the part of that class, wherever it sits.
        private _index = _back findIf {
            (_x isEqualType "" && {_x == _class}) || {_x isEqualType [] && {(_x param [0, ""]) == _class}}
        };

        if (_index > 0) then {
            _back set [_index, ["", []] select (_index in [4, 5])];
        };
    };

    [_unit, _back] call FUNC(setSecondPrimary);
};

if (!_on) exitWith {
    switch (_base) do {
        case "primary": {_unit removePrimaryWeaponItem _class};
        case "handgun": {_unit removeHandgunItem _class};
        case "launcher": {_unit removeSecondaryWeaponItem _class};
    };
};

private _kind = ([_class] call EFUNC(items,getInfo)) get "kind";

if (_kind in ["magazine", "grenade"]) exitWith {
    private _muzzles = getArray (configFile >> "CfgWeapons" >> _weapon >> "muzzles");
    // The first muzzle is "this" - the weapon's own name - on nearly every weapon; one that names it (a launcher
    // or a mod's weapon) is asked for by that name.
    private _first = _muzzles param [0, "this"];
    private _muzzle = if (_second) then {
        (_muzzles select {_x != "this" && {_x != _first}}) param [0, _weapon]
    } else {
        [_first, _weapon] select (_first in ["this", ""])
    };

    if (_ammo < 0) then {
        _ammo = getNumber (configFile >> "CfgMagazines" >> _class >> "count");
    };

    // Where the muzzle's magazine stands in weaponsItems: the first muzzle's at 4, the second's at 5.
    private _slot = [4, 5] select _second;

    // Whether the muzzle holds a magazine of the class now. Asked after every try: an empty weapon does not
    // always take the first form the command knows, and a load that did not happen must not be taken for one.
    private _fnc_loaded = {
        private _item = (weaponsItems _unit) select {(_x select 0) == _weapon};

        if (_item isEqualTo []) exitWith {false};

        private _mag = (_item select 0) param [_slot, []];

        _mag isEqualType [] && {count _mag >= 2} && {(_mag select 0) == _class}
    };

    // A chosen magazine, whatever the "Use items from ..." settings say of the container it lay in: should the
    // command raise the game's "Reloaded" event, the reload undo leaves it alone (fnc_noteHandLoad).
    [_unit, _weapon, _class] call FUNC(noteHandLoad);

    // The muzzle by its name first, as the arsenal gives it; then without it for the weapon's own muzzle;
    // then the magazine of the class as it comes and its rounds set afterwards.
    _unit addWeaponItem [_weapon, [_class, _ammo, _muzzle], true];

    if (call _fnc_loaded) exitWith {};

    if (!_second) then {
        _unit addWeaponItem [_weapon, [_class, _ammo], true];
    };

    if (call _fnc_loaded) exitWith {
        INFO_2("%1 went into %2 only without a muzzle name.",_class,_weapon);
    };

    _unit addWeaponItem [_weapon, _class, true];

    if (call _fnc_loaded) then {
        _unit setAmmo [_muzzle, _ammo];

        INFO_2("%1 went into %2 only as a plain magazine, its rounds set after.",_class,_weapon);
    } else {
        // Nothing went in, so nothing is expected.
        [objNull] call FUNC(noteHandLoad);

        WARNING_3("%1 did not go into %2 (muzzle %3) by any form of addWeaponItem.",_class,_weapon,_muzzle);
    };
};

switch (_base) do {
    case "primary": {_unit addPrimaryWeaponItem _class};
    case "handgun": {_unit addHandgunItem _class};
    case "launcher": {_unit addSecondaryWeaponItem _class};
};
