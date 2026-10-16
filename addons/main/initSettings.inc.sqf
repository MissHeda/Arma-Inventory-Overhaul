// Settings are ordered by topic, and within a topic numbers, then switches, then lists, then text boxes.

// ----- Setup -----

// All the settings that are the same for everyone, in one text box: the setup wizard's General page writes it,
// and fnc_applySettings sets the variable of each setting from it on every machine - with the same names, the
// same values and the same scripts as when each had a row of CBA's menu. They are saved the way the rules
// are, by the server, the mission or a cba_settings.sqf, forced or not; the box is for the wizard to fill, not
// for typing. The third value is the sanitizer run on every key press: a ";" would break CBA's export and every
// cba_settings.sqf line holding the text.
[
    QGVAR(settings),
    "EDITBOX",
    [LLSTRING(Setting_Settings), LLSTRING(Setting_Settings_Desc)],
    [CBA_SETTINGS_EINV, LELSTRING(items,SubCategory_Grids)],
    ["", false, FUNC(sanitizeSettings)],
    1,
    {[_this] call FUNC(applySettings)}
] call CBA_fnc_addSetting;
