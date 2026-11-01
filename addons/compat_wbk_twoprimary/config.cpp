#include "script_component.hpp"

// Loads only with WebKnight's Two Primary Weapons (Workshop 2976569274): an addon whose required addons are missing
// is skipped, quietly - the rest of the mod works the same without it. The weapon that mod keeps on the back is a
// slot of the window then, next to the primary (see XEH_preInit).
class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {};
        weapons[] = {};
        requiredVersion = REQUIRED_VERSION;
        requiredAddons[] = {
            "cba_main",
            "aio_main",
            "aio_storage",
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
