// Settings are ordered by topic, and within a topic numbers, then switches, then lists, then text boxes.

// ----- Locks -----

// For everyone alike: the mission decides whether its game masters may look into everything.
[
    QGVAR(zeusOpens),
    "CHECKBOX",
    [LLSTRING(Setting_ZeusOpens), LLSTRING(Setting_ZeusOpens_Desc)],
    [CBA_SETTINGS_EINV, LLSTRING(SubCategory_Locks)],
    true,
    1
] call CBA_fnc_addSetting;
