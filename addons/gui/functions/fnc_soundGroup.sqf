#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Which kind of sound an action belongs to, for the volumes of the dropdown under the speaker in the
 * header (fnc_openSoundMenu). The kinds, by the action of fnc_playSound or by what plays beside it:
 *   moves      - an item lifted, moved, dropped, put on, taken off, attached, detached, turned, given back
 *   magazines  - a magazine loaded or unloaded, the reload's own sound ("reload"), a repack's ("repack")
 *   containers - opened, closed
 *   search     - rummaging, an item found ("search", "uncover")
 *   other      - inspecting, and the click or the warning of something refused ("inspect", "warn")
 *
 * Arguments:
 * 0: The action of fnc_playSound, or "reload", "repack", "warn" <STRING>
 *
 * Return Value:
 * The kind, one of einv_gui_soundGroups <STRING>
 *
 * Example:
 * ["loadMag"] call einv_gui_fnc_soundGroup;
 *
 * Public: No
 */

params [["_action", "move", [""]]];

switch (_action) do {
    case "search";
    case "uncover": {"search"};
    case "open";
    case "close": {"containers"};
    case "loadMag";
    case "loadMagHandgun";
    case "loadMagLauncher";
    case "loadMagUgl";
    case "unloadMag";
    case "reload";
    case "repack": {"magazines"};
    case "inspect";
    case "warn": {"other"};
    default {"moves"};
}
