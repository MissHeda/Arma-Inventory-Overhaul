// preStart as well as preInit: CBA's Addon Options open over the game's menus too, and the button put
// there (fnc_initCbaMenu) and the wizard's own display read their functions from uiNamespace, which only
// preStart fills before a mission is running.
class Extended_PreStart_EventHandlers {
    class ADDON {
        init = QUOTE(call COMPILE_FILE(XEH_preStart));
    };
};

class Extended_PreInit_EventHandlers {
    class ADDON {
        init = QUOTE(call COMPILE_FILE(XEH_preInit));
        disableModuload = "true";
    };
};

// CBA's Addon Options are the vanilla game options display. CBA runs these handlers in config order, and
// this addon loads after CBA's settings, so the menu's own controls exist by the time this one runs.
class Extended_DisplayLoad_EventHandlers {
    class RscDisplayGameOptions {
        ADDON = QUOTE(_this call (uiNamespace getVariable [ARR_2(QQFUNC(initCbaMenu),{})]));
    };
};
