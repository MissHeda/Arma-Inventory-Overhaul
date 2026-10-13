#define COMPONENT arsenal
#define COMPONENT_BEAUTIFIED EINV - Arsenal
#include "\z\einv\addons\main\script_mod.hpp"
#include "\z\einv\addons\main\script_macros.hpp"

// ACE Arsenal's own numbers. Its defines.hpp is not in this project's include folder, so they are
// copied here, each under the name it has there (z\ace\addons\arsenal\defines.hpp, ACE 3.21.2).

// The arsenal's display (IDD_ace_arsenal).
#define ARSENAL_IDD 1127001

// The list of the right panel (IDC_rightTabContentListnBox), its "+" arrow (IDC_arrowPlus), the load
// bar under it (IDC_loadIndicatorBar) and the message line across the bottom of the middle (IDC_message).
#define ARSENAL_IDC_LIST 15
#define ARSENAL_IDC_PLUS 102
#define ARSENAL_IDC_LOAD 701
#define ARSENAL_IDC_MESSAGE 9

// The "Remove all" button that empties the open uniform, vest or backpack (IDC_buttonRemoveAll).
#define ARSENAL_IDC_REMOVE_ALL 40

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
