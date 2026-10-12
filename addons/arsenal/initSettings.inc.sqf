// Settings are ordered by topic, and within a topic numbers, then switches, then lists, then text boxes.

// ----- Arsenal -----

// Each player's own.
[
    QGVAR(quickAddAmount),
    "SLIDER",
    [LLSTRING(Setting_QuickAddAmount), LLSTRING(Setting_QuickAddAmount_Desc)],
    [CBA_SETTINGS_EINV, LLSTRING(SubCategory_Arsenal)],
    [1, 20, 5, 0],
    0
] call CBA_fnc_addSetting;

[
    QGVAR(confirmUnique),
    "CHECKBOX",
    [LLSTRING(Setting_ConfirmUnique), LLSTRING(Setting_ConfirmUnique_Desc)],
    [CBA_SETTINGS_EINV, LLSTRING(SubCategory_Arsenal)],
    true,
    0
] call CBA_fnc_addSetting;

// Each player's own choice by default - a mission can still force it for everyone.
[
    QGVAR(window),
    "LIST",
    [LLSTRING(Setting_Window), LLSTRING(Setting_Window_Desc)],
    [CBA_SETTINGS_EINV, LLSTRING(SubCategory_Arsenal)],
    [["enhanced", "ace"], [LLSTRING(Setting_Window_Enhanced), LLSTRING(Setting_Window_Ace)], 1],
    0
] call CBA_fnc_addSetting;

// ----- Vanilla Arsenal -----

// For everyone alike: the mission decides which arsenals it allows.
private _modes = ["enhanced", "block", "vanilla"];
private _labels = [LLSTRING(Setting_BIArsenal_Enhanced), LLSTRING(Setting_BIArsenal_Block), LLSTRING(Setting_BIArsenal_Vanilla)];

[
    QGVAR(biArsenal),
    "LIST",
    [LLSTRING(Setting_BIArsenal), LLSTRING(Setting_BIArsenal_Desc)],
    [CBA_SETTINGS_EINV, LLSTRING(SubCategory_Vanilla)],
    [_modes, _labels, 2],
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
