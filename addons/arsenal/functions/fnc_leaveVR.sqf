#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Escape in ACE's own showcase mission, Arsenal.VR: closing the window would leave the player standing in
 * an empty world, and ACE's window asks "Leave the Arsenal?" for that reason - so does this one, on a card
 * with [Exit to the menu] and [Stay]. Exit saves the soldier's loadout for the next time the mission is
 * played (as ACE does), closes the window and ends the mission. Escape again, or a click beside the
 * card, stays.
 *
 * The mission is ACE's when its description.ext names ACE's pause script; every other mission, and the
 * Eden editor, close at once.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Asked - the window is not to close now <BOOL>
 *
 * Example:
 * call einv_arsenal_fnc_leaveVR;
 *
 * Public: No
 */

disableSerialization;

private _display = uiNamespace getVariable [QEGVAR(gui,display), displayNull];

// Arsenal.VR's description.ext writes it as an array of one name (onPauseScript[] = {...}).
private _pause = getMissionConfigValue ["onPauseScript", ""];

if (_pause isEqualType []) then {
    _pause = _pause param [0, ""];
};

if (is3DEN || {isNull _display} || {!(_pause isEqualType "")} || {(toLowerANSI _pause) isNotEqualTo "ace_arsenal_fnc_onpause"}) exitWith {false};

private _choices = [
    [LLSTRING(Leave_Title), [], {}, createHashMapFromArray [["enabled", false]]],
    [LLSTRING(Leave_Exit), [], {
        // The loadout for the next visit; the mission ends a frame after the window, which ACE does the same way.
        profileNamespace setVariable [QACEGVAR(arsenal,missionLastLoadout), [player] call CBA_fnc_getLoadout];

        [2] call FUNC(close);

        [{
            (findDisplay 46) closeDisplay 0;
        }] call EFUNC(gui,later);
    }],
    [LLSTRING(Leave_Stay), [], {}]
];

// In the middle of the screen; the menu keeps itself on it.
[_display, _choices, [0.5 - SQUARE(UNIT * 3), 0.5 - UNIT * 2]] call EFUNC(gui,openMenu);

true
