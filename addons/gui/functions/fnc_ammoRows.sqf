#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The ballistic rows a magazine adds to the inspect card (fnc_drawInspect), from its round (CfgAmmo):
 * - muzzle velocity: the magazine's initSpeed - a weapon may change it (its own initSpeed), the card does not know the weapon;
 * - damage: the round's hit, and for an explosive one its splash (indirectHit within indirectHitRange);
 * - penetration: Arma's measure for a bullet, caliber × velocity / 1000 × 15 mm of rolled armour (RHA), at the muzzle;
 * - with ACE loaded, what its advanced ballistics compute with: bullet weight (ACE_bulletMass, g and grains), ballistic
 *   coefficient with its drag model (ACE_ballisticCoefficients, ACE_dragModel) and calibre (ACE_caliber).
 * A row is left out when the config has no value for it, so smoke, flares and chemlights show none of them.
 * (A Steam Workshop comment asked for it.)
 *
 * Arguments:
 * 0: Magazine class <STRING>
 *
 * Return Value:
 * Rows, [[label, value], ...] <ARRAY>
 *
 * Example:
 * ["30Rnd_65x39_caseless_mag"] call aio_gui_fnc_ammoRows;
 *
 * Public: No
 */

params [["_class", "", [""]]];

private _magazine = configFile >> "CfgMagazines" >> _class;

if (!isClass _magazine) exitWith {[]};

private _ammoClass = getText (_magazine >> "ammo");
private _ammo = configFile >> "CfgAmmo" >> _ammoClass;

if (_ammoClass isEqualTo "" || {!isClass _ammo}) exitWith {[]};

// A number as short as it reads: 12, 9.5, 0.151.
private _fnc_number = {
    params ["_value", ["_digits", 1]];

    private _text = _value toFixed _digits;

    if ("." in _text) then {
        while {_text select [count _text - 1] isEqualTo "0"} do {_text = _text select [0, count _text - 1]};
        if (_text select [count _text - 1] isEqualTo ".") then {_text = _text select [0, count _text - 1]};
    };

    _text
};

private _rows = [];
private _simulation = toLowerANSI getText (_ammo >> "simulation");
private _isBullet = _simulation in ["shotbullet", "shotspread"];
private _isProjectile = _isBullet || {_simulation in ["shotshell", "shotrocket", "shotmissile", "shotsubmunitions"]};

private _speed = getNumber (_magazine >> "initSpeed");

if (_speed <= 0) then {
    _speed = getNumber (_ammo >> "typicalSpeed");
};

if (_isProjectile && {_speed > 0}) then {
    _rows pushBack [LLSTRING(Inspect_Velocity), format [LLSTRING(Inspect_VelocityValue), round _speed]];
};

private _hit = getNumber (_ammo >> "hit");

if (_hit > 0) then {
    _rows pushBack [LLSTRING(Inspect_Damage), [_hit] call _fnc_number];
};

private _indirectHit = getNumber (_ammo >> "indirectHit");
private _indirectRange = getNumber (_ammo >> "indirectHitRange");

if (_indirectHit > 0 && {_indirectRange > 0}) then {
    _rows pushBack [LLSTRING(Inspect_Splash), format [LLSTRING(Inspect_SplashValue), [_indirectHit] call _fnc_number, [_indirectRange] call _fnc_number]];
};

private _caliber = getNumber (_ammo >> "caliber");

if (_isBullet && {_caliber > 0} && {_speed > 0}) then {
    _rows pushBack [LLSTRING(Inspect_Penetration), format [LLSTRING(Inspect_PenetrationValue), [_caliber * _speed / 1000 * 15] call _fnc_number]];
};

// ACE's advanced ballistics: the values are there when ACE is loaded, whether the setting is on or not.
private _bulletMass = getNumber (_ammo >> "ACE_bulletMass");

if (_bulletMass > 0) then {
    _rows pushBack [LLSTRING(Inspect_BulletMass), format [LLSTRING(Inspect_BulletMassValue), [_bulletMass] call _fnc_number, round (_bulletMass * 15.4324)]];
};

private _coefficients = getArray (_ammo >> "ACE_ballisticCoefficients");
private _coefficient = _coefficients param [0, 0];

if (_coefficient isEqualType 0 && {_coefficient > 0}) then {
    private _dragModel = getNumber (_ammo >> "ACE_dragModel");
    private _text = [_coefficient, 3] call _fnc_number;

    if (_dragModel > 0) then {
        _text = format ["%1 G%2", _text, round _dragModel];
    };

    // Several coefficients, one per velocity band (ACE_velocityBoundaries): the first, with a mark that more follow.
    if (count _coefficients > 1) then {
        _text = _text + " …";
    };

    _rows pushBack [LLSTRING(Inspect_BallisticCoefficient), _text];
};

private _aceCaliber = getNumber (_ammo >> "ACE_caliber");

if (_aceCaliber > 0) then {
    _rows pushBack [LLSTRING(Inspect_Caliber), format [LLSTRING(Inspect_CaliberValue), [_aceCaliber, 2] call _fnc_number]];
};

_rows
