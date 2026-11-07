#include "script_component.hpp"

// ACE Arsenal in this mod's look (aio_arsenal_fnc_aceSkin): empty controls groups in ACE's background layer, the one layer drawn
// under all of ACE's controls - a control made at run time lies over everything made before it, and panels on the display under
// ACE's were not drawn at all (0.6.86). At run time each is placed under one of ACE's lists, boxes or buttons and filled with a
// round panel of the theme; with ACE's own look they stay empty and nought wide. Loads only with ACE Arsenal (skipped otherwise).
class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {};
        weapons[] = {};
        requiredVersion = REQUIRED_VERSION;
        requiredAddons[] = {
            "cba_main",
            "ace_arsenal",
            "aio_main",
            "aio_arsenal"
        };
        skipWhenMissingDependencies = 1;
        author = "Miss Heda";
        url = ECSTRING(main,URL);
        VERSION_CONFIG;
    };
};

class RscControlsGroupNoScrollbars;

class ace_arsenal_display {
    class ControlsBackground {
        class aio_skin_0: RscControlsGroupNoScrollbars { idc = 99000; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_1: RscControlsGroupNoScrollbars { idc = 99001; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_2: RscControlsGroupNoScrollbars { idc = 99002; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_3: RscControlsGroupNoScrollbars { idc = 99003; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_4: RscControlsGroupNoScrollbars { idc = 99004; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_5: RscControlsGroupNoScrollbars { idc = 99005; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_6: RscControlsGroupNoScrollbars { idc = 99006; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_7: RscControlsGroupNoScrollbars { idc = 99007; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_8: RscControlsGroupNoScrollbars { idc = 99008; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_9: RscControlsGroupNoScrollbars { idc = 99009; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_10: RscControlsGroupNoScrollbars { idc = 99010; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_11: RscControlsGroupNoScrollbars { idc = 99011; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_12: RscControlsGroupNoScrollbars { idc = 99012; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_13: RscControlsGroupNoScrollbars { idc = 99013; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_14: RscControlsGroupNoScrollbars { idc = 99014; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_15: RscControlsGroupNoScrollbars { idc = 99015; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_16: RscControlsGroupNoScrollbars { idc = 99016; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_17: RscControlsGroupNoScrollbars { idc = 99017; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_18: RscControlsGroupNoScrollbars { idc = 99018; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_19: RscControlsGroupNoScrollbars { idc = 99019; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_20: RscControlsGroupNoScrollbars { idc = 99020; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_21: RscControlsGroupNoScrollbars { idc = 99021; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_22: RscControlsGroupNoScrollbars { idc = 99022; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_23: RscControlsGroupNoScrollbars { idc = 99023; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_24: RscControlsGroupNoScrollbars { idc = 99024; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_25: RscControlsGroupNoScrollbars { idc = 99025; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_26: RscControlsGroupNoScrollbars { idc = 99026; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_27: RscControlsGroupNoScrollbars { idc = 99027; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
    };
};
