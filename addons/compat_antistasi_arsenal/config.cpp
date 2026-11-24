#include "script_component.hpp"

// For Antistasi Ultimate (Workshop 3020755032). It names none of that mod's addons as required: Antistasi lists every addon
// that does as an "extender" and warns about each one that does not declare its exact version (A3A_compatibility), at
// every mission start until it is updated. So this one always loads and does nothing without Antistasi (XEH_preInit
// looks for A3A_jeroen_arsenal). Antistasi's arsenal (JNA, A3A_jeroen_arsenal) is the vanilla Virtual Arsenal with a shared stock: the
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
            "aio_arsenal"
        };
        author = "Miss Heda";
        url = ECSTRING(main,URL);
        VERSION_CONFIG;
    };
};

#include "CfgEventHandlers.hpp"
