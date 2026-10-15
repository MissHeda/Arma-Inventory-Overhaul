#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * A magazine went into a slot of the weapon the soldier holds in his hands: that weapon's reload action
 * (reloadAction, fnc_reloadGesture) and its own reload sound (its config entry reloadMagazineSound - any
 * mod's weapon) play, so the soldier reloads in the window and everyone near hears and sees it. The action
 * plays whether or not the weapon has a sound of its own. A second magazine at once cuts the first one's
 * sound. For any other weapon - holstered, slung, or the second muzzle of one that is not in the hands -
 * nothing plays here, and neither does a sound for a weapon without one of its own: the caller plays the
 * generic seating click.
 *
 * Arguments:
 * 0: The unit <OBJECT>
 * 1: The slot, "primary_mag", "primary_mag2" (the grenade launcher), "handgun_mag" or "launcher_mag" <STRING>
 *
 * Return Value:
 * Its own sound played <BOOL>
 *
 * Example:
 * [player, "primary_mag"] call einv_gui_fnc_playReload;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_slot", "", [""]]];

(_slot splitString "_") params [["_base", "", [""]], ["_part", "", [""]]];

private _weapon = switch (_base) do {
    case "primary": {primaryWeapon _unit};
    case "handgun": {handgunWeapon _unit};
    case "launcher": {secondaryWeapon _unit};
    default {""};
};

if (_weapon isEqualTo "" || {currentWeapon _unit isNotEqualTo _weapon}) exitWith {false};

private _config = configFile >> "CfgWeapons" >> _weapon;

// The second muzzle (a grenade launcher) reloads with its own sound and action.
if (_part isEqualTo "mag2") then {
    private _muzzle = ((getArray (_config >> "muzzles")) select {_x isNotEqualTo "this"}) param [0, ""];

    _config = if (_muzzle isNotEqualTo "") then {_config >> _muzzle} else {configNull};
};

// The reload itself, after the swap: the answer said the magazine is in.
[_unit, getText (_config >> "reloadAction")] call FUNC(reloadGesture);

private _sound = [_config] call FUNC(reloadSound);

if (_sound isEqualTo []) exitWith {false};

_sound params ["_file", "_volume", "_pitch", "_range"];

private _layer = [_file, RELOAD_GAIN * _volume, _pitch, 0, 0, 0];

// One reload at a time: a second magazine at once cuts the first one's sound.
if (GVAR(reloadSoundId) >= 0) then {
    stopSound GVAR(reloadSoundId);
};

if (missionNamespace getVariable [QGVAR(sounds), true]) then {
    GVAR(reloadSoundId) = [_layer, missionNamespace getVariable [QGVAR(soundVolume), 1]] call FUNC(playLayer);
};

[[_layer], _range min 25, NOISE_GAP, false] call FUNC(sendNoise);

true
