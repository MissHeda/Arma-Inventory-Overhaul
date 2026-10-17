#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * How loud the looter hears an action: the volume of its kind (fnc_soundGroup) times the master volume, both
 * from the dropdown under the speaker in the header (fnc_openSoundMenu). 0 when the kind is off. Only the
 * looter's own ears: what the others hear of his looting is the world's setting (einv_gui_soundsWorld) and is
 * not scaled by it.
 *
 * Arguments:
 * 0: The action of fnc_playSound, or "reload", "repack", "warn" <STRING>
 *
 * Return Value:
 * The volume, 0 to 1 <NUMBER>
 *
 * Example:
 * private _scale = ["lift"] call einv_gui_fnc_soundGain;
 *
 * Public: No
 */

params [["_action", "move", [""]]];

private _index = GVAR(soundGroups) find ([_action] call FUNC(soundGroup));

if (_index < 0) exitWith {GVAR(soundMaster)};

((GVAR(soundLevels) select _index) select 0) * GVAR(soundMaster)
