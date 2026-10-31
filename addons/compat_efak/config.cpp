#include "script_component.hpp"

// Loads only with Enhanced First Aid Kits or Enhanced Utility Pouches, which brings that mod's framework
// along (efak_core, efak_gui): an addon whose required addons are missing is skipped, quietly - the rest
// of the mod works the same without it.
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
            "efak_core",
            "efak_gui"
        };
        skipWhenMissingDependencies = 1;
        author = "Miss Heda";
        url = ECSTRING(main,URL);
        VERSION_CONFIG;
    };
};

#include "CfgEventHandlers.hpp"
