#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The picture of a mouse button for the footer's keys (fnc_uiKeyHint) and the hint line (fnc_updateHover): this mod's own
 * (icon_mouse_*_ca), with or without ACE - one look with the double click's, which ACE has none of (Mia, after 0.6.77; ACE's were
 * used where it was loaded before).
 *
 * Arguments:
 * 0: "left", "right", "scroll" or "double" - a double click, always this mod's own picture: ACE has none <STRING>
 *
 * Return Value:
 * The picture's path <STRING>
 *
 * Example:
 * ["left"] call aio_gui_fnc_mouseIcon;
 *
 * Public: No
 */

params [["_button", "left", [""]]];

if (_button isEqualTo "double") exitWith {UI_TEX(icon_mouse_double_ca)};

switch (_button) do {
    case "right": {UI_TEX(icon_mouse_right_ca)};
    case "scroll": {UI_TEX(icon_mouse_scroll_ca)};
    default {UI_TEX(icon_mouse_left_ca)};
}
