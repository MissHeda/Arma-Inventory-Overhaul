#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether the speaker in the header (fnc_toggleMute) silences a kind of sound for the looter just now: it
 * is muted, and the player's setting for that kind says the button covers it (the checkboxes under
 * "Mute button silences", all on by default). Only the looter's own ears: what the others hear of his
 * looting is the world's setting (einv_gui_soundsWorld) and stays.
 *
 * The kinds, by the action of fnc_playSound or by what plays beside it:
 *   moves      - an item lifted, moved, dropped, put on, taken off, attached, detached, turned, given back
 *   magazines  - a magazine loaded or unloaded, the reload's own sound ("reload"), a repack's ("repack")
 *   containers - opened, closed
 *   search     - rummaging, an item found ("search", "uncover")
 *   other      - inspecting, and the click or the warning of something refused ("inspect", "warn")
 *
 * The settings are read with their defaults: the Arsenal panel plays in Eden, where CBA's settings may not be
 * there.
 *
 * Arguments:
 * 0: The action of fnc_playSound, or "reload", "repack", "warn" <STRING>
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

if !(GVAR(muted)) exitWith {false};

switch (_action) do {
    case "search";
    case "uncover": {missionNamespace getVariable [QGVAR(muteSearch), true]};
    case "open";
    case "close": {missionNamespace getVariable [QGVAR(muteContainers), true]};
    case "loadMag";
    case "loadMagHandgun";
    case "loadMagLauncher";
    case "loadMagUgl";
    case "unloadMag";
    case "reload";
    case "repack": {missionNamespace getVariable [QGVAR(muteMagazines), true]};
    case "inspect";
    case "warn": {missionNamespace getVariable [QGVAR(muteOther), true]};
    default {missionNamespace getVariable [QGVAR(muteMoves), true]};
}
