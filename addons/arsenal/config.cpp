#include "script_component.hpp"
#include "defines.hpp"

// The arsenals' grid panel: beside the list on the right, the open uniform's, vest's or backpack's grid, drawn by the
// inventory's engine on the arsenal's own display - ACE Arsenal's, or the vanilla Virtual Arsenal's (fnc_biOpened) - and
// nothing of either is patched or replaced. By setting the vanilla one opens ACE Arsenal with the grid instead. ACE is
// optional: without it the vanilla arsenal has the grid. A3_Functions_F_Bootcamp makes the entry for BIS_fnc_arsenal load
// after BI's.
class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {};
        weapons[] = {};
        requiredVersion = REQUIRED_VERSION;
        requiredAddons[] = {
            "cba_main",
            "A3_Functions_F_Bootcamp",
            "aio_main",
            "aio_items",
            "aio_storage",
            "aio_gui",
            "aio_setup"
        };
        skipWhenMissingDependencies = 1;
        author = "Miss Heda";
        url = ECSTRING(main,URL);
        VERSION_CONFIG;
    };
};

#include "CfgEventHandlers.hpp"
#include "CfgFunctions.hpp"
#include "RscArsenal.hpp"
