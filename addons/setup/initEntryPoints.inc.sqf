// The way into the setup wizard that has to be registered while the mission starts. The others come
// by themselves: the button on CBA's Addon Options with the menu (fnc_initCbaMenu), the entry in Eden's
// Tools menu from config (Display3DEN.hpp), the cog with the inventory's header (aio_gui_fnc_drawHeader).
//
// Included by XEH_preInit for machines with a screen. The call does nothing harmful elsewhere: the pause
// menu entry is only a line in CBA's list. There is no keybind for the wizard; the pause menu, the cog and the
// other entries are enough.

// ESC > Options > Inventory setup. The engine makes the wizard over the pause menu itself; the wizard
// then opens in direct mode at its first step (its onLoad), the way every entry outside CBA's menu does.
// CBA's entries carry no condition, so the entry is in CBA's list for everyone, and taken off the pause menu
// again as it opens for a player who may not see the wizard (fnc_canOpen, asked every time: fnc_initPauseMenu,
// Extended_DisplayLoad_EventHandlers in CfgEventHandlers.hpp). Should that ever miss, the wizard's onLoad
// still closes it again without a word.
[[LLSTRING(OpenWizard), LLSTRING(OpenWizard_Tooltip)], QGVAR(RscWizard)] call CBA_fnc_addPauseMenuOption;
