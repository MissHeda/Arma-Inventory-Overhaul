#include "script_component.hpp"

// Loads only with ACE Interaction Menu Expansion (AIME), whose actions it brings under this mod's rules: an
// addon whose required addons are missing is skipped, quietly - the rest of the mod works the same without
// it. It loads after the window (einv_gui, whose opening and checks it calls), after the storage (the use
// limits and the loading of a magazine) and after the two AIME addons whose actions it patches.
class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {};
        weapons[] = {};
        requiredVersion = REQUIRED_VERSION;
        requiredAddons[] = {
            "cba_main",
            "ace_interact_menu",
            "einv_main",
            "einv_storage",
            "einv_gui",
            "UPSL_aime_change_ammo",
            "UPSL_aime_inventory"
        };
        skipWhenMissingDependencies = 1;
        author = "Miss Heda";
        url = ECSTRING(main,URL);
        VERSION_CONFIG;
    };
};

#include "CfgEventHandlers.hpp"

// AIME's inventory actions, in its own classes, with the conditions of this window added to what each one
// asked already. Every one of them ends in the engine's Gear or OpenBag action - which this mod answers
// with its window and its checks, whatever menu asked - so what is changed here is when they are offered,
// and the ground pile's pick-up (below).
class CfgVehicles {
    // "Inventory" on a vehicle: shown when the window may open on it (in reach, not locked to the player),
    // and not at all next to ACE interaction's own "Inventory" of this mod.
    class LandVehicle;
    class Car: LandVehicle {
        class ACE_Actions {
            class ACE_MainActions {
                class UPSL_aime_inventory_open_action {
                    condition = QUOTE(_this call FUNC(vehicleCondition));
                };
            };
        };
    };

    class Tank: LandVehicle {
        class ACE_Actions {
            class ACE_MainActions {
                class UPSL_aime_inventory_open_action {
                    condition = QUOTE(_this call FUNC(vehicleCondition));
                };
            };
        };
    };

    class Air;
    class Helicopter: Air {
        class ACE_Actions {
            class ACE_MainActions {
                class UPSL_aime_inventory_open_action {
                    condition = QUOTE(_this call FUNC(vehicleCondition));
                };
            };
        };
    };

    class Plane: Air {
        class ACE_Actions {
            class ACE_MainActions {
                class UPSL_aime_inventory_open_action {
                    condition = QUOTE(_this call FUNC(vehicleCondition));
                };
            };
        };
    };

    class Ship;
    class Ship_F: Ship {
        class ACE_Actions {
            class ACE_MainActions {
                class UPSL_aime_inventory_open_action {
                    condition = QUOTE(_this call FUNC(vehicleCondition));
                };
            };
        };
    };

    // "Open backpack" on a living person (the 3D icon on the back and the entry in the main actions): shown
    // when the window may open them, as the setting "Living persons" and the reach say.
    class Man;
    class CAManBase: Man {
        class ACE_Actions {
            class UPSL_aime_inventory_backpack_action_3d {
                condition = QUOTE([ARR_2(_this,true)] call FUNC(personCondition));
            };

            class ACE_MainActions {
                class UPSL_aime_inventory_backpack_action {
                    condition = QUOTE([ARR_2(_this,false)] call FUNC(personCondition));
                };
            };
        };
    };

    // The ground pile's action: one click picks up the only item lying there - without the search, and with
    // the engine's addMagazine, which stops at a container's config load. With searching on for the ground the
    // click opens the window on the pile instead, where the item is searched first (fnc_holderRun); else a
    // magazine, or a weapon that does not fit an empty slot, goes through this mod's grid like a quick move
    // out of a pile (fnc_holderPick), and AIME's own pick-up runs for the rest.
    class ReammoBox;
    class WeaponHolder: ReammoBox {
        class ACE_Actions {
            class UPSL_aime_inventory_holder_action {
                statement = QUOTE(_this call FUNC(holderRun));
            };
        };
    };

    class ThingX;
    class WeaponHolderSimulated: ThingX {
        class ACE_Actions {
            class UPSL_aime_inventory_holder_action {
                statement = QUOTE(_this call FUNC(holderRun));
            };
        };
    };
};
