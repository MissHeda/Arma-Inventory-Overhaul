// Settings are ordered by topic, and within a topic numbers, then switches, then lists, then text boxes.

// ----- Setup -----

// The same for everyone: the server decides who sees its setup. Admins by default - a public server's
// players have no use for the wizard, and the setup it shows is the server's. Read whenever a way into
// the wizard is taken (fnc_canOpen), so a change needs no script.
[
    QGVAR(access),
    "LIST",
    [LLSTRING(Setting_Access), LLSTRING(Setting_Access_Desc)],
    [CBA_SETTINGS_EINV, LLSTRING(SubCategory_Setup)],
    [["everyone", "admins"], [LLSTRING(Option_Everyone), LLSTRING(Option_Admins)], 1],
    1
] call CBA_fnc_addSetting;
