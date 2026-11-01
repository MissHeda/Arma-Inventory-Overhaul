#include "script_component.hpp"

// BackpackOnChest (DerZade, Workshop 820924072) and its Redux (mjc4wilton) let a soldier carry a second backpack on
// the chest. Their actions - pack on the chest, back on the back, swap the two - are entries of the backpack slot's
// right-click menu in the window (fnc_menuChoices). Either mod is found by its functions when the menu opens, so this
// addon needs neither of them and does nothing without them.
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
