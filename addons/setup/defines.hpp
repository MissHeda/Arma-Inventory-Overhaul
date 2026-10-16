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
#define DIK_C 46

// CT_EDIT and CT_CONTROLS_GROUP, as ctrlType reports them.
#define CTRL_TYPE_EDIT 2
#define CTRL_TYPE_GROUP 15

// How often a step's scroll positions are set again after it was drawn (fnc_restoreScroll).
#define RESTORE_TRIES 12

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
#define MENU_BG [0.06, 0.06, 0.06, 0.98]
#define MENU_EDGE [1, 1, 1, 0.14]
#define ACCENT_HOVER [1, 0.733, 0.29, 1]
#define DISABLED_FILL [1, 1, 1, 0.035]
#define DISABLED_INK [1, 1, 1, 0.3]

// ---------------------------------------------------------------------------
// The Items and Containers steps.
// ---------------------------------------------------------------------------

// A row of the class index (fnc_buildIndex): the class lowercase and as config names it, what the search
// looks through (class and name, lowercase), its name, its kind and the family the Items step filters by,
// its picture, the mod it comes from and what it holds (config mass; 0 for what is no container). The
// class as config names it (1) and the picture (6) are not read by name.
#define ROW_LC 0
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

// The kinds the Containers step lists: what holds things and has a grid - a kit of Enhanced First Aid Kits
// too, whose grid counts only once a rule or its config gives it one (einv_compat_efak_fnc_roomMode).
#define CONTAINER_KINDS ["uniform", "vest", "backpack", "crate", "vehicle", "kit"]

// The containers the General step sets a size for, one kind at a time (fnc_drawGeneral, fnc_kindRule): what a soldier
// wears and what holds cargo - each a rule "all kind=... > grid=WxH" of the text, which the engine asks after
// everything that is about a class (einv_items_fnc_resolve). Kits stay out: a grid for them all would turn off
// Enhanced First Aid Kits' capacity for every kit at once.
#define GENERAL_KINDS ["uniform", "vest", "backpack", "vehicle", "crate"]

// Cards on one page of a class list: only those are drawn and asked what the rules make of them.
#define LIST_PAGE 30

// The most that share a tile in the Items step: what the rules engine allows (MAX_STACK). An item is
// drawn on a canvas SHAPE_MAX cells each way. Its weight (kg) and name are limited as the rules engine
// limits them (MAX_WEIGHT, MAX_NAME).
#define EDIT_STACK_MAX 999
#define EDIT_WEIGHT_MAX 1000
#define EDIT_NAME_MAX 100

// The picture of an item (icon=, the Items step's zoom and shift) is counted in whole per cent on its
// steppers: [zoom, across, down], 100 % and nothing shifted being the plain picture. ICON_PLAIN is the same
// as the rules count it.
#define ICON_PERCENT_PLAIN [100, 0, 0]

// What a layout text starts with (fnc_exportClasses "layout", fnc_importClasses): the values of one class
// without its name, to share and to apply to whichever class is selected where it is imported.
#define LAYOUT_MARKER "einv-layout:"

// What fnc_drawIconBlock takes in height: its caption, the zoom row and the shift row with their gaps.
#define ICON_BLOCK_H (UNIT * 3.46)

// The picture picker (fnc_drawPicturePicker): a page of thumbnails, PICKER_COLS across and PICKER_ROWS down, a
// thumbnail with its name under it; a picture that many classes share lists PICKER_OWNERS of them for the search.
#define PICKER_COLS 6
#define PICKER_ROWS 4
#define PICKER_OWNERS 8

// The tree view of the class lists (fnc_classTree, fnc_drawTree): a row of the tree is this high, a level
// of the tree moves it this far in (TREE_INDENT_MAX levels at most, deeper ones stay at the last), and
// "up" stops at a parent with more classes than TREE_UP_MAX - a tree of the whole game is no use.
#define TREE_ROW_H (UNIT * 2.3)
#define TREE_INDENT (SQUARE(UNIT * 0.7))
#define TREE_INDENT_MAX 5
#define TREE_UP_MAX 2000

// The canvas both editors draw on (fnc_uiCanvas): a cell filled dark and a place without one light, as
// cells picked on a sheet; each a little lighter under the mouse.
#define CANVAS_ON [0.12, 0.12, 0.12, 0.97]
#define CANVAS_ON_HOVER [0.22, 0.22, 0.22, 0.97]
#define CANVAS_OFF [1, 1, 1, 0.24]
#define CANVAS_OFF_HOVER [1, 1, 1, 0.4]
// The Containers step paints compartments (fnc_uiCanvas with a palette): eight colours that stay apart on
// the dark card whatever the theme - red, blue, green, yellow, orange, purple, cyan, pink -, each a
// little lighter under the mouse. A place holds 0 for no colour, else 1 to PAINT_COUNT.
#define PAINT_COUNT 8
#define PAINT_COLORS [[0.9, 0.3, 0.3, 1], [0.28, 0.52, 0.94, 1], [0.32, 0.74, 0.36, 1], [0.95, 0.83, 0.24, 1], [0.96, 0.55, 0.16, 1], [0.63, 0.42, 0.9, 1], [0.24, 0.8, 0.84, 1], [0.93, 0.48, 0.74, 1]]
#define PAINT_HOVER [[0.95, 0.5, 0.5, 1], [0.48, 0.68, 0.98, 1], [0.52, 0.86, 0.56, 1], [0.99, 0.91, 0.48, 1], [0.99, 0.7, 0.4, 1], [0.76, 0.6, 0.97, 1], [0.48, 0.9, 0.92, 1], [0.97, 0.66, 0.85, 1]]
// On the drawing a painted place is the inventory's empty cell under a tint of its colour this strong
// (fnc_uiCanvas), stronger under the mouse; the colour itself frames each compartment.
#define PAINT_TINT 0.35
#define PAINT_TINT_HOVER 0.5
// The Blocks way of the Containers step (fnc_drawCellBlocks): a compartment's hole, and a place under
// the mouse.
#define BLOCK_HOLE [0, 0, 0, 0.32]
#define BLOCK_HOVER [1, 1, 1, 0.3]
// A canvas loaded from a grid may be taller than MAX_ROWS - compartments laid out one under the other
// with room to their right -, up to this; drawn on, it is MAX_ROWS at most.
#define CANVAS_ROWS_LOADED (MAX_ROWS * 2)

// How wide a button (fnc_uiAction) of W_TEXT on a row W_H high must be, with W_ICON (BOOL) or without: what
// fnc_uiAction takes off for its padding and icon, the label with fitText's slack, and half a row more -
// a button exactly that wide lost a pixel to snapping and showed "App..." at the small UI size.
// SQUARE written out: a comma inside a macro's argument would split it.
#define ACTION_W(W_TEXT,W_H,W_ICON,W_FONT) (((W_H) * ([0.6, 1.38] select (W_ICON)) + (W_H) * 0.5) * pixelW / pixelH + ((W_TEXT) getTextWidth [W_FONT, (W_H) * 0.5]) * TEXT_SLACK)
