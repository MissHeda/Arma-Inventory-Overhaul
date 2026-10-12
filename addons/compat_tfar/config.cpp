#include "script_component.hpp"

// Loads only when Task Force Arrowhead Radio is there: an addon whose required addons are missing is
// skipped, quietly - the rest of the mod works the same without it. TFAR and ACRE2 never load together;
// each has an addon of its own that answers the same questions about a radio (einv_gui_fnc_compatCollect
// asks both).
class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {};
        weapons[] = {};
        requiredVersion = REQUIRED_VERSION;
        requiredAddons[] = {
            "cba_main",
            "tfar_core",
            "einv_main",
            "einv_storage",
            "einv_gui"
        };
        skipWhenMissingDependencies = 1;
        author = "Miss Heda";
        url = ECSTRING(main,URL);
        VERSION_CONFIG;
    };
};

#include "CfgEventHandlers.hpp"
