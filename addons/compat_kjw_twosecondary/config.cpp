#include "script_component.hpp"

// Loads only with KJW's Two Secondary Weapons (Workshop 3018159841): an addon whose required addons are missing is
// skipped, quietly - the rest of the mod works the same without it. The second handgun that mod keeps holstered is a
// slot of the window then, next to the handgun (see XEH_preInit).
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
            "KJW_TwoSecondaryWeapons"
        };
        skipWhenMissingDependencies = 1;
        author = "Miss Heda";
        url = ECSTRING(main,URL);
        VERSION_CONFIG;
    };
};

#include "CfgEventHandlers.hpp"
