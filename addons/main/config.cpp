#include "script_component.hpp"

class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {};
        weapons[] = {};
        requiredVersion = REQUIRED_VERSION;
        requiredAddons[] = {
            "cba_main"
        };
        author = "Miss Heda";
        url = CSTRING(URL);
        VERSION_CONFIG;
    };
};

#include "CfgEventHandlers.hpp"

// The one address the update check may load (aio_gui_fnc_updateCheck): the engine loads no address a config does not allow.
class CfgCommands {
    allowedHTMLLoadURIs[] += {
        "https://raw.githubusercontent.com/MissHeda/Arma-Inventory-Overhaul/main/updates/outdated/*"
    };
};
