#include "script_component.hpp"

// Loads only with WebKnight's Two Primary Weapons (Workshop 2976569274): an addon whose required addons are missing
// is skipped, quietly - the rest of the mod works the same without it. That mod brings the weapon on the back into
// the hands from the player's engine "Put" event once the hands are empty, an event this window never raises (see
// XEH_postInit).
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
            "WBK_TwoWeaponsOnBack"
        };
        skipWhenMissingDependencies = 1;
        author = "Miss Heda";
        url = ECSTRING(main,URL);
        VERSION_CONFIG;
    };
};

#include "CfgEventHandlers.hpp"
