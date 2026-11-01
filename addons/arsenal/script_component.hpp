#define COMPONENT arsenal
#define COMPONENT_BEAUTIFIED AIO - Arsenal
#include "\z\aio\addons\main\script_mod.hpp"
#include "\z\aio\addons\main\script_macros.hpp"

// ACE Arsenal's own numbers. Its defines.hpp is not in this project's include folder, so they are
// copied here, each under the name it has there (z\ace\addons\arsenal\defines.hpp, ACE 3.21.2).

// The arsenal's display (IDD_ace_arsenal).
#define ARSENAL_IDD 1127001

// The list of the right panel (IDC_rightTabContentListnBox), its "-" and "+" arrows (IDC_arrowMinus,
// IDC_arrowPlus) and the load bar under it (IDC_loadIndicatorBar).
#define ARSENAL_IDC_LEFT_LIST 13
#define ARSENAL_IDC_RIGHT_LIST 14
#define ARSENAL_IDC_LIST 15
#define ARSENAL_IDC_MINUS 101
#define ARSENAL_IDC_PLUS 102
#define ARSENAL_IDC_LOAD 701

// The "Close" button of ACE's menu bar (IDC_menuBarClose), whose click closes the display with exit code 1,
// and ACE's loadouts display (IDD_loadouts_display), which takes Escape for itself while it is open.
#define ARSENAL_IDC_CLOSE 1001
#define ARSENAL_IDD_LOADOUTS 1127002

// The sort bar over the right list (IDC_sortRightTab), whose top the panel starts at.
#define ARSENAL_IDC_SORT 17

// The soldier's weight beside ACE's menu bar (IDC_totalWeightText), which ACE writes only when its own panels change.
#define ARSENAL_IDC_WEIGHT 801

// The left panel's buttons for uniform, vest and backpack (IDC_buttonUniform, IDC_buttonVest,
// IDC_buttonBackpack) - what ace_arsenal_currentLeftPanel holds while one of them is open.
#define ARSENAL_IDC_UNIFORM 2010
#define ARSENAL_IDC_VEST 2012
#define ARSENAL_IDC_BACKPACK 2014

// Where the uniform's, vest's and backpack's items lie in ace_arsenal_currentItems
// (IDX_CURR_UNIFORM_ITEMS, IDX_CURR_VEST_ITEMS, IDX_CURR_BACKPACK_ITEMS).
#define ARSENAL_ITEMS_UNIFORM 15
#define ARSENAL_ITEMS_VEST 16
#define ARSENAL_ITEMS_BACKPACK 17

// Where the uniform, vest and backpack lie in a getUnitLoadout array (IDX_LOADOUT_UNIFORM,
// IDX_LOADOUT_VEST, IDX_LOADOUT_BACKPACK).
#define LOADOUT_UNIFORM 3
#define LOADOUT_VEST 4
#define LOADOUT_BACKPACK 5

// The vanilla Virtual Arsenal (BIS_fnc_arsenal; \a3\ui_f\hpp\defineResinclDesign.inc). Its display is RscDisplayArsenal, kept in
// the uiNamespace under that name. Each tab has a list of its own, IDC_RSCDISPLAYARSENAL_LIST plus the tab's index, the one of
// the open tab enabled; the sort bar over it IDC_RSCDISPLAYARSENAL_SORT plus that index; the "-" and "+" over the picked row
// of a cargo list (IDC_RSCDISPLAYARSENAL_ARROWLEFT, _ARROWRIGHT); the load bar under it (IDC_RSCDISPLAYARSENAL_LOADCARGO).
// The tabs of uniform, vest and backpack on the left (IDC_RSCDISPLAYARSENAL_TAB_UNIFORM, _VEST, _BACKPACK), and the cargo tabs
// on the right while one of them is open (_TAB_CARGOMAG, _CARGOTHROW, _CARGOPUT, _CARGOMISC, _CARGOMAGALL).
#define BI_IDC_LIST 960
#define BI_IDC_SORT 800
#define BI_IDC_MINUS 992
#define BI_IDC_PLUS 993
#define BI_IDC_LOAD 991
#define BI_TAB_UNIFORM 3
#define BI_TAB_VEST 4
#define BI_TAB_BACKPACK 5
#define BI_CARGO_TABS [21, 22, 23, 24, 26]

// How often the panel looks for what the vanilla arsenal changed, in frames (fnc_biWatch).
#define BI_WATCH_FRAMES 3
