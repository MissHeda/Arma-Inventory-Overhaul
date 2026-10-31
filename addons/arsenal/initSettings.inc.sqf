// Settings are ordered by topic, and within a topic numbers, then switches, then lists, then text boxes.
//
// What is the same for everyone (a server's or a mission's to decide) is registered with aio_main_fnc_addSetting: it
// has no row in CBA's menu but a control on the setup wizard's General page, and its value comes from the one
// text box aio_main_settings (addons/main). The variable, its name, its kind of value and its script are as they were.

// ----- Vanilla Arsenal -----

// For everyone alike: the mission decides which arsenals it allows.
private _modes = ["ace", "block", "vanilla"];
private _labels = [LLSTRING(Setting_BIArsenal_Ace), LLSTRING(Setting_BIArsenal_Block), LLSTRING(Setting_BIArsenal_Vanilla)];

[
    QGVAR(biArsenal),
    "LIST",
    [LLSTRING(Setting_BIArsenal), LLSTRING(Setting_BIArsenal_Desc)],
    [_modes, _labels, 0]
] call EFUNC(main,addSetting);

[
    QGVAR(biMessage),
    "EDITBOX",
    [LLSTRING(Setting_BIMessage), LLSTRING(Setting_BIMessage_Desc)],
    ""
] call EFUNC(main,addSetting);
