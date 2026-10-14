class Extended_PreInit_EventHandlers {
    class ADDON {
        init = QUOTE(call COMPILE_FILE(XEH_preInit));
        disableModuload = "true";
    };
};

// The vanilla inventory must not come up over this window or in its place (fnc_guardVanilla).
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
