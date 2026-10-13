// Settings are ordered by topic, and within a topic numbers, then switches, then lists, then text boxes.

// ----- Vanilla Arsenal -----

// For everyone alike: the mission decides which arsenals it allows.
private _modes = ["ace", "block", "vanilla"];
private _labels = [LLSTRING(Setting_BIArsenal_Ace), LLSTRING(Setting_BIArsenal_Block), LLSTRING(Setting_BIArsenal_Vanilla)];

[
    QGVAR(biArsenal),
    "LIST",
    [LLSTRING(Setting_BIArsenal), LLSTRING(Setting_BIArsenal_Desc)],
    [CBA_SETTINGS_EINV, LLSTRING(SubCategory_Vanilla)],
    [_modes, _labels, 0],
    1
] call CBA_fnc_addSetting;

[
    QGVAR(biMessage),
    "EDITBOX",
    [LLSTRING(Setting_BIMessage), LLSTRING(Setting_BIMessage_Desc)],
    [CBA_SETTINGS_EINV, LLSTRING(SubCategory_Vanilla)],
    "",
    1
] call CBA_fnc_addSetting;
