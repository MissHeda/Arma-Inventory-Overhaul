#include "script_component.hpp"

// Loads only with Zeus Enhanced, whose right-click menu, custom modules and dialogs it uses: an addon whose
// required addons are missing is skipped, quietly - the rest of the mod works the same without it.
class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {};
        weapons[] = {};
        requiredVersion = REQUIRED_VERSION;
        requiredAddons[] = {
            "cba_main",
            "zen_context_menu",
            "zen_custom_modules",
            "zen_dialog",
            "aio_main",
            "aio_locks"
        };
        skipWhenMissingDependencies = 1;
        author = "Miss Heda";
        url = ECSTRING(main,URL);
        VERSION_CONFIG;
    };
};

#include "CfgEventHandlers.hpp"
