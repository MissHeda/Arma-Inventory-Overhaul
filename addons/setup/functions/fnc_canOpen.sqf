#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether this player may open the wizard at all - the one gate every way into it from a running mission
 * passes: the keybind and the inventory's cog (fnc_openFromGame, before the inventory closes for it), a
 * mission's own call (fnc_open) and ESC > Options, where the engine makes the display itself and only its
 * onLoad can still say no (fnc_onLoad). Saving is a question of its own (fnc_canEdit); this one is only
 * whether the window shows.
 *
 * With einv_setup_access at "everyone" anyone may, and whoever may not save sees the setup read-only.
 * At "admins" only who runs the server (single player and a hosted game included), a logged-in admin,
 * a player on CBA's settings whitelist - who may save the server's settings anyway - or a Zeus: a
 * public server's players need not see how its inventory is set up. Eden and CBA's Addon Options always
 * may: the editor is not the game, and CBA's menu has its own gate for the server's values.
 *
 * Arguments:
 * 0: Mode, "menu" or "direct" <STRING> (default: "direct")
 * 1: Tell the player why not, in a hint <BOOL> (default: false)
 *
 * Return Value:
 * May open <BOOL>
 *
 * Example:
 * ["direct", true] call einv_setup_fnc_canOpen;
 *
 * Public: Yes
 */

params [["_mode", "direct", [""]], ["_tell", false, [false]]];

if (
    is3DEN || {_mode isEqualTo "menu"} || {isServer}
    || {(missionNamespace getVariable [QGVAR(access), "admins"]) isEqualTo "everyone"}
    // #kick is there for a logged-in admin and a voted one alike: both run the server for the session.
    || {serverCommandAvailable "#kick"}
    || {!isNil "cba_settings_fnc_whitelisted" && {call cba_settings_fnc_whitelisted}}
    || {!isNull getAssignedCuratorLogic player}
) exitWith {true};

if (_tell) then {
    [LLSTRING(Access_AdminsOnly)] call ACEFUNC(common,displayTextStructured);
};

false
