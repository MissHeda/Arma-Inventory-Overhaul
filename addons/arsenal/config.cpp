#include "script_component.hpp"
#include "defines.hpp"

// The Enhanced Arsenal: ACE Arsenal's boxes, loadouts and events in the inventory's window, and the
// vanilla Virtual Arsenal by setting. ACE is a hard requirement of the mod, so this addon is not skipped
// when ace_arsenal is missing - the game should say so. ace_arsenal makes the patches of its display and
// of Eden's Arsenal menu load after ACE's own, A3_Functions_F_Bootcamp the entry for BIS_fnc_arsenal after
// BI's. ACE Arsenal Extended is neither required nor ordered against: only onLoad of ACE's display is
// patched, which it leaves alone (CfgAceArsenal.hpp).
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
            "einv_main",
            "einv_items",
            "einv_storage",
            "einv_gui",
            "einv_setup"
        };
        author = "Miss Heda";
        url = ECSTRING(main,URL);
        VERSION_CONFIG;
    };
};

#include "CfgEventHandlers.hpp"
#include "CfgFunctions.hpp"
#include "CfgAceArsenal.hpp"
#include "Display3DEN.hpp"
#include "RscArsenal.hpp"
