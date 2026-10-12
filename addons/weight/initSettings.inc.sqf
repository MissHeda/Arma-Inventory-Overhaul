// Settings are ordered by topic, and within a topic numbers, then switches, then lists, then text boxes.

// ----- Weight -----

// The same for everyone: a mission decides how much its soldiers may carry. Each player's own whether to be
// told. None of them needs a change script - the tier check looks at them every second (XEH_postInit).
[
    QGVAR(heavyAt),
    "SLIDER",
    [LLSTRING(Setting_HeavyAt), LLSTRING(Setting_HeavyAt_Desc)],
    [CBA_SETTINGS_EINV, LLSTRING(SubCategory_Weight)],
    [0, 100, 0, 1],
    1
] call CBA_fnc_addSetting;

[
    QGVAR(overloadedAt),
    "SLIDER",
    [LLSTRING(Setting_OverloadedAt), LLSTRING(Setting_OverloadedAt_Desc)],
    [CBA_SETTINGS_EINV, LLSTRING(SubCategory_Weight)],
    [10, 100, 45, 1],
    1
] call CBA_fnc_addSetting;

[
    QGVAR(criticalAt),
    "SLIDER",
    [LLSTRING(Setting_CriticalAt), LLSTRING(Setting_CriticalAt_Desc)],
    [CBA_SETTINGS_EINV, LLSTRING(SubCategory_Weight)],
    [10, 150, 60, 1],
    1
] call CBA_fnc_addSetting;

[
    QGVAR(effects),
    "CHECKBOX",
    [LLSTRING(Setting_Effects), LLSTRING(Setting_Effects_Desc)],
    [CBA_SETTINGS_EINV, LLSTRING(SubCategory_Weight)],
    true,
    1
] call CBA_fnc_addSetting;

// Each player's own.
[
    QGVAR(notify),
    "CHECKBOX",
    [LLSTRING(Setting_Notify), LLSTRING(Setting_Notify_Desc)],
    [CBA_SETTINGS_EINV, LLSTRING(SubCategory_Weight)],
    true,
    0
] call CBA_fnc_addSetting;
