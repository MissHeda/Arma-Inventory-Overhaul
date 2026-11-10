#include "script_component.hpp"

// Loads only with TSP Animate - Rewrite (Workshop 3283612524): an addon whose required addons are missing is
// skipped, quietly. Mounting or taking off a weapon's attachment in the window plays TSP's gesture (the screwing
// on of a suppressor, the click of an optic) as the vanilla inventory does with that mod.
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
            "tsp_animate"
        };
        skipWhenMissingDependencies = 1;
        author = "Miss Heda";
        url = ECSTRING(main,URL);
        VERSION_CONFIG;
    };
};

#include "CfgEventHandlers.hpp"
