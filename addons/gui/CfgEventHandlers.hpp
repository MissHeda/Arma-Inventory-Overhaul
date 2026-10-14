class Extended_PreInit_EventHandlers {
    class ADDON {
        init = QUOTE(call COMPILE_FILE(XEH_preInit));
        disableModuload = "true";
    };
};

// The vanilla inventory is gone: whatever brings the display up is closed again the moment it loads
// (fnc_guardVanilla; XEH_postInit looks for one this event missed).
class Extended_DisplayLoad_EventHandlers {
    class RscDisplayInventory {
        ADDON = QUOTE(_this call FUNC(guardVanilla));
    };
};

class Extended_PostInit_EventHandlers {
    class ADDON {
        init = QUOTE(call COMPILE_FILE(XEH_postInit));
    };
};
