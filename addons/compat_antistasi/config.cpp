#include "script_component.hpp"

// Loads only with Antistasi Ultimate (Workshop 3020755032): an addon whose required addons are missing is skipped,
// quietly. That mod's "Loot around" (a loot truck or crate, SCRT_fnc_loot_gatherLoot) takes the bodies and the
// piles near it by their exact class - WeaponHolderSimulated, GroundWeaponHolder, WeaponHolder - and so passed over
// every pile this mod puts things into (a GroundWeaponHolder_Scripted, aio_storage_fnc_getGroundHolder). Its
// function is pointed at fnc_gatherLoot, which runs that mod's own file with this mod's piles taken in as well.
class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {};
        weapons[] = {};
        requiredVersion = REQUIRED_VERSION;
        requiredAddons[] = {
            "cba_main",
            "aio_main",
            "A3A_scrt"
        };
        skipWhenMissingDependencies = 1;
        author = "Miss Heda";
        url = ECSTRING(main,URL);
        VERSION_CONFIG;
    };
};

class CfgFunctions {
    class SCRT {
        class Loot {
            class loot_gatherLoot {
                file = QPATHTOF(functions\fnc_gatherLoot.sqf);
            };
        };
    };
};
