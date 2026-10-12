#define COMPONENT setup
#define COMPONENT_BEAUTIFIED EINV - Setup
#include "\z\einv\addons\main\script_mod.hpp"
#include "\z\einv\addons\main\script_macros.hpp"

// The one setting the wizard edits: the whole setup as a text (einv_items_fnc_parseRules reads it), and
// what it holds while nobody has changed it.
#define RULES_SETTING QEGVAR(items,rules)
#define RULES_DEFAULT "einv1 base=default"

// Undo goes back this many changes.
#define UNDO_DEPTH 50

// A rules text longer than TEXT_WARN gets a warning - CBA's text boxes and the mission file have not been
// tried with more in the game - and one longer than TEXT_MAX is not saved at all.
#define TEXT_WARN 8192
#define TEXT_MAX 16384
