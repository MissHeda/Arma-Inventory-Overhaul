#include "script_component.hpp"

// Loads only with Ravage (Workshop 1376636636): an addon whose required addons are missing is skipped, quietly.
// Ravage's "Search" (a hold action on furniture and containers) makes an empty ground pile at the player's feet,
// marks it _uncheckedLoot and opens it; its InventoryOpened handler (fnc_checkLoot) fills it a moment later. By then
// the pile was gone: the engine deletes an empty pile whose vanilla inventory closes. It is filled at once now, with
// Ravage's own function, before the window opens on it (see XEH_preInit).
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
