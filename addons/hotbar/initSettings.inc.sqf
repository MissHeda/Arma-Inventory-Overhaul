// Settings are ordered by topic, and within a topic numbers, then switches, then lists, then text boxes.

// ----- Hotbar -----

// Each player's own taste.
[
    QGVAR(hudTime),
    "SLIDER",
    [LLSTRING(Setting_HudTime), LLSTRING(Setting_HudTime_Desc)],
    [CBA_SETTINGS_EINV, LLSTRING(SubCategory)],
    [1, 15, 4, 0],
    0
] call CBA_fnc_addSetting;

// For everyone alike: a mission decides whether the keys 4 to 0 belong to the hotbar.
[
    QGVAR(enabled),
    "CHECKBOX",
    [LLSTRING(Setting_Enabled), LLSTRING(Setting_Enabled_Desc)],
    [CBA_SETTINGS_EINV, LLSTRING(SubCategory)],
    true,
    1
] call CBA_fnc_addSetting;

// Each player's own choice: someone who leads AI soldiers all the time may prefer the hotbar's keys.
[
    QGVAR(leaderKeys),
    "CHECKBOX",
    [LLSTRING(Setting_LeaderKeys), LLSTRING(Setting_LeaderKeys_Desc)],
    [CBA_SETTINGS_EINV, LLSTRING(SubCategory)],
    true,
    0
] call CBA_fnc_addSetting;

[
    QGVAR(hudMode),
    "LIST",
    [LLSTRING(Setting_HudMode), LLSTRING(Setting_HudMode_Desc)],
    [CBA_SETTINGS_EINV, LLSTRING(SubCategory)],
    [[0, 1, 2], [LLSTRING(HudMode_Never), LLSTRING(HudMode_InUse), LLSTRING(HudMode_Always)], 1],
    0
] call CBA_fnc_addSetting;
