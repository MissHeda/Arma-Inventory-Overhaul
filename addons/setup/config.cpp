#include "script_component.hpp"
#include "defines.hpp"

// The setup wizard: sizes, stacks and container grids for everyone, as one text in the setting
// einv_items_rules. It edits that text and nothing else - the rules engine itself is the items addon's,
// the window's kit the gui addon's.
class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {};
        weapons[] = {};
        requiredVersion = REQUIRED_VERSION;
        requiredAddons[] = {
            "einv_gui",
            "einv_items",
            "einv_storage"
        };
        author = "Miss Heda";
        url = ECSTRING(main,URL);
        VERSION_CONFIG;
    };
};

#include "CfgEventHandlers.hpp"
#include "RscWizard.hpp"
#include "Display3DEN.hpp"
