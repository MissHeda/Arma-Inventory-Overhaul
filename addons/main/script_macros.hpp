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

// Category every setting and keybind of the mod lives under, shared by all addons.
#define CBA_SETTINGS_EINV "Enhanced Inventory"

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
// anew each time the style changes.
#define STORAGE_COLS 8

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

// Most item moves one transaction carries (einv_storage_fnc_request): the window sends the next chunk
// when this one is answered (einv_gui_fnc_sendMoves), so one message never carries a whole crate.
#define BATCH_MAX 25

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

// A container is "near" full by weight from this share of its load used (einv_storage_fnc_getLoadState). The
// window draws it in a warning colour (einv_gui_fnc_drawSection), and a section that brings its own fill
// - a kit - is judged by it as well.
#define NEAR_FULL 0.85
