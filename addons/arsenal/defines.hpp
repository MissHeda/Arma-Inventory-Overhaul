// ACE Arsenal's grid panel and the vanilla Virtual Arsenal: the inventory's screen geometry and pixel
// snapping (gui/defines.hpp), and this addon's own ids and measures. The panel is drawn by the inventory's
// engine with the inventory's measures, and takes its colours from the inventory's theme.

#include "\z\einv\addons\gui\defines.hpp"

// The textures are the inventory's own, drawn by tools/generate_ui_textures.py into the gui addon.
#undef UI_TEX
#define UI_TEX(NAME) QPATHTOEF(gui,ui\NAME.paa)

// The red screen for a Virtual Arsenal that is not allowed. 9601 to 9603 are the inventory's (IDC_DIM,
// IDC_FIRST, IDC_KEEP), 9620 to 9622 the setup wizard's.
#define IDD_ARSENAL_BLOCKED 9611

// The ACE Arsenal version whose ids and internals the panel was checked against; another one is reported
// once in the RPT (fnc_compatCheck).
#define ACE_TESTED "3.21.2"

// The panel beside ACE's list (fnc_panelRect): the gap to the list, in UNITs, and the most of the screen's
// width it may take - the soldier stands in the middle.
#define PANEL_GAP 0.3
#define PANEL_MAX_SHARE (1 / 3)

// The panel's title band when ACE shows no sort bar above its list to line it up with, in UNITs.
#define HEAD_LINE_H 1.1

// The title band against ACE's sort bar beside it: taller, so the container's picture and name read at a
// glance - the column under it starts lower by the difference.
#define HEAD_BAND_SCALE 1.6

// ACE's look (ui/RscAttributes.hpp), which the panel takes on (fnc_theme, fnc_layout, fnc_footer): the
// background of the right panel's block (blockRightBackground) and its frame (blockRightFrame, an RscFrame
// in black), the sort bar over the list - a vanilla RscCombo, opaque black, 6 of ACE's grid units high
// (GRID_H, which ignores the interface size) with RobotoCondensed at 5 -, and the text of ACE's message
// line (IDC 9), also 5 units. The list's rows are 7 units (sizeEx of IDC 15).
#define ACE_PANEL_BG [0, 0, 0, 0.5]
#define ACE_PANEL_FRAME [0, 0, 0, 1]
#define ACE_SORT_BG [0, 0, 0, 1]
#define ACE_TEXT [1, 1, 1, 1]
#define ACE_FONT "RobotoCondensed"
#define ACE_GRID_H (pixelH * pixelGridNoUIScale * 0.25)
#define ACE_TEXT_SIZE (5 * ACE_GRID_H)
#define ACE_LINE_H (6 * ACE_GRID_H)
#define ACE_ROW_SIZE (7 * ACE_GRID_H)

// The hint line, the panel's last band (fnc_layout, fnc_footer): lines as high as ACE's sort bar with
// ACE's message text, this much room above and below them, in ACE's grid units. One line; a second only
// while the staging space holds something, for the note that it goes when the window closes.
#define HINT_PAD 1

// The staging space under the container's grid (fnc_staging): a crate of the game's own, made on this
// machine only and hidden at the soldier's feet, with a grid of its own. A crate rather than a ground
// holder: the ground has no grid and no limit (einv_storage_fnc_getBlocks). Its grid is STORAGE_COLS wide
// and grows with what lies in it (fnc_growStaging): always STAGING_FREE_ROWS free rows under the lowest
// one in use, never fewer than STAGING_MIN_ROWS rows nor than fill the panel down to its hint line, never
// more than STAGING_MAX_ROWS - a cap of its own, as MAX_ROWS also bounds every item's and compartment's
// size in the rules.
#define STAGING_CLASS "Box_NATO_Support_F"
#define STAGING_MIN_ROWS 10
#define STAGING_FREE_ROWS 4
#define STAGING_MAX_ROWS 100

// The share of ACE's list, from its left edge, where a press may become a drag of its row (fnc_onMouse):
// the list's scroll bar runs along its right edge.
#define LIST_ROWS_SHARE 0.94

// How long a move into or out of the staging space is waited for before ACE's list is no longer told,
// in seconds (fnc_onFrame).
#define WATCH_TIME 3

// The Ctrl keys, for Ctrl and the wheel over a tile (fnc_onKey, fnc_onWheel).
#define DIK_LCONTROL 29
#define DIK_RCONTROL 157


// ---------------------------------------------------------------------------
// ACE's own numbers, copied under names of ours (z\ace\addons\arsenal\defines.hpp, ACE 3.21.2)
// ---------------------------------------------------------------------------

// Where the categories lie in ace_arsenal_virtualItems (IDX_VIRT_*): the weapons and the attachments are
// lists of lists, one deeper.
#define ACE_IDX_WEAPONS 0
#define ACE_IDX_PRIMARY 0
#define ACE_IDX_LAUNCHER 1
#define ACE_IDX_HANDGUN 2
#define ACE_IDX_ATTACHMENTS 1
#define ACE_IDX_OPTIC 0
#define ACE_IDX_RAIL 1
#define ACE_IDX_MUZZLE 2
#define ACE_IDX_BIPOD 3
#define ACE_IDX_ITEMS_ALL 2
#define ACE_IDX_HEADGEAR 3
#define ACE_IDX_UNIFORM 4
#define ACE_IDX_VEST 5
#define ACE_IDX_BACKPACK 6
#define ACE_IDX_GOGGLES 7
#define ACE_IDX_NVG 8
#define ACE_IDX_BINO 9
#define ACE_IDX_MAP 10
#define ACE_IDX_COMPASS 11
#define ACE_IDX_RADIO 12
#define ACE_IDX_WATCH 13
#define ACE_IDX_COMMS 14
#define ACE_IDX_GRENADES 15
#define ACE_IDX_EXPLOSIVES 16
#define ACE_IDX_MISC_ITEMS 17
#define ACE_IDX_MISC_GOGGLES 18
