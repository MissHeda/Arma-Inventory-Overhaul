#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The "ace" look of the panel (the "theme" hook): the inventory's theme, changed where ACE Arsenal's own
 * panels look different, so the panel sits in ACE's window like one of its own. Flat and square, in the
 * colour and see-through of ACE's right panel with its black frame, ACE's white text, ACE's dark bars for
 * the hint line (fnc_footer), and the font and size of the text in ACE's sort bar for the panel's title
 * (fnc_layout). The tiles keep the inventory's colours, fonts and names, so an item reads the same here
 * as in the inventory.
 *
 * Only this display is asked: the inventory's own window and its kit windows keep the inventory's look.
 * The theme's id stays the inventory's - a build keeps each column's scroll only while the id is the
 * same (einv_gui_fnc_build).
 *
 * Arguments:
 * 0: Theme, changed in place <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_theme] call einv_arsenal_fnc_theme;
 *
 * Public: No
 */

params [["_theme", createHashMap, [createHashMap]]];

_theme merge [createHashMapFromArray [
    ["radius", 0],
    ["panel", ACE_PANEL_BG],
    ["panelBorder", ACE_PANEL_FRAME],
    ["text", ACE_TEXT],
    ["barBg", ACE_BAR_BG],
    ["headFont", ACE_FONT],
    ["headSize", ACE_TEXT_SIZE]
], true];
