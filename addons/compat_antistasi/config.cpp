#include "script_component.hpp"

// For Antistasi Ultimate (Workshop 3020755032). It names none of that mod's addons as required: Antistasi lists every
// addon that does as an "extender" and warns about each one that does not declare its exact version
// (A3A_compatibility) - a dialog at every mission start, back with each of its updates. So this one always loads and
// does nothing without Antistasi (fnc_isLoaded).
//
// Where Antistasi's own functions go past the grid, they are pointed at this addon's (CfgFunctions below). A class of a
// function that only names its file merges with Antistasi's empty one whichever addon loads first, so no load order is
// needed. Each of them runs Antistasi's own file, read from its addon, with the few words changed that matter here
// (fnc_patched) - or wraps it unchanged - so the rest stays that mod's as it ships; should its words ever read
// differently, it runs unchanged and the RPT says so. Without Antistasi none of them is ever called.
//   SCRT_fnc_loot_gatherLoot     "Loot around" takes this mod's piles as well (fnc_gatherLoot)
//   SCRT_fnc_paradrop_jump       the HALO jump gives the backpack back as it was, every thing on its cell (fnc_paradropJump)
//   A3A_fnc_mineSweep            the engineer's mine sweep never deletes a pile of this mod (fnc_mineSweep)
//   A3U_fnc_useMagazineItem      a lockpick kit is used from a container it may be used from first (fnc_useMagazineItem)
//   HALs_store_fnc_canAddItem    the trader's room check counts the grid (fnc_canAddItem)
//   HALs_store_fnc_main          ... and so does its Buy button (fnc_storeMain)
//   ABZ_fnc_receiveItems         the Bazaar's purchases go in only where the grid has room, else beside the player
//                                as that mod does when there is none (fnc_receiveItems)
class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {};
        weapons[] = {};
        requiredVersion = REQUIRED_VERSION;
        requiredAddons[] = {
            "cba_main",
            "aio_main",
            "aio_storage",
            "aio_gui"
        };
        author = "Miss Heda";
        url = ECSTRING(main,URL);
        VERSION_CONFIG;
    };
};

#include "CfgEventHandlers.hpp"

class CfgFunctions {
    class SCRT {
        class Loot {
            class loot_gatherLoot {
                file = QPATHTOF(functions\fnc_gatherLoot.sqf);
            };
        };
        class Paradrop {
            class paradrop_jump {
                file = QPATHTOF(functions\fnc_paradropJump.sqf);
            };
        };
    };
    class A3A {
        class AI {
            class mineSweep {
                file = QPATHTOF(functions\fnc_mineSweep.sqf);
            };
        };
    };
    class A3U {
        class Utility {
            class useMagazineItem {
                file = QPATHTOF(functions\fnc_useMagazineItem.sqf);
            };
        };
    };
    class HALs_store {
        class System {
            class canAddItem {
                file = QPATHTOF(functions\fnc_canAddItem.sqf);
            };
        };
        class UI {
            class main {
                file = QPATHTOF(functions\fnc_storeMain.sqf);
            };
        };
    };
    class ABZ {
        class main {
            class receiveItems {
                file = QPATHTOF(functions\fnc_receiveItems.sqf);
            };
        };
    };
};
