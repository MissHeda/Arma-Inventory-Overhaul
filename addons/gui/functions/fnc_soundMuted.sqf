#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether the dropdown under the speaker in the header (fnc_openSoundMenu) silences a kind of sound for the
 * looter just now: its volume, or the master volume, is 0 (fnc_soundGain). Only the looter's own ears: what
 * the others hear of his looting is the world's setting (einv_gui_soundsWorld) and stays.
 *
 * The kinds are those of fnc_soundGroup. A sound played by the game itself (playSound) has no volume to
 * scale: a caller plays it through fnc_playClass, which does. With "" for the action the question is about
 * all of them: silent when the master volume is 0 or every kind is off - what the speaker shows.
 *
 * Arguments:
 * 0: The action of fnc_playSound, or "reload", "repack", "warn"; "" for everything <STRING>
 *
 * Return Value:
 * Silenced <BOOL>
 *
 * Example:
 * if (["lift"] call einv_gui_fnc_soundMuted) exitWith {};
 *
 * Public: No
 */

params [["_action", "move", [""]]];

if (_action isEqualTo "") exitWith {
    GVAR(soundMaster) <= 0 || {(GVAR(soundLevels) findIf {(_x select 0) > 0}) < 0}
};

([_action] call FUNC(soundGain)) <= 0
