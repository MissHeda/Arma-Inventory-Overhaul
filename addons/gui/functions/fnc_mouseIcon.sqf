#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The picture of a mouse button for the footer's keys (fnc_uiKeyHint) and the hint line (fnc_updateHover): ACE's own from its
 * interaction addon where ACE is loaded, so it looks as ACE's menus do - else this mod's own (icon_mouse_*_ca), so a game without
 * ACE shows a picture as well, not words.
 *
 * Arguments:
 * 0: "left", "right" or "scroll" <STRING>
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

private _ace = [MOUSE_ICON_PATH + format ["\mouse_%1_ca.paa", _button]] call FUNC(safePicture);

if (_ace isNotEqualTo "") exitWith {_ace};

switch (_button) do {
    case "right": {UI_TEX(icon_mouse_right_ca)};
    case "scroll": {UI_TEX(icon_mouse_scroll_ca)};
    default {UI_TEX(icon_mouse_left_ca)};
}
