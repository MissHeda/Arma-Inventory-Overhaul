#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Plays one resolved layer (fnc_resolveLayers). The looter hears it on the interface, but through the
 * effects bus - the game's effects volume, ACE's earplugs and a blast's deafness apply. Someone who hears
 * the looter (fnc_onNoise) gets it where the looter's hands are, on this machine only.
 *
 * A layer with a delay plays when its time has come (fnc_delay). A piece of a longer file ends where its
 * length says - sooner when pitched up.
 *
 * Arguments:
 * 0: Layer, [file, volume, pitch, offset, length, delay] <ARRAY>
 * 1: A scale for the volume - the player's own setting <NUMBER> (default: 1)
 * 2: The looter, when someone else's sound is played at his hands <OBJECT> (default: objNull)
 * 3: How far it carries, in metres <NUMBER> (default: 0)
 * 4: The looter is indoors, and so the sound is <BOOL> (default: false)
 *
 * Return Value:
 * The sound's id, -1 when none was played now <NUMBER>
 *
 * Example:
 * [["a3\sounds_f\characters\stances\adjust_short1.wss", 0.48, 1.1, 0, 0, 0]] call einv_gui_fnc_playLayer;
 *
 * Public: No
 */

params [["_layer", [], [[]]], ["_volumeScale", 1, [0]], ["_source", objNull, [objNull]], ["_range", 0, [0]], ["_inside", false, [false]]];

_layer params [["_file", "", [""]], ["_volume", 1, [0]], ["_pitch", 1, [0]], ["_offset", 0, [0]], ["_length", 0, [0]], ["_delay", 0, [0]]];

// Later: the same layer without its delay, when its time has come (fnc_delay works in Eden too).
if (_delay > 0) exitWith {
    [{_this call FUNC(playLayer)}, [[_file, _volume, _pitch, _offset, _length, 0], _volumeScale, _source, _range, _inside], _delay] call FUNC(delay);

    -1
};

private _gain = ((_volume * _volumeScale) max 0) min 5;

if (_file isEqualTo "" || {_gain <= 0} || {_pitch <= 0}) exitWith {-1};

// The looter: on the interface, but through the effects bus. Everyone else: where the looter's hands are,
// on this machine only.
private _id = if (isNull _source) then {
    playSoundUI [_file, _gain, _pitch, true, _offset]
} else {
    playSound3D [_file, objNull, _inside, AGLToASL (_source modelToWorldVisual NOISE_POINT), _gain min 2, _pitch, _range, _offset, true]
};

// A piece of a longer file ends where its length says - sooner when pitched up.
if (_length > 0 && {!isNil "_id"} && {_id isEqualType 0} && {_id >= 0}) then {
    [{stopSound _this}, _id, _length / _pitch] call FUNC(delay);
};

if (isNil "_id" || {!(_id isEqualType 0)}) exitWith {-1};

_id
