// Settings are ordered by topic, and within a topic numbers, then switches, then lists, then text boxes.
//
// What is the same for everyone (a server's or a mission's to decide) is registered with aio_main_fnc_addSetting: it
// has no row in CBA's menu but a control on the setup wizard's General page, and its value comes from the one
// text box aio_main_settings (addons/main). The variable, its name, its kind of value and its script are as they were.

// ----- ACE Arsenal -----

// Each player's own eyes: ACE Arsenal in this mod's look - round glass panels under ACE's lists, boxes and buttons, the theme's
// words (fnc_aceSkin) - or ACE's own, as it was. Applied when the arsenal opens, at once when it is open.
[
    QGVAR(aceStyle),
    "LIST",
    [LLSTRING(Setting_AceStyle), LLSTRING(Setting_AceStyle_Desc)],
    [CBA_SETTINGS_AIO_CLIENT, LELSTRING(gui,SubCategory_General)],
    [["aio", "ace"], [LLSTRING(Setting_AceStyle_Aio), LLSTRING(Setting_AceStyle_Ace)], 0],
    0,
    {
        private _display = findDisplay ARSENAL_IDD;

        if (!isNull _display) then {
            ["apply", [_display]] call FUNC(aceSkin);
        };
    }
] call CBA_fnc_addSetting;

// ----- Vanilla Arsenal -----

// For everyone alike: the mission decides which arsenals it allows. Without ACE, "Open ACE Arsenal" is the vanilla one with grids.
private _modes = ["ace", "grid", "block", "vanilla"];
private _labels = [
    LLSTRING(Setting_BIArsenal_Ace), LLSTRING(Setting_BIArsenal_Grid), LLSTRING(Setting_BIArsenal_Block), LLSTRING(Setting_BIArsenal_Vanilla)
];

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
