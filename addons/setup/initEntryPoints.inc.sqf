// The ways into the setup wizard that have to be registered while the mission starts. The others come
// by themselves: the button on CBA's Addon Options with the menu (fnc_initCbaMenu), the entry in Eden's
// Tools menu from config (Display3DEN.hpp), the cog with the inventory's header (einv_gui_fnc_drawHeader).
//
// Included by XEH_preInit for machines with a screen. Neither call does anything harmful elsewhere: the
// pause menu entry is only a line in CBA's list, and CBA leaves keybinds out on a dedicated server.

// ESC > Options > Inventory setup. The engine makes the wizard over the pause menu itself; the wizard
// then opens in direct mode at its first step (its onLoad), the way every entry outside CBA's menu does.
// CBA's entries carry no condition, so it is there for everyone: for a player einv_setup_access leaves
// out, the wizard's onLoad closes it again with a hint (fnc_canOpen).
[[LLSTRING(OpenWizard), LLSTRING(OpenWizard_Tooltip)], QGVAR(RscWizard)] call CBA_fnc_addPauseMenuOption;

// A key for it, left unbound: hardly anyone needs the wizard often enough to give it a key of its own,
// and whoever does picks one in CBA's Configure Addons. It works in a running mission only - CBA's keys
// are read on the game's own screen, which Eden and the main menu do not have.
[
    CBA_SETTINGS_EINV,
    QGVAR(openWizard),
    [LLSTRING(Keybind_Open), LLSTRING(OpenWizard_Tooltip)],
    {
        [0, ""] call FUNC(openFromGame);
        true
    },
    {},
    [0, [false, false, false]]
] call CBA_fnc_addKeybind;
