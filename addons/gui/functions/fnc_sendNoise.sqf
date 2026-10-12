#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Lets the players near the looter hear what he does (einv_gui_soundsWorld, a server setting). The sound
 * has been resolved already - the variant picked, the pitch, the ground, the vehicle's door -, so every
 * listener plays the same one and needs neither the config nor the settings. It goes as a CBA event
 * (einv_gui_noise, fnc_onNoise) to the players within the sound's range plus NOISE_MARGIN metres, and to
 * nobody else: a lone looter costs no network at all. At most one sound every NOISE_GAP seconds goes out
 * (a search's ticks have their own clock, slower), at most three layers of it.
 *
 * Not from the Arsenal (its hook table is set) and not for a dead looter.
 *
 * Arguments:
 * 0: Layers, [[file, volume, pitch, offset, length, delay], ...] <ARRAY>
 * 1: How far it carries, in metres <NUMBER>
 * 2: The least time before the next such sound, in seconds <NUMBER>
 * 3: It is a search tick <BOOL> (default: false)
 *
 * Return Value:
 * None
 *
 * Example:
 * [_layers, 12, 0.2] call einv_gui_fnc_sendNoise;
 *
 * Public: No
 */

params [["_layers", [], [[]]], ["_range", 10, [0]], ["_gap", NOISE_GAP, [0]], ["_isSearch", false, [false]]];

// Not in the Arsenal, not when the server says nobody hears looting.
if (!(missionNamespace getVariable [QGVAR(soundsWorld), true]) || {!([] call FUNC(isInventoryMode))}) exitWith {};

private _unit = GVAR(unit);

if (isNull _unit || {!alive _unit}) exitWith {};

// One sound in a while is enough to tell someone loots - the search ticks have their own, slower clock.
private _now = diag_tickTime;
private _next = [GVAR(noiseNext), GVAR(noiseSearchNext)] select _isSearch;

if (_now < _next) exitWith {};

// Only players who can hear it get it: nobody near, no network at all.
private _targets = allPlayers select {
    _x isNotEqualTo _unit && {_x isKindOf "CAManBase"} && {alive _x} && {(_x distance _unit) < _range + NOISE_MARGIN}
};

// Testing in single player: the looter hears the copy the others would hear.
if (missionNamespace getVariable [QGVAR(noiseSelf), false]) then {
    _targets pushBack _unit;
};

if (_targets isEqualTo []) exitWith {};

if (_isSearch) then {
    GVAR(noiseSearchNext) = _now + _gap;
} else {
    GVAR(noiseNext) = _now + _gap;
};

private _inside = !isNull objectParent _unit || {([_unit] call FUNC(groundSurface)) isEqualTo "indoor"};

[QGVAR(noise), [
    _unit,
    (_layers select [0, 3]) apply {[_x select 0, (_x select 1) * NOISE_GAIN, _x select 2, _x select 3, _x select 4, _x select 5]},
    _range,
    _inside
], _targets] call CBA_fnc_targetEvent;
