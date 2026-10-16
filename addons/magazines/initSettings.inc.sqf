// Settings are ordered by topic, and within a topic numbers, then switches, then lists, then text boxes.
//
// What is the same for everyone (a server's or a mission's to decide) is registered with einv_main_fnc_addSetting: it
// has no row in CBA's menu but a control on the setup wizard's General page, and its value comes from the one
// text box einv_main_settings (addons/main). The variable, its name, its kind of value and its script are as they were.

// ----- Magazines -----

// The same for everyone: a server with a mod of its own for refilling magazines (GreenMag) switches it
// off for all. It joins the inventory's own topic (einv_gui_magazineFillBar).
[
    QGVAR(repack),
    "CHECKBOX",
    [LLSTRING(Setting_Repack), LLSTRING(Setting_Repack_Desc)],
    true
] call EFUNC(main,addSetting);
