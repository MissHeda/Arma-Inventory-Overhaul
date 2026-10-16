// The inventory window's own keys that the player may change, in CBA's Configure Addons. CBA's keybinds do not
// run while a dialog is open, so the window reads them itself (fnc_onKeyDown) - what the game's own screen
// does with the key is nothing, and the handler says so.

// Quick move: the double click's work for the tile under the mouse, from the keyboard.
[
    [CBA_SETTINGS_EINV, LLSTRING(SubCategory_General)],
    QGVAR(quickMove),
    [LLSTRING(Keybind_QuickMove), LLSTRING(Keybind_QuickMove_Tooltip)],
    {false},
    {},
    [DEFAULT_QUICK_KEY, [false, false, false]]
] call CBA_fnc_addKeybind;
