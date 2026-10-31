#include "script_component.hpp"

// Loads only with KPBLM Item Preview (Workshop 3822903400): an addon whose required addons are missing is skipped,
// quietly - the rest of the mod works the same without it. That mod shows an item in 3D from a row of the vanilla
// inventory (a press of the mouse wheel), which this window replaces; here the inspect card and the context menu
// open its showcase instead (aio_gui_fnc_drawInspect, aio_gui_fnc_contextMenu - only when this addon is loaded).
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
            "kpblm_itempreview"
        };
        skipWhenMissingDependencies = 1;
        author = "Miss Heda";
        url = ECSTRING(main,URL);
        VERSION_CONFIG;
    };
};

#include "CfgEventHandlers.hpp"
