// Warnings and errors go straight to the RPT rather than through CBA_fnc_log.
#define DEBUG_SYNCHRONOUS
#include "\x\cba\addons\main\script_macros_common.hpp"
#include "\x\cba\addons\xeh\script_xeh.hpp"

// Functions are compiled through CBA, which caches them and lets them be recompiled while testing
// with file patching.
#undef PREP
#define PREP(fncName) [QPATHTOF(functions\DOUBLES(fnc,fncName).sqf), QFUNC(fncName)] call CBA_fnc_compileFunction

// ACE3's variables and functions, the way ACE names them.
#define ACE_PREFIX ace

#define ACEGVAR(module,var)         TRIPLES(ACE_PREFIX,module,var)
#define QACEGVAR(module,var)        QUOTE(ACEGVAR(module,var))

#define ACEFUNC(module,function)    TRIPLES(DOUBLES(ACE_PREFIX,module),fnc,function)
#define QACEFUNC(module,function)   QUOTE(ACEFUNC(module,function))

// Category every keybind of the mod lives under (CBA's Controls menu), shared by all addons. The settings are in two
// categories of CBA's Addon Options: what each player sets for himself (scope 0), and what the server or the mission
// decides - the settings box einv_main_settings, the rules and the older tables (scope 1). A setting's name
// does not carry its category, so cba_settings.sqf lines and saved values are the same under either.
#define CBA_SETTINGS_EINV "Enhanced Inventory"
#define CBA_SETTINGS_EINV_CLIENT "Enhanced Inventory - Client"
#define CBA_SETTINGS_EINV_SERVER "Enhanced Inventory - Server"

// ---------------------------------------------------------------------------
// Shared between addons
// ---------------------------------------------------------------------------

// What an item is, for its tile's colour - see einv_items_fnc_getInfo.
#define CATEGORY_MISC    0
#define CATEGORY_GEAR    1
#define CATEGORY_WEAPON  2
#define CATEGORY_AMMO    3
#define CATEGORY_MEDICAL 4

// Every storage grid is this many cells wide, whatever the style. Where an item lies is stored per
// container (einv_storage_fnc_getLayout); a grid of another width would have to lay everything out
// anew each time the style changes. Ten since 0.4.0: a backpack drawn on the wizard's canvas - a
// column of pouches either side of the main compartment - needs the room. Places stored at eight
// stay valid, every compartment keeps its own columns.
#define STORAGE_COLS 10

// Config mass is counted in tenths of a pound. Kilograms the way ACE shows them.
#define MASS_TO_KG (0.1 / 2.2046)

// ... and the other way round: kilograms to config mass.
#define KG_TO_MASS (1 / MASS_TO_KG)

// How many rows an item or a compartment may have at most, how many compartments one container and
// how many cells all of them together (einv_items_fnc_parseGrid, einv_items_fnc_resolve,
// einv_storage_fnc_blocksFor). The window makes a control per cell, so a typo in a rule must not
// build tens of thousands of them.
#define MAX_ROWS 40
#define MAX_BLOCKS 24
#define MAX_CELLS (STORAGE_COLS * MAX_ROWS)

// The compartments a uniform and a vest get when no rule, mod or setting says otherwise (einv_storage_fnc_blocksFor,
// "block" and "pouches"): a uniform is one block UNIFORM_COLS wide and as many rows high as its load asks for, at least
// UNIFORM_ROWS_MIN and at most UNIFORM_ROWS_MAX; a vest is pouches, a tall one of one cell by two and a square one of
// two by two after another, as many as the load asks for (at most VEST_POUCHES_MAX, a pair of them being six cells).
#define UNIFORM_COLS 6
#define UNIFORM_ROWS_MIN 2
#define UNIFORM_ROWS_MAX 5
#define VEST_POUCHES_MAX 20

// An item drawn as a shape (size=xx/x-, einv_items_fnc_parseMask) is at most this many cells each way:
// the wizard draws one on a board this size, and every free-cell test walks its cells one by one.
#define SHAPE_MAX 8

// How an item's picture is drawn in its tile (icon=, einv_items_fnc_parseIcon, the "icon" of
// einv_items_fnc_getInfo): [scale, across, down], the offsets a share of the tile's width and height.
// ICON_PLAIN is the picture as it is fitted, nothing moved. Anything else is cut to its tile by the
// window (einv_gui_fnc_uiItemPicture), and the wizard offers the same range (einv_setup_fnc_drawItemEditor).
// ICON_PLAIN is an array literal - used in code only, never inside a macro's arguments.
#define ICON_PLAIN [1, 0, 0]
#define ICON_SCALE_MIN 0.25
#define ICON_SCALE_MAX 4
#define ICON_OFFSET_MAX 1

// The containers of a person's gear an item can be used from, in the order everything lists them (use=,
// einv_use, einv_items_fnc_parseUse; the "use" of einv_items_fnc_getInfo; the settings einv_storage_useUniform,
// einv_storage_useVest and einv_storage_useBackpack). An array literal - used in code only, never inside a
// macro's arguments.
#define USE_KINDS ["uniform", "vest", "backpack"]

// The four answers of the settings that say what can be used from one of them (einv_storage_useUniform and
// the others, einv_storage_fnc_useMode): everything in the container can be used, only the items whitelisted
// for it (use=, einv_use), nothing - and strict: only the whitelisted items, and the others are kept out of
// the container altogether, in a hidden holder on the unit (einv_storage_fnc_opStrict), so nothing but this
// mod can reach them.
#define USE_ALL "all"
#define USE_LIST "list"
#define USE_NONE "none"
#define USE_STRICT "strict"

// The longest texture path a picture override may have (picture=, einv_picture; einv_items_fnc_parsePicture).
#define PICTURE_MAX 260

// Most item moves one transaction carries (einv_storage_fnc_request): the window sends the next chunk
// when this one is answered (einv_gui_fnc_sendMoves), so one message never carries a whole crate.
#define BATCH_MAX 25

// The orders a Sort lays a container out in, in the order the Sort button steps through them
// (einv_gui_fnc_sortHolder, einv_storage_fnc_opSort, einv_storage_fnc_getLayout): by name, heaviest
// first, largest first, by kind. "size" is what a Sort did before there were orders, and what every layout
// of new items still does. Array literals - used in code only, never inside a macro's arguments.
#define SORT_MODES ["name", "weight", "size", "type"]
#define SORT_DEFAULT "size"

// What lies around a player: at most this many boxes of their own, within this height of the feet - the
// same floor (einv_storage_fnc_isNear, einv_storage_fnc_groundPos). Storage and the window both read
// them.
#define NEARBY_MAX 10
#define NEARBY_DZ 2

// How hard the weight a soldier carries is on him, in order (einv_weight_fnc_getTier). Light: nothing
// happens. Heavy: ACE's jog tires him. Overloaded: no sprinting, and ACE's fatigue costs rise. Critical:
// walking only. The weight addon works them out and the window shows them, so both name them the same.
#define TIER_LIGHT 0
#define TIER_HEAVY 1
#define TIER_OVERLOADED 2
#define TIER_CRITICAL 3
