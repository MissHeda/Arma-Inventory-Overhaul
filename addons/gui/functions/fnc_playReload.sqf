#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * A magazine went into a slot of the weapon the soldier holds in his hands: that weapon's own reload sound
 * (its config entry reloadMagazineSound - any mod's weapon) and its reload gesture (reloadAction) play, so
 * the soldier reloads in the window and everyone near hears and sees it. A second magazine at once cuts
 * the first one's sound. For any other weapon - holstered, slung, without a sound of its own - nothing
 * plays here and the caller plays the generic seating click.
 *
 * Arguments:
 * 0: The unit <OBJECT>
 * 1: The slot, "primary_mag", "primary_mag2" (the grenade launcher), "handgun_mag" or "launcher_mag" <STRING>
 *
 * Return Value:
 * It played <BOOL>
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
[_unit, getText (_config >> "reloadAction")] call FUNC(gesture);

true
