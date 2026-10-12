#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * A sound file the game can play, from a path as config or the sound table writes it, kept per path: a
 * leading backslash dropped, the path itself when the file exists, else the path with ".wss", ".ogg" or
 * ".wav" added (vanilla configs write sound paths without an extension, playSoundUI and playSound3D need
 * one), else "".
 *
 * Arguments:
 * 0: Path <STRING>
 *
 * Return Value:
 * The path to play, "" when no such file exists <STRING>
 *
 * Example:
 * ["A3\Sounds_F\arsenal\weapons\Rifles\MX\Reload_MX"] call einv_gui_fnc_soundFile;
 *
 * Public: No
 */

params [["_path", "", [""]]];

private _cached = GVAR(soundFiles) get _path;

if (!isNil "_cached") exitWith {_cached};

private _clean = _path;

if ((_clean select [0, 1]) isEqualTo "\") then {
    _clean = _clean select [1];
};

private _found = "";

if (_clean isNotEqualTo "") then {
    if (fileExists _clean) then {
        _found = _clean;
    } else {
        {
            if (fileExists (_clean + _x)) exitWith {
                _found = _clean + _x;
            };
        } forEach [".wss", ".ogg", ".wav"];
    };
};

GVAR(soundFiles) set [_path, _found];

_found
