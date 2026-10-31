#define COMPONENT setup
#define COMPONENT_BEAUTIFIED EINV - Setup
#include "\z\einv\addons\main\script_mod.hpp"
#include "\z\einv\addons\main\script_macros.hpp"

// What the wizard edits: the rules - the whole setup of sizes, stacks and grids as one CBA text (einv_items_fnc_parseRules
// reads it), and what it holds while nobody has changed it - and the server settings, each a CBA setting of its own
// (einv_main_fnc_addSetting), which the draft holds as one short text (einv_main_fnc_parseSettings reads it; empty while
// all are at their defaults). LEGACY_SETTINGS is the one text box the test builds kept them in, which an import still reads.
#define RULES_SETTING QEGVAR(items,rules)
#define RULES_DEFAULT "einv1 base=default"
#define LEGACY_SETTINGS QEGVAR(main,settings)

// Undo goes back this many changes.
#define UNDO_DEPTH 50

// A rules text longer than TEXT_WARN gets a warning, and one longer than TEXT_MAX is not saved at all - nor
// applied: a change that would make it longer is turned down (fnc_commit), as the engine would read such a
// text as the default and every rule of the setup would be gone. The same limits as the rules engine's.
#define TEXT_WARN 65536
#define TEXT_MAX 262144
