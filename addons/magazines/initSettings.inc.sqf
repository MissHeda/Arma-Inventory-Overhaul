// Settings are ordered by topic, and within a topic numbers, then switches, then lists, then text boxes.

// ----- Magazines -----

// The same for everyone: a server with a mod of its own for refilling magazines (GreenMag) switches it
// off for all. It joins the inventory's own topic (einv_gui_magazineFillBar).
[
    QGVAR(repack),
    "CHECKBOX",
    [LLSTRING(Setting_Repack), LLSTRING(Setting_Repack_Desc)],
    [CBA_SETTINGS_EINV, LELSTRING(gui,SubCategory_Magazines)],
    true,
    1
] call CBA_fnc_addSetting;
