#define COMPONENT items
#define COMPONENT_BEAUTIFIED EINV - Items
#include "\z\einv\addons\main\script_mod.hpp"
#include "\z\einv\addons\main\script_macros.hpp"

// ---------------------------------------------------------------------------
// The rules (einv_items_rules, fnc_parseRules, fnc_compileRules)
// ---------------------------------------------------------------------------

// What the setting holds until someone changes it, and what an empty or unreadable text means.
#define DEFAULT_RULES "einv1 base=default"

// The defaults of the two older sliders. Moved off them, they still count (fnc_compileRules).
#define DEFAULT_MASS_PER_CELL 5
#define DEFAULT_STACK_SMALL 10

// Every kind fnc_getFacts gives out. The rules are sorted by these, so an item only meets the rules
// that can be about it.
#define ITEM_KINDS ["rifle", "handgun", "launcher", "binocular", "muzzle", "optic", "rail", "bipod", "headgear", "nvg", "vest", "uniform", "map", "gps", "radio", "compass", "watch", "item", "magazine", "grenade", "backpack", "goggles", "crate", "vehicle", "unknown"]

// The kinds that hold things and so get a grid, and the kinds that never share a tile: each of them
// holds things of its own or carries attachments, and a tile moves only one of them with all that.
#define KINDS_CONTAINER ["uniform", "vest", "backpack", "crate", "vehicle"]
#define KINDS_SINGLE ["rifle", "handgun", "launcher", "binocular", "uniform", "vest", "backpack"]

// The tile categories by their names in the rules (cat=), in the order of the CATEGORY_* numbers.
#define CATEGORY_NAMES ["misc", "gear", "weapon", "ammo", "medical"]

// The grid patterns a container can be laid out by (grid=rig, ...), see einv_storage_fnc_blocksFor.
#define GRID_PATTERNS ["pockets", "pockets_mixed", "rig", "mixed", "plate", "long", "single", "wide"]

// Limits on what a text may ask for. A rules text travels to every machine and is read on each, so
// a pasted mistake must stay cheap: statements past the limit, longer OR lists and texts over the
// size limit are left out, with a warning in the RPT.
#define MAX_STATEMENTS 500
#define MAX_ALTERNATIVES 64
#define MIN_SEARCH 3
#define TEXT_WARN 8192
#define TEXT_MAX 16384
#define MAX_GROUP_DEPTH 4
#define MAX_CHAIN 4
#define MAX_STACK 999
#define MAX_WEIGHT 1000
#define MAX_NAME 100
#define CELL_MIN 1
#define CELL_MAX 50
#define PERCENT_MIN 10
#define PERCENT_MAX 500

// ---------------------------------------------------------------------------
// Armor (fnc_getArmor, fnc_getProtection)
// ---------------------------------------------------------------------------

// ItemInfo >> type of the items whose armor ACE scales by what kind they are (headgear and vests above a
// limit, uniforms never): copied from ACE's damage handling for use without it.
#define TYPE_HEADGEAR 605
#define TYPE_VEST 701
#define TYPE_UNIFORM 801
