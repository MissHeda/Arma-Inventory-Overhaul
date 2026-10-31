// Settings are ordered by topic, and within a topic numbers, then switches, then lists, then text boxes.

// ----- About the server settings -----

// The first row of the category "Arma Inventory Overhaul - Server", above every topic (CBA puts the settings without
// a sub-category first): a list with a single choice that only says where else these settings are - the setup
// wizard's General page - and that both places stay in sync. It changes nothing and nothing reads it. Registered
// here, before any addon registers its server settings.
[
    QGVAR(settingsInfo),
    "LIST",
    [LLSTRING(Setting_Info), LLSTRING(Setting_Info_Desc)],
    CBA_SETTINGS_AIO_SERVER,
    [[0], [LLSTRING(Setting_Info_Value)], 0],
    1
] call CBA_fnc_addSetting;
