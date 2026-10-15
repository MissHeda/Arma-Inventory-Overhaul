#include "script_component.hpp"

// Loads only when ACE's interaction menu is there: an addon whose required addons are missing is skipped,
// quietly - the rest of the mod works the same without it, and the action menu's "Inventory" stays. The
// interaction menu is an ACE component a modpack may strip, so it gets an addon of its own like a mod
// would. It loads after the window (einv_gui), whose gate and opening it calls.
class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {};
        weapons[] = {};
        requiredVersion = REQUIRED_VERSION;
        requiredAddons[] = {
            "cba_main",
            "ace_interact_menu",
            "einv_main",
            "einv_gui"
        };
        skipWhenMissingDependencies = 1;
        author = "Miss Heda";
        url = ECSTRING(main,URL);
        VERSION_CONFIG;
    };
};

#include "CfgEventHandlers.hpp"
