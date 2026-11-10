#include "script_component.hpp"

// Loads only with Antistasi Ultimate (Workshop 3020755032): an addon whose required addons are missing is skipped,
// quietly. Antistasi's arsenal (JNA, A3A_jeroen_arsenal) is the vanilla Virtual Arsenal with a shared stock: the
// server keeps how many of each item the rebels own (jna_dataList) and every take and return goes through it. This
// addon registers that stock with the grid panel (aio_arsenal_fnc_registerPool), so the panel lies beside JNA's list
// as it does beside ACE Arsenal's, and everything it adds or takes away is counted against the stock.
class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {};
        weapons[] = {};
        requiredVersion = REQUIRED_VERSION;
        requiredAddons[] = {
            "cba_main",
            "aio_main",
            "aio_arsenal",
            "A3A_jeroen_arsenal"
        };
        skipWhenMissingDependencies = 1;
        author = "Miss Heda";
        url = ECSTRING(main,URL);
        VERSION_CONFIG;
    };
};

#include "CfgEventHandlers.hpp"
