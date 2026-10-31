#include "script_component.hpp"
#include "defines.hpp"

// ACE Arsenal's grid panel: beside ACE's list, the open uniform's, vest's or backpack's grid, drawn by the
// inventory's engine on ACE's own display - nothing of ACE's is patched or replaced. And the vanilla
// Virtual Arsenal by setting. ACE is a hard requirement of the mod, so this addon is not skipped when
// ace_arsenal is missing - the game should say so. A3_Functions_F_Bootcamp makes the entry for
// BIS_fnc_arsenal load after BI's.
class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {};
        weapons[] = {};
        requiredVersion = REQUIRED_VERSION;
        requiredAddons[] = {
            "cba_main",
            "ace_common",
            "ace_arsenal",
            "A3_Functions_F_Bootcamp",
            "aio_main",
            "aio_items",
            "aio_storage",
            "aio_gui",
            "aio_setup"
        };
        author = "Miss Heda";
        url = ECSTRING(main,URL);
        VERSION_CONFIG;
    };
};

#include "CfgEventHandlers.hpp"
#include "CfgFunctions.hpp"
#include "RscArsenal.hpp"
