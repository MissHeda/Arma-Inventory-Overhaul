#include "script_component.hpp"

// Loads only with Ravage (Workshop 1376636636): an addon whose required addons are missing is skipped, quietly.
// Ravage's "Search" (a hold action on furniture) is made over: held only a moment, it opens the window on a hidden
// box at the furniture that holds what was found, searched there item by item like any crate (fnc_patchAction,
// fnc_search). A pile Ravage's own search made is filled at once, before the window opens on it (XEH_preInit).
class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {};
        weapons[] = {};
        requiredVersion = REQUIRED_VERSION;
        requiredAddons[] = {
            "cba_main",
            "aio_main",
            "aio_gui",
            "ravage"
        };
        skipWhenMissingDependencies = 1;
        author = "Miss Heda";
        url = ECSTRING(main,URL);
        VERSION_CONFIG;
    };
};

#include "CfgEventHandlers.hpp"
