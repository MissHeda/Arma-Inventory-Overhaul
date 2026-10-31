#define COMPONENT compat_aime
#define COMPONENT_BEAUTIFIED EINV - ACE Interaction Menu Expansion
#include "\z\einv\addons\main\script_mod.hpp"
#include "\z\einv\addons\main\script_macros.hpp"

// AIME's own names (author upsilon, Workshop 1376867375): the CBA settings its actions read, and the action
// of its "Change Ammo Type" menu, which this addon takes the place of (XEH_postInit).
#define AIME_AMMO_ACTION "UPSL_aime_change_ammo_ammo_class"
#define AIME_AMMO_SETTING "UPSL_aime_change_ammo_setting_ammo_class"
#define AIME_OPEN_SETTING "UPSL_aime_inventory_setting_open_action"
#define AIME_BACKPACK_SETTING "UPSL_aime_inventory_setting_backpack_action"
