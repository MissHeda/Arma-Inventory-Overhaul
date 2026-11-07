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
class RscListBox;
class RscListNBox;

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
        class aio_skin_28: RscControlsGroupNoScrollbars { idc = 99028; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_29: RscControlsGroupNoScrollbars { idc = 99029; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_30: RscControlsGroupNoScrollbars { idc = 99030; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_31: RscControlsGroupNoScrollbars { idc = 99031; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_32: RscControlsGroupNoScrollbars { idc = 99032; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_33: RscControlsGroupNoScrollbars { idc = 99033; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_34: RscControlsGroupNoScrollbars { idc = 99034; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_35: RscControlsGroupNoScrollbars { idc = 99035; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_36: RscControlsGroupNoScrollbars { idc = 99036; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_37: RscControlsGroupNoScrollbars { idc = 99037; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_38: RscControlsGroupNoScrollbars { idc = 99038; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_39: RscControlsGroupNoScrollbars { idc = 99039; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_40: RscControlsGroupNoScrollbars { idc = 99040; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_41: RscControlsGroupNoScrollbars { idc = 99041; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_42: RscControlsGroupNoScrollbars { idc = 99042; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_43: RscControlsGroupNoScrollbars { idc = 99043; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_44: RscControlsGroupNoScrollbars { idc = 99044; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_45: RscControlsGroupNoScrollbars { idc = 99045; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_46: RscControlsGroupNoScrollbars { idc = 99046; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_47: RscControlsGroupNoScrollbars { idc = 99047; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_48: RscControlsGroupNoScrollbars { idc = 99048; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_49: RscControlsGroupNoScrollbars { idc = 99049; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_50: RscControlsGroupNoScrollbars { idc = 99050; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_51: RscControlsGroupNoScrollbars { idc = 99051; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_52: RscControlsGroupNoScrollbars { idc = 99052; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_53: RscControlsGroupNoScrollbars { idc = 99053; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_54: RscControlsGroupNoScrollbars { idc = 99054; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_55: RscControlsGroupNoScrollbars { idc = 99055; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_56: RscControlsGroupNoScrollbars { idc = 99056; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_57: RscControlsGroupNoScrollbars { idc = 99057; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_58: RscControlsGroupNoScrollbars { idc = 99058; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_59: RscControlsGroupNoScrollbars { idc = 99059; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_60: RscControlsGroupNoScrollbars { idc = 99060; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_61: RscControlsGroupNoScrollbars { idc = 99061; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_62: RscControlsGroupNoScrollbars { idc = 99062; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_63: RscControlsGroupNoScrollbars { idc = 99063; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_64: RscControlsGroupNoScrollbars { idc = 99064; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_65: RscControlsGroupNoScrollbars { idc = 99065; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_66: RscControlsGroupNoScrollbars { idc = 99066; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_67: RscControlsGroupNoScrollbars { idc = 99067; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_68: RscControlsGroupNoScrollbars { idc = 99068; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_69: RscControlsGroupNoScrollbars { idc = 99069; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_70: RscControlsGroupNoScrollbars { idc = 99070; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_71: RscControlsGroupNoScrollbars { idc = 99071; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_72: RscControlsGroupNoScrollbars { idc = 99072; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_73: RscControlsGroupNoScrollbars { idc = 99073; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_74: RscControlsGroupNoScrollbars { idc = 99074; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_75: RscControlsGroupNoScrollbars { idc = 99075; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_76: RscControlsGroupNoScrollbars { idc = 99076; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_77: RscControlsGroupNoScrollbars { idc = 99077; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_78: RscControlsGroupNoScrollbars { idc = 99078; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_79: RscControlsGroupNoScrollbars { idc = 99079; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_80: RscControlsGroupNoScrollbars { idc = 99080; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_81: RscControlsGroupNoScrollbars { idc = 99081; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_82: RscControlsGroupNoScrollbars { idc = 99082; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_83: RscControlsGroupNoScrollbars { idc = 99083; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_84: RscControlsGroupNoScrollbars { idc = 99084; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_85: RscControlsGroupNoScrollbars { idc = 99085; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_86: RscControlsGroupNoScrollbars { idc = 99086; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_87: RscControlsGroupNoScrollbars { idc = 99087; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_88: RscControlsGroupNoScrollbars { idc = 99088; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_89: RscControlsGroupNoScrollbars { idc = 99089; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_90: RscControlsGroupNoScrollbars { idc = 99090; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_91: RscControlsGroupNoScrollbars { idc = 99091; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_92: RscControlsGroupNoScrollbars { idc = 99092; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_93: RscControlsGroupNoScrollbars { idc = 99093; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_94: RscControlsGroupNoScrollbars { idc = 99094; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_95: RscControlsGroupNoScrollbars { idc = 99095; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_96: RscControlsGroupNoScrollbars { idc = 99096; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_97: RscControlsGroupNoScrollbars { idc = 99097; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_98: RscControlsGroupNoScrollbars { idc = 99098; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
        class aio_skin_99: RscControlsGroupNoScrollbars { idc = 99099; x = 0; y = 0; w = 0; h = 0; class Controls {}; };
    };

    // ACE's bar under the picked row is see-through: aio_arsenal_fnc_aceSkin draws it - round in this mod's look, ACE's own white
    // bar in ACE's - under the row, so it can be round.
    class controls {
        class leftTabContent: RscListBox {
            colorSelectBackground[] = {0, 0, 0, 0};
            colorSelectBackground2[] = {0, 0, 0, 0};
        };
        class rightTabContentListnBox: RscListNBox {
            colorSelectBackground[] = {0, 0, 0, 0};
            colorSelectBackground2[] = {0, 0, 0, 0};
        };
    };
};
