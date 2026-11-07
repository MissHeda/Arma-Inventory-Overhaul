#include "script_component.hpp"

// GreenMag Rework (Miss Heda, prefix gmr) loads magazines from loose rounds, packs and belts. Its right-click entries (Refill,
// Unload, Unpack, Pack, the belt's) are CBA item context menu options, which the window shows by itself (aio_gui_fnc_cbaOptions).
// What GreenMag cannot do in the window is its drag: it watches the lists of the engine's inventory, which the window replaces.
// Here a round, pack or belt let go on a magazine tile starts the same loading as GreenMag's own drag (fnc_canLoad, fnc_load).
// GreenMag is found by its functions when a drag asks, so this addon needs it not and does nothing without it.
class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {};
        weapons[] = {};
        requiredVersion = REQUIRED_VERSION;
        requiredAddons[] = {
            "cba_main",
            "aio_main",
            "aio_gui"
        };
        author = "Miss Heda";
        url = ECSTRING(main,URL);
        VERSION_CONFIG;
    };
};

#include "CfgEventHandlers.hpp"
