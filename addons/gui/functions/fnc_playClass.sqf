#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Plays a sound of the game's CfgSounds (the mission's own too) for the looter at the volume the dropdown under
 * the speaker in the header sets for its kind (fnc_soundGain). The game's playSound has no volume to give: the
 * sound's file, volume and pitch are read from the class and played as a layer (fnc_playLayer) at the scaled
 * volume. A class whose file cannot be found is played as it is, with playSound, unless its kind is silenced.
 * Used for the clicks and warnings of something refused and for a repack's finished sound, which are not item
 * sounds (fnc_playSound).
 *
 * Arguments:
 * 0: A class of CfgSounds <STRING>
 * 1: The kind it belongs to, as the action of fnc_soundGroup: "warn", "repack" <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["ACE_Sound_Click", "warn"] call aio_gui_fnc_playClass;
 *
 * Public: Yes
 */

params [["_class", "", [""]], ["_action", "warn", [""]]];

private _gain = [_action] call FUNC(soundGain);

if (_class isEqualTo "" || {_gain <= 0}) exitWith {};

private _config = configFile >> "CfgSounds" >> _class;

if (!isClass _config) then {
    _config = missionConfigFile >> "CfgSounds" >> _class;
};

private _played = false;

if (isClass _config) then {
    (getArray (_config >> "sound")) params [["_path", "", [""]], ["_volume", 1, [0, ""]], ["_pitch", 1, [0]]];

    private _file = [_path] call FUNC(soundFile);

    if (_file isNotEqualTo "") then {
        // Config writes a volume as a number or as decibels, "db-5".
        if (_volume isEqualType "") then {
            _volume = 10 ^ ((parseNumber (_volume select [2])) / 20);
        };

        [[_file, _volume, _pitch max 0.1, 0, 0, 0], _gain] call FUNC(playLayer);
        _played = true;
    };
};

if (!_played) then {
    playSound _class;
};
