// Settings are ordered by topic, and within a topic numbers, then switches, then lists, then text boxes.
//
// What is the same for everyone (a server's or a mission's to decide) is registered with einv_main_fnc_addSetting: it
// has no row in CBA's menu but a control on the setup wizard's General page, and its value comes from the one
// text box einv_main_settings (addons/main). The variable, its name, its kind of value and its script are as they were.

// ----- Weight -----

// The master switch, first in the category: with it off the rest of the category does nothing. A server
// that wants ACE's own fatigue alone, with no tiers of ours on top, should not have to know which of the
// others to turn down. No change script either: the tier check (XEH_postInit) sees it within a second
// and takes off what the tiers had put on.
[
    QGVAR(enabled),
    "CHECKBOX",
    [LLSTRING(Setting_Enabled), LLSTRING(Setting_Enabled_Desc)],
    true
] call EFUNC(main,addSetting);

// The same for everyone: a mission decides how much its soldiers may carry. Each player's own whether to be
// told. None of them needs a change script - the tier check looks at them every second (XEH_postInit).
[
    QGVAR(heavyAt),
    "SLIDER",
    [LLSTRING(Setting_HeavyAt), LLSTRING(Setting_HeavyAt_Desc)],
    [0, 100, 0, 1]
] call EFUNC(main,addSetting);

[
    QGVAR(overloadedAt),
    "SLIDER",
    [LLSTRING(Setting_OverloadedAt), LLSTRING(Setting_OverloadedAt_Desc)],
    [10, 100, 45, 1]
] call EFUNC(main,addSetting);

[
    QGVAR(criticalAt),
    "SLIDER",
    [LLSTRING(Setting_CriticalAt), LLSTRING(Setting_CriticalAt_Desc)],
    [10, 150, 60, 1]
] call EFUNC(main,addSetting);

[
    QGVAR(effects),
    "CHECKBOX",
    [LLSTRING(Setting_Effects), LLSTRING(Setting_Effects_Desc)],
    true
] call EFUNC(main,addSetting);

// Each player's own.
[
    QGVAR(notify),
    "CHECKBOX",
    [LLSTRING(Setting_Notify), LLSTRING(Setting_Notify_Desc)],
    [CBA_SETTINGS_EINV, LLSTRING(SubCategory_Weight)],
    true,
    0
] call CBA_fnc_addSetting;
