#include "script_component.hpp"

// Loads only with Mavic 3 (Improved): an addon whose required addons are missing is skipped, quietly - the rest
// of the mod works the same without it. That mod deploys a drone from its item when the player's engine "Put"
// event reports the item on a plain ground pile, an event this window never raises (see XEH_postInit).
class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {};
        weapons[] = {};
        requiredVersion = REQUIRED_VERSION;
        requiredAddons[] = {
            "cba_main",
            "ace_interact_menu",
            "aio_main",
            "aio_storage",
            "Mavic_Core"
        };
        skipWhenMissingDependencies = 1;
        author = "Miss Heda";
        url = ECSTRING(main,URL);
        VERSION_CONFIG;
    };
};

#include "CfgEventHandlers.hpp"
