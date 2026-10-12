#include "script_component.hpp"

// Weight overrides from the rules ("weight=" in einv_items_rules) are only numbers to the engine's
// eyes - it keeps weighing every item by its config. This addon makes them count where players feel
// them: ACE's weight and fatigue, through ACE movement's virtual load. It also keeps the weight tiers
// - Light, Heavy, Overloaded, Critical - and what the red ones do to the player, through ACE's status
// effects and its fatigue.
class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {};
        weapons[] = {};
        requiredVersion = REQUIRED_VERSION;
        requiredAddons[] = {
            "cba_main",
            "ace_common",
            "ace_movement",
            "einv_main",
            "einv_items"
        };
        author = "Miss Heda";
        url = ECSTRING(main,URL);
        VERSION_CONFIG;
    };
};

#include "CfgEventHandlers.hpp"
