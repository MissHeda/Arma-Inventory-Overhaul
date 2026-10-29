#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Whether a key press is the player's key for turning what is being dragged, by the keybind set in Configure Addons (R by
 * default). CBA's keybinds do not run while the inventory window is open, so the window asks this itself
 * (fnc_onKeyDown).
 *
 * Arguments:
 * 0: DIK code <NUMBER>
 * 1: Modifiers held, [shift, ctrl, alt] <ARRAY> (default: none)
 *
 * Return Value:
 * It is the rotate key <BOOL>
 *
 * Example:
 * [19, [false, false, false]] call einv_gui_fnc_isRotateKey;
 *
 * Public: No
 */

params [["_key", 0, [0]], ["_modifiers", [false, false, false], [[]]]];

if (isNil "CBA_fnc_getKeybind") exitWith {false};

private _entry = [CBA_SETTINGS_EINV, QGVAR(rotate)] call CBA_fnc_getKeybind;

!isNil "_entry" && {((_entry param [8, []]) findIf {_x isEqualTo [_key, _modifiers]}) >= 0}
