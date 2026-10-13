// The setup wizard's window: the inventory's screen geometry and pixel snapping (gui/defines.hpp), and
// the wizard's own ids and measures. It looks like the inventory - Enhanced First Aid Kits' glass - and
// takes its colours from the inventory's theme (einv_gui_fnc_theme).

#include "\z\einv\addons\gui\defines.hpp"

// The textures are the inventory's own, drawn by tools/generate_ui_textures.py into the gui addon.
#undef UI_TEX
#define UI_TEX(NAME) QPATHTOEF(gui,ui\NAME.paa)

// An icon drawn for the wizard, or an older one standing in for it while the new one is not in the gui
// addon yet.
#define ICON(NEW,OLD) ([UI_TEX(OLD), UI_TEX(NEW)] select (fileExists UI_TEX(NEW)))

#define IDD_WIZARD 9620
#define IDC_WIZARD_DIM 9621
#define IDC_WIZARD_FIRST 9622

// DIK codes the wizard looks at, besides those of gui/defines.hpp.
#define DIK_Y 21
#define DIK_Z 44
#define DIK_SPACE 57
#define DIK_F 33

// CT_EDIT and CT_CONTROLS_GROUP, as ctrlType reports them.
#define CTRL_TYPE_EDIT 2
#define CTRL_TYPE_GROUP 15

// ---------------------------------------------------------------------------
// The window: a pane in the middle of the screen, as wide as fits and 35 rows high.
//
//    0.8 -  2.3   title, where it saves, undo, redo, close         (in UNITs from its top)
//    2.75 - 3.9   the steps
//    4.45 - ...   the step itself
//   last 2.4      key hints, the hint, Back / Next / Save
// ---------------------------------------------------------------------------
#define WIZ_W ((SQUARE(UNIT * 60)) min (safezoneW - SQUARE(UNIT * 2)))
#define WIZ_H (UNIT * 35)
#define WIZ_X (safezoneX + (safezoneW - WIZ_W) / 2)
#define WIZ_Y (safezoneY + (safezoneH - WIZ_H) / 2)

#define WIZ_PAD_Y (UNIT * 0.8)
#define WIZ_PAD_X (SQUARE(WIZ_PAD_Y))

#define WIZ_TITLE_H (UNIT * 1.5)
#define WIZ_STEPS_H (UNIT * 1.15)
#define WIZ_BANNER_H (UNIT * 1.6)
#define WIZ_FOOT_H (UNIT * 2.4)

// A card inside a step: its padding and the row its caption takes.
#define CARD_PAD_Y (UNIT * 0.5)
#define CARD_PAD_X (SQUARE(CARD_PAD_Y))
#define CARD_CAPTION_H (UNIT * 1.1)

// Text sizes, as heights.
#define TEXT_TITLE (UNIT * 0.95)
#define TEXT_HEAD (UNIT * 0.8)
#define TEXT_BODY (UNIT * 0.64)
#define TEXT_SMALL (UNIT * 0.56)

// The size EINV_StructuredText is made with (gui/RscBase.hpp): a text of another size is written as a
// share of it.
#define STRUCTURED_SIZE (UNIT * 0.7)

// Colours the theme has no key for: Enhanced First Aid Kits' menus and their edge, the accent under the
// mouse, and what is greyed out.
#define MENU_BG [0.075, 0.083, 0.1, 0.97]
#define MENU_EDGE [1, 1, 1, 0.14]
#define ACCENT_HOVER [1, 0.733, 0.29, 1]
#define DISABLED_FILL [1, 1, 1, 0.035]
#define DISABLED_INK [1, 1, 1, 0.3]

// ---------------------------------------------------------------------------
// The Items and Containers steps.
// ---------------------------------------------------------------------------

// A row of the class index (fnc_buildIndex): the class lowercase and as config names it, what the search
// looks through (class and name, lowercase), its name, its kind and the family the Items step filters by,
// its picture, the mod it comes from and what it holds (config mass; 0 for what is no container).
#define ROW_LC 0
#define ROW_CLASS 1
#define ROW_SEARCH 2
#define ROW_NAME 3
#define ROW_KIND 4
#define ROW_FAMILY 5
#define ROW_PICTURE 6
#define ROW_MOD 7
#define ROW_LOAD 8

// Where the index looks, in the order the rules engine does (einv_items_fnc_getFacts).
#define INDEX_ROOTS ["CfgWeapons", "CfgMagazines", "CfgGlasses", "CfgVehicles"]

// One piece of the index may take this long (s) - the window keeps its frame rate while it is read -, and
// looks at the clock every INDEX_STRIDE classes.
#define INDEX_BUDGET 0.006
#define INDEX_STRIDE 64

// The kinds the Containers step lists: what holds things and has a grid.
#define CONTAINER_KINDS ["uniform", "vest", "backpack", "crate", "vehicle"]

// Cards on one page of a class list: only those are drawn and asked what the rules make of them.
#define LIST_PAGE 30

// The ends of the Items step's numbers: an item at most 8 cells down (the rules would take more, the
// window would not show it well), and a tile holding at most what the rules engine allows (MAX_STACK).
#define EDIT_ITEM_ROWS 8
#define EDIT_STACK_MAX 999

// The cell editor (fnc_drawCellEditor): a hole - a cell the compartment does not have - darker than the
// glass, and a cell or hole under the mouse. A cell takes the theme's buttonHover.
#define EDIT_HOLE [0, 0, 0, 0.32]
#define EDIT_HOVER [1, 1, 1, 0.3]
