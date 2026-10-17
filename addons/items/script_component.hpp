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
#define ITEM_KINDS ["rifle", "handgun", "launcher", "binocular", "muzzle", "optic", "rail", "bipod", "headgear", "nvg", "vest", "uniform", "map", "gps", "radio", "compass", "watch", "item", "magazine", "grenade", "backpack", "goggles", "crate", "vehicle", "kit", "unknown"]

// The kinds that hold things and so get a grid, and the kinds that never share a tile: each of them
// holds things of its own or carries attachments, and a tile moves only one of them with all that. A kit
// of Enhanced First Aid Kits or a pouch of Enhanced Utility Pouches holds things too, but its grid counts
// only where a rule or its config gives it one (einv_compat_efak_fnc_roomMode): else that mod's capacity
// is its room.
#define KINDS_CONTAINER ["uniform", "vest", "backpack", "crate", "vehicle", "kit"]

// Kinds that are an item to kind= as well: a kit is sized and stacked as the item it is - kind=item and the
// presets' item groups reach it as they always did - and has a grid as a kit (kind=kit reaches only kits).
// fnc_matches tests a condition that way, and fnc_compileRules sorts the rules that way.
#define KINDS_AS_ITEM ["kit"]
#define KINDS_SINGLE ["rifle", "handgun", "launcher", "binocular", "uniform", "vest", "backpack"]

// The tile categories by their names in the rules (cat=), in the order of the CATEGORY_* numbers.
#define CATEGORY_NAMES ["misc", "gear", "weapon", "ammo", "medical"]

// The grid patterns a container can be laid out by (grid=rig, ...), see einv_storage_fnc_blocksFor. "pouches"
// is what a vest gets when no rule says otherwise, "block" a uniform.
#define GRID_PATTERNS ["pockets", "pockets_mixed", "rig", "mixed", "plate", "long", "single", "wide", "pouches", "block"]

// What a uniform, vest or backpack gets from the built-in answer when nothing says otherwise: a fifth more
// room than its load gives (a share, as grid=120% writes it). Crates and vehicles get "auto", the load itself
// (fnc_resolve).
#define BUILTIN_WORN_GRID ["percent", 120]
#define WORN_KINDS ["uniform", "vest", "backpack"]

// Presets that were renamed or taken out, [old id, id read instead]: a text written before (base=tarkov,
// base=realism, base=weight) and another mod's preset that builds on one of them keep loading, on the one
// preset there is now (fnc_parseRules, fnc_compileRules).
#define PRESET_ALIASES [["tarkov", "default"], ["realism", "default"], ["weight", "default"]]

// The keys an item's own config may set, each written the way the rules write the same value
// (fnc_readConfigKeys): einv_size, einv_stack, einv_grid, einv_weight, einv_name, einv_icon, einv_picture, einv_use, einv_cat. fnc_configEntry
// writes them, fnc_parseConfigEntry reads them back from a snippet.
#define CONFIG_KEYS [QGVARMAIN(size), QGVARMAIN(stack), QGVARMAIN(grid), QGVARMAIN(weight), QGVARMAIN(name), QGVARMAIN(icon), QGVARMAIN(picture), QGVARMAIN(use), QGVARMAIN(cat)]

// The config roots an item class lives in, in the order fnc_getFacts looks for it.
#define CONFIG_ROOTS ["CfgWeapons", "CfgMagazines", "CfgVehicles", "CfgGlasses"]

// Most characters of a config snippet fnc_parseConfigEntry reads: a pasted file is a mistake, and every
// character is looked at one by one.
#define CONFIG_TEXT_MAX 65536

// What like=CLASS takes from that class (fnc_resolve) - everything but its name - and how many like=
// one item may follow, one after the other, before it gives up.
#define LIKE_FIELDS ["footprint", "stack", "grid", "weight"]
#define LIKE_DEPTH 8

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
