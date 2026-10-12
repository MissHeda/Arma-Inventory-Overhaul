#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Turns the layers of a chosen variant (CfgEinvSounds) into what is played: each layer's pitch picked
 * between its lowest and highest and times the action's, its volume times the action's, the file a path
 * the game can play. A file of "@crawl", "@crawl2" or "@grenade" is looked up in Surfaces for the ground
 * the player stands on (fnc_groundSurface) - the entry brings its own file, volume, offset and length, the
 * layer's volume is a factor then -, and "@getIn" or "@getOut" is the opened vehicle's own door sound
 * (soundGetIn, soundGetOut). A layer whose file cannot be found is left out.
 *
 * The result travels as it is to the players who hear the looter (fnc_sendNoise), so every listener plays
 * the same sound whatever their own config or settings.
 *
 * Arguments:
 * 0: Layers, [[file, volume, lowest pitch, highest pitch, offset, length, delay], ...] <ARRAY>
 * 1: The action's pitch <NUMBER> (default: 1)
 * 2: The action's volume <NUMBER> (default: 1)
 * 3: The container the sound is about, for a vehicle's doors <OBJECT> (default: objNull)
 *
 * Return Value:
 * Layers, [[file, volume, pitch, offset, length, delay], ...] <ARRAY>
 *
 * Example:
 * [[["a3\sounds_f\characters\stances\adjust_short1.wss", 0.48, 1.08, 1.2, 0, 0, 0]], 1, 0.85] call einv_gui_fnc_resolveLayers;
 *
 * Public: No
 */

params [["_layers", [], [[]]], ["_pitch", 1, [0]], ["_volume", 1, [0]], ["_container", objNull, [objNull]]];

private _resolved = [];

{
    _x params [
        ["_file", "", [""]], ["_layerVolume", 1, [0]], ["_low", 1, [0]], ["_high", 1, [0]],
        ["_offset", 0, [0]], ["_length", 0, [0]], ["_delay", 0, [0]]
    ];

    private _layerPitch = (_low + random ((_high - _low) max 0)) * _pitch;
    private _gain = _layerVolume * _volume;
    private _path = "";

    switch (true) do {
        // The ground under the player's feet.
        case ((_file select [0, 1]) isEqualTo "@" && {!(_file in ["@getIn", "@getOut"])}): {
            private _table = configFile >> "CfgEinvSounds" >> "Surfaces" >> (_file select [1]);
            private _entry = _table >> ([GVAR(unit)] call FUNC(groundSurface));

            if (!isArray _entry) then {
                _entry = _table >> "dirt";
            };

            if (isArray _entry) then {
                (getArray _entry) params [["_surfaceFile", "", [""]], ["_surfaceVolume", 1, [0]], ["_surfaceOffset", 0, [0]], ["_surfaceLength", 0, [0]]];

                _path = [_surfaceFile] call FUNC(soundFile);
                _gain = _gain * _surfaceVolume;
                _offset = _surfaceOffset;
                _length = _surfaceLength;
            };
        };
        // The opened vehicle's own door.
        case (_file in ["@getIn", "@getOut"]): {
            if (!isNull _container) then {
                (getArray (configOf _container >> (["soundGetIn", "soundGetOut"] select (_file isEqualTo "@getOut")))) params [["_doorFile", "", [""]], ["_doorVolume", 1, [0, ""]]];

                _path = [_doorFile] call FUNC(soundFile);

                // Config writes a volume as a number or as decibels, "db-5".
                if (_doorVolume isEqualType "") then {
                    _doorVolume = 10 ^ ((parseNumber (_doorVolume select [2])) / 20);
                };

                _gain = _gain * _doorVolume;
                _offset = 0;
            };
        };
        default {
            _path = [_file] call FUNC(soundFile);
        };
    };

    if (_path isNotEqualTo "") then {
        _resolved pushBack [_path, _gain, _layerPitch, _offset, _length, _delay];
    };
} forEach _layers;

_resolved
