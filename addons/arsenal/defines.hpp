// The Enhanced Arsenal: the inventory's screen geometry and pixel snapping (gui/defines.hpp), and the
// arsenal's own ids and measures. It is the inventory's window on a display of its own, so it is drawn
// with the inventory's measures and takes its colours from the inventory's theme (einv_gui_fnc_theme).

#include "\z\einv\addons\gui\defines.hpp"

// The textures are the inventory's own, drawn by tools/generate_ui_textures.py into the gui addon.
#undef UI_TEX
#define UI_TEX(NAME) QPATHTOEF(gui,ui\NAME.paa)

// An icon drawn for the Arsenal, or an older one standing in for it while the new one is not in the gui
// addon yet. All of them are there since 0.2.2; the second name is what a build without them would show:
// arsenal -> icon_crate_ca, loadouts -> icon_inventory_ca, star -> icon_check_ca, unique -> icon_auto_ca,
// import and export -> icon_undo_ca and icon_redo_ca, share -> icon_swap_ca, giveback -> icon_minus_ca,
// blocked -> icon_close_ca, eye -> icon_search_ca.
#define ICON(NEW,OLD) ([UI_TEX(OLD), UI_TEX(NEW)] select (fileExists UI_TEX(NEW)))

// The Arsenal's own display, and the red screen for a Virtual Arsenal that is not allowed. 9601 to 9603
// are the inventory's (IDC_DIM, IDC_FIRST, IDC_KEEP), 9620 to 9622 the setup wizard's. None of them is one
// of ACE Arsenal's: what other mods address there finds nothing on this display.
#define IDD_ARSENAL 9610
#define IDD_ARSENAL_BLOCKED 9611

// The ACE Arsenal version the display patch (CfgAceArsenal.hpp) was checked against; a newer one is
// reported once in the RPT (fnc_compatCheck).
#define ACE_TESTED "3.21.2"

// How the camera sees the soldier (fnc_cameraStart): the zoom, the field of view of ACE's own.
#define ARSENAL_FOV 0.5

// A catalog card (fnc_drawCatalog), in cells of the grid: its size and the gap between two, stretched
// afterwards so that the cards fill the column exactly.
#define CARD_W_CELLS 2.6
#define CARD_H_CELLS 2.3
#define CARD_GAP_CELLS 0.2

// The column the catalog stands in takes the place of the loot column and grows with a wide screen
// (fnc_layout, fnc_layoutGlass): by what the middle has beyond RIGHT_KEEP UNITs, at most RIGHT_GROW of a
// column.
#define RIGHT_GROW 0.75
#define RIGHT_KEEP 18

// The glass of the Arsenal's panels is a little more see-through than the inventory's, so a soldier who
// slips behind one is still seen (fnc_theme).
#define PANEL_ALPHA 0.7

// The catalog reads the rows of its items in the background (fnc_catalogFrame): for about this many
// seconds a frame, and never more than WARM_MAX_PER_FRAME classes. A search is worked out once the typing
// has been still for SEARCH_DEBOUNCE seconds.
#define WARM_BUDGET 0.002
#define WARM_MAX_PER_FRAME 150
#define SEARCH_DEBOUNCE 0.15

// Loadouts checked against the game and the Arsenal per frame (fnc_verifyStep).
#define VERIFY_PER_FRAME 10

// A click that would destroy something waits for a second one within this many seconds (fnc_arm), and the
// arrow keys step at most once every STEP_REPEAT seconds while held (fnc_stepCount).
#define ARM_TIME 3
#define STEP_REPEAT 0.1

// ACE's display opens a frame after openBox: a request to leave the next display to ACE (GVAR(forceAce))
// counts for this many frames (fnc_handOver).
#define FORCE_ACE_FRAMES 3

// How long a Zeus's remote controlled unit is waited for to become local, in seconds (fnc_handOver).
#define ZEUS_LOCAL_WAIT 2

// What a kit of Enhanced First Aid Kits lets the Arsenal do with it (its "arsenal editing" setting, as
// einv_compat_efak_fnc_arsenalEditing answers): nothing, take things out, or take things out and pack new
// ones in.
#define EDIT_NOTHING 0
#define EDIT_REMOVE 1
#define EDIT_ALL 2

// The views the vision key goes through (fnc_cycleVision): normal, night vision, thermal.
#define VISION_MODES 3

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

// The unique ones, items a soldier may carry that the arsenal does not offer (IDX_VIRT_UNIQUE_*).
#define ACE_IDX_UNIQUE_MISC_ITEMS 19
#define ACE_IDX_UNIQUE_ITEMS_ALL 20
#define ACE_IDX_UNIQUE_GRENADES 21
#define ACE_IDX_UNIQUE_EXPLOSIVES 22
#define ACE_IDX_UNIQUE_ATTACHMENTS 23
#define ACE_IDX_UNIQUE_BACKPACKS 24
#define ACE_IDX_UNIQUE_GOGGLES 25
#define ACE_IDX_UNIQUE_UNKNOWN_ITEMS 26

// Where what the soldier carries lies in ace_arsenal_currentItems (IDX_CURR_*). The ones for the contents
// of the uniform, vest and backpack are also ARSENAL_ITEMS_* in script_component.hpp, for the window of ACE.
#define ITEM_INDEX_PRIMARY 0
#define ITEM_INDEX_LAUNCHER 1
#define ITEM_INDEX_HANDGUN 2
#define ITEM_INDEX_HEADGEAR 3
#define ITEM_INDEX_UNIFORM 4
#define ITEM_INDEX_VEST 5
#define ITEM_INDEX_BACKPACK 6
#define ITEM_INDEX_GOGGLES 7
#define ITEM_INDEX_NVG 8
#define ITEM_INDEX_BINO 9
#define ITEM_INDEX_MAP 10
#define ITEM_INDEX_COMPASS 11
#define ITEM_INDEX_RADIO 12
#define ITEM_INDEX_WATCH 13
#define ITEM_INDEX_COMMS 14
#define ITEM_INDEX_UNIFORM_ITEMS 15
#define ITEM_INDEX_VEST_ITEMS 16
#define ITEM_INDEX_BACKPACK_ITEMS 17
#define ITEM_INDEX_PRIMARY_ITEMS 18
#define ITEM_INDEX_LAUNCHER_ITEMS 19
#define ITEM_INDEX_HANDGUN_ITEMS 20
#define ITEM_INDEX_BINO_ITEMS 21

// ---------------------------------------------------------------------------
// A row of the catalog (fnc_catalogRow), by place
// ---------------------------------------------------------------------------
#define ROW_CLASS 0
#define ROW_SEARCH 1
#define ROW_NAME 2
#define ROW_SHORT 3
#define ROW_PICTURE 4
#define ROW_W 5
#define ROW_H 6
#define ROW_TILE_CATEGORY 7
#define ROW_KIND 8
#define ROW_STACK 9
#define ROW_CAPACITY 10
#define ROW_MASS 11
#define ROW_MOD 12
#define ROW_CATEGORY 13
#define ROW_KEY 14
