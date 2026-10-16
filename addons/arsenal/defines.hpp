// ACE Arsenal's grid panel and the vanilla Virtual Arsenal: the inventory's screen geometry and pixel
// snapping (gui/defines.hpp), and this addon's own ids and measures. The panel is drawn by the inventory's
// engine with the inventory's measures, and takes its colours, fonts and corner radius from the inventory's
// theme.

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

// ACE's own measures (GRID_H in its defines.hpp): its grid unit - pixelGridNoUIScale / 4 screen pixels,
// 4 px at 1080p, the same at every interface size -, and the rows of its list, 7 units high (sizeEx of
// IDC 15, which leaves rowHeight at RscListNBox's 0): 28 px at 1080p.
#define ACE_GRID_H (pixelH * pixelGridNoUIScale * 0.25)
#define ACE_ROW_SIZE (7 * ACE_GRID_H)

// The panel is laid out the way the inventory's columns are (einv_gui_fnc_drawColumn), so a container reads
// here as it does there: a title row on top, the sections under it, the hint line last, a hairline under
// the title and one over the hint. PANEL_PAD, in UNITs, is the room round the block's content and between
// its bands, high as it is - and as many pixels wide (SQUARE) -, so the picture, the section captions and
// the grids all start on one left edge and the texts on the right end on one right edge. It stays on the
// window engine's UNIT with the grids and the section captions the engine draws (einv_gui_fnc_drawSection).
#define PANEL_PAD 0.4

// The panel's own texts - the title row and the hint line - are in ACE's grid, as the rows of ACE's list
// beside them are: the UNIT (a fortieth of the screen's height) and ACE's grid (a whole pixel count the
// engine picks per resolution) do not keep one ratio, so texts sized in UNITs stood a size larger or
// smaller than ACE's own on some screens. At 1080p they are what the UNITs gave there to half a pixel.

// The title row (fnc_layout): the container's picture, TITLE_H high and square (30 px at 1080p, between
// ACE's row and its sort bar with its gap), and its name beside it in the bold font, TITLE_SIZE high
// (18 px), centred in the row's height.
#define TITLE_H (7.5 * ACE_GRID_H)
#define TITLE_SIZE (4.5 * ACE_GRID_H)

// The hint line, the panel's last band (fnc_layout, fnc_footer): lines HINT_LINE_H high (22 px) of
// HINT_SIZE text (15 px, the class EINV_ArsenalHint's), HINT_PAD room above and below them (8 px) - 38 px
// for one line, the inventory footer's height. One line; a second only while the staging space holds
// something, for the note that it goes when the window closes.
#define HINT_LINE_H (5.5 * ACE_GRID_H)
#define HINT_PAD (2 * ACE_GRID_H)
#define HINT_SIZE (3.75 * ACE_GRID_H)

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

// The share of ACE's list, from its left edge, where a press may become a drag of its row
// (fnc_onListPress): the list's scroll bar runs along its right edge.
#define LIST_ROWS_SHARE 0.94

// How long a frame's turn of putting the rules' pictures on ACE's lists may take, in seconds (fnc_pictures).
#define PICTURE_BUDGET 0.003

// How far the mouse moves with the button held, in any direction and in the screen's pixels, before a
// press on ACE's list becomes a drag of its row (fnc_onFrame). Less than the engine's DRAG_THRESHOLD,
// which is in screen units - 6 px at 1080p and the normal interface size, 9 px at the largest - and let
// a quick grab end before it counted; more than a hand's tremor on a click.
#define LIST_DRAG_PX 5

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
