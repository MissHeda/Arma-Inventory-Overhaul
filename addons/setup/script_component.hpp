#define COMPONENT setup
#define COMPONENT_BEAUTIFIED EINV - Setup
#include "\z\einv\addons\main\script_mod.hpp"
#include "\z\einv\addons\main\script_macros.hpp"

// The two settings the wizard edits: the rules - the whole setup of sizes, stacks and grids as a text
// (einv_items_fnc_parseRules reads it), and what it holds while nobody has changed it - and the server
// settings, one text for all the ones that are the same for everyone (einv_main_fnc_parseSettings reads it;
// empty while nobody has changed any).
#define RULES_SETTING QEGVAR(items,rules)
#define RULES_DEFAULT "einv1 base=default"
#define SETTINGS_SETTING QEGVAR(main,settings)

// Undo goes back this many changes.
#define UNDO_DEPTH 50

// A rules text longer than TEXT_WARN gets a warning - CBA's text boxes and the mission file have not been
// tried with more in the game - and one longer than TEXT_MAX is not saved at all.
#define TEXT_WARN 8192
#define TEXT_MAX 16384
