#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The sound a weapon (or one of its muzzles) makes when a magazine goes in, from its config entry
 * reloadMagazineSound - [file, volume, pitch, range], the volume a number or decibels ("db-5") - kept per
 * config. Any mod's weapon: the file is looked up (fnc_soundFile) and a weapon without one, or whose file
 * cannot be found, has no reload sound here.
 *
 * Arguments:
 * 0: The weapon's or muzzle's config <CONFIG>
 *
 * Return Value:
 * [file, volume, pitch, range], [] for none <ARRAY>
 *
 * Example:
 * [configFile >> "CfgWeapons" >> "arifle_MX_F"] call aio_gui_fnc_reloadSound;
 *
 * Public: No
 */

params [["_config", configNull, [configNull]]];

if (isNull _config) exitWith {[]};

private _key = str _config;
private _cached = GVAR(reloadSounds) get _key;

if (!isNil "_cached") exitWith {_cached};

private _sound = [];

(getArray (_config >> "reloadMagazineSound")) params [["_path", "", [""]], ["_volume", 1, [0, ""]], ["_pitch", 1, [0]], ["_range", 15, [0]]];

private _file = [_path] call FUNC(soundFile);

if (_file isNotEqualTo "") then {
    // Config writes a volume as a number or as decibels, "db-5".
    if (_volume isEqualType "") then {
        _volume = 10 ^ ((parseNumber (_volume select [2])) / 20);
    };

    _sound = [_file, _volume, _pitch, _range];
};

GVAR(reloadSounds) set [_key, _sound];

_sound
