#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Whether a key press is the player's key for dropping, by the keybind set in Configure Addons (G by default;
 * einv_gui_drop). CBA's keybinds do not run while the inventory window is open, so the window asks this itself
 * (fnc_onKeyDown), and so do the hotbar's strip (einv_hotbar_fnc_onWindowKey) and the Arsenal's panel
 * (einv_arsenal_fnc_onKey). No other key drops: Delete does nothing unless the player binds it.
 *
 * Arguments:
 * 0: DIK code <NUMBER>
 * 1: Modifiers held, [shift, ctrl, alt] <ARRAY> (default: none)
 *
 * Return Value:
 * It is the drop key <BOOL>
 *
 * Example:
 * [34, [false, false, false]] call einv_gui_fnc_isDropKey;
 *
 * Public: No
 */

params [["_key", 0, [0]], ["_modifiers", [false, false, false], [[]]]];

if (isNil "CBA_fnc_getKeybind") exitWith {false};

private _entry = [CBA_SETTINGS_EINV, QGVAR(drop)] call CBA_fnc_getKeybind;

!isNil "_entry" && {((_entry param [8, []]) findIf {_x isEqualTo [_key, _modifiers]}) >= 0}
