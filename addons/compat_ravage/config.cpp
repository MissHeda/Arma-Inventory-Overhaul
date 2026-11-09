#include "script_component.hpp"

// Loads only with Ravage (Workshop 1376636636): an addon whose required addons are missing is skipped, quietly.
// Ravage's "Search" (a hold action on furniture and containers) makes an empty ground pile at the player's feet,
// marks it _uncheckedLoot and opens it; its InventoryOpened handler (fnc_checkLoot) fills the pile a moment later
// and opens it again. The window opened on the first asking - the pile still empty, so passed over as the engine's
// pile at the feet - and refused the second one, as it was open already: the find never showed. That first asking
// is held back now (see XEH_preInit), and the window opens on the filled pile.
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
