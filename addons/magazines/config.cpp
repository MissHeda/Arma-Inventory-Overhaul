#include "script_component.hpp"

// Loads only when ACE's magazine repack is there: an addon whose required addons are missing is skipped,
// quietly - the rest of the mod works the same without it, and the window shows no repack. ACE's repack
// is an ACE component a modpack may strip, so it gets an addon of its own like a mod would.
class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {};
        weapons[] = {};
        requiredVersion = REQUIRED_VERSION;
        requiredAddons[] = {
            "cba_main",
            "ace_common",
            "ace_magazinerepack",
            "einv_main",
            "einv_storage",
            "einv_gui"
        };
        skipWhenMissingDependencies = 1;
        author = "Miss Heda";
        url = ECSTRING(main,URL);
        VERSION_CONFIG;
    };
};

#include "CfgEventHandlers.hpp"
