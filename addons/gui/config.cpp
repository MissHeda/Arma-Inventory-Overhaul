#include "script_component.hpp"
#include "defines.hpp"

class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {};
        weapons[] = {};
        requiredVersion = REQUIRED_VERSION;
        requiredAddons[] = {
            "aio_storage",
            "aio_locks",
            "aio_weight"
        };
        author = "Miss Heda";
        url = ECSTRING(main,URL);
        VERSION_CONFIG;
    };
};

#include "CfgEventHandlers.hpp"
#include "CfgAioSounds.hpp"
#include "CfgActions.hpp"
#include "Cfg3DEN.hpp"
#include "RscBase.hpp"
#include "RscInventory.hpp"
