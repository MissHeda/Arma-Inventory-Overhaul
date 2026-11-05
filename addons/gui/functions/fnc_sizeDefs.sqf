#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The sizes the size popover under its button in the header sets (fnc_openSizeMenu), top to bottom: each a player's CBA client
 * setting (initSettings.inc.sqf), with its name and tip in the popover, the slider's two ends, its step and the setting's default.
 *   Tiles          the tile scale (aio_gui_cellScale): the cells, the item pictures and the words with them
 *   Text           the text size (aio_gui_textSize): the window's words on top of what the tiles give (fnc_textScale)
 *   Rows per page  how many rows of a tall crate or vehicle show at a time (aio_gui_pageRows); the right end, MAX_ROWS, shows all
 *
 * Arguments:
 * None
 *
 * Return Value:
 * [[setting, name, tip, least, most, step, default], ...] <ARRAY>
 *
 * Example:
 * (call aio_gui_fnc_sizeDefs) select 0;
 *
 * Public: No
 */

[
    [QGVAR(cellScale), LLSTRING(Size_Tiles), LLSTRING(Size_Tiles_Tip), CELL_SCALE_MIN, CELL_SCALE_MAX, SIZE_STEP, CELL_SCALE_DEFAULT],
    [QGVAR(textSize), LLSTRING(Size_Text), LLSTRING(Size_Text_Tip), TEXT_SIZE_MIN, TEXT_SIZE_MAX, SIZE_STEP, TEXT_SIZE_DEFAULT],
    [QGVAR(pageRows), LLSTRING(Size_PageRows), LLSTRING(Size_PageRows_Tip), PAGE_MIN_ROWS, MAX_ROWS, 1, PAGE_ROWS_DEFAULT]
]
