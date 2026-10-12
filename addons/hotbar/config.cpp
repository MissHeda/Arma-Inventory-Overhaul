#include "script_component.hpp"
#include "defines.hpp"

class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {};
        weapons[] = {};
        requiredVersion = REQUIRED_VERSION;
        requiredAddons[] = {
            "cba_main",
            "ace_common",
            "A3_Ui_F",
            "einv_main",
            "einv_items",
            "einv_storage",
            "einv_gui"
        };
        author = "Miss Heda";
        url = ECSTRING(main,URL);
        VERSION_CONFIG;
    };
};

#include "CfgEventHandlers.hpp"
#include "CfgUIGrids.hpp"
#include "RscHud.hpp"
