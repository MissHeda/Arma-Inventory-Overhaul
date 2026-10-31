#include "script_component.hpp"

// Loads only with Better Inventory (Workshop 2791403093): an addon whose required addons are missing is skipped,
// quietly - the rest of the mod works the same without it.
//
// Better Inventory dresses up the vanilla inventory (RscDisplayInventory). At every opening its InventoryOpened
// handler spawns a script that waits for that display and then lays it out. This window takes the vanilla
// inventory's place, so that display does not come - and each of those scripts would wait for the rest of the
// mission, one more for every opening, all of them running at once the next time the vanilla display does show.
// Its handler is emptied here; its look of the vanilla display stays as it is.
class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {};
        weapons[] = {};
        requiredVersion = REQUIRED_VERSION;
        requiredAddons[] = {
            "cba_main",
            "aio_main",
            "bettinv_main"
        };
        skipWhenMissingDependencies = 1;
        author = "Miss Heda";
        url = ECSTRING(main,URL);
        VERSION_CONFIG;
    };
};

class Extended_InventoryOpened_EventHandlers {
    class CAManBase {
        BetterInv_EH = "";
    };
};
