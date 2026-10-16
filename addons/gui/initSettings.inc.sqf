// Settings are ordered by topic, and within a topic numbers, then switches, then lists, then text boxes.
//
// What is the same for everyone (a server's or a mission's to decide) is registered with einv_main_fnc_addSetting: it
// has no row in CBA's menu but a control on the setup wizard's General page, and its value comes from the one
// text box einv_main_settings (addons/main). The variable, its name, its kind of value and its script are as they were.

// ----- General -----

// Each player's own eyes and screen: some find the pictures too small to make out. Read when a window
// opens (fnc_getCell), so a change shows at the next one; capped where the columns would not fit. A tenth
// above the plain size by default: at 1 a one-cell tile shows two or three letters of an item's name.
[
    QGVAR(cellScale),
    "SLIDER",
    [LLSTRING(Setting_CellScale), LLSTRING(Setting_CellScale_Desc)],
    [CBA_SETTINGS_EINV, LLSTRING(SubCategory_General)],
    [CELL_SCALE_MIN, CELL_SCALE_MAX, 1.1, 1],
    0
] call CBA_fnc_addSetting;

// Each player's own eyes.
[
    QGVAR(compareTooltip),
    "CHECKBOX",
    [LLSTRING(Setting_CompareTooltip), LLSTRING(Setting_CompareTooltip_Desc)],
    [CBA_SETTINGS_EINV, LLSTRING(SubCategory_General)],
    true,
    0
] call CBA_fnc_addSetting;

// Each player's own eyes: the name takes room from a small tile's picture, and the name at the mouse says it
// anyway. Read as tiles are drawn (fnc_createTile), so a change shows at the next build; off unless asked for.
[
    QGVAR(tileNames),
    "CHECKBOX",
    [LLSTRING(Setting_TileNames), LLSTRING(Setting_TileNames_Desc)],
    [CBA_SETTINGS_EINV, LLSTRING(SubCategory_General)],
    false,
    0
] call CBA_fnc_addSetting;

// Each player's own taste: the soldier from the front, as ACE Arsenal shows him, or the world as seen from
// his eyes. Read as the window opens (fnc_open); the header's button still turns it for that window.
[
    QGVAR(cameraDefault),
    "LIST",
    [LLSTRING(Setting_CameraDefault), LLSTRING(Setting_CameraDefault_Desc)],
    [CBA_SETTINGS_EINV, LLSTRING(SubCategory_General)],
    [["soldier", "off"], [LLSTRING(Setting_CameraDefault_Soldier), LLSTRING(Setting_CameraDefault_Off)], 0],
    0
] call CBA_fnc_addSetting;

// Each player's own: how long the window takes to draw, written to the RPT for a report of stutters
// (fnc_build, fnc_refresh). Read at every build and redraw.
[
    QGVAR(debugTiming),
    "CHECKBOX",
    [LLSTRING(Setting_DebugTiming), LLSTRING(Setting_DebugTiming_Desc)],
    [CBA_SETTINGS_EINV, LLSTRING(SubCategory_General)],
    false,
    0
] call CBA_fnc_addSetting;

// ----- Sounds -----

// Each player's own ears.
[
    QGVAR(soundVolume),
    "SLIDER",
    [LLSTRING(Setting_SoundVolume), LLSTRING(Setting_SoundVolume_Desc)],
    [CBA_SETTINGS_EINV, LLSTRING(SubCategory_Sounds)],
    [0, 2, 1, 0, true],
    0
] call CBA_fnc_addSetting;

[
    QGVAR(sounds),
    "CHECKBOX",
    [LLSTRING(Setting_Sounds), LLSTRING(Setting_Sounds_Desc)],
    [CBA_SETTINGS_EINV, LLSTRING(SubCategory_Sounds)],
    true,
    0
] call CBA_fnc_addSetting;

// For everyone alike: whether looting can be heard is part of a mission's game.
[
    QGVAR(soundsWorld),
    "CHECKBOX",
    [LLSTRING(Setting_SoundsWorld), LLSTRING(Setting_SoundsWorld_Desc)],
    true
] call EFUNC(main,addSetting);

// ----- Animation -----

// For everyone alike: whether others can see who loots is part of a mission's game.
[
    QGVAR(animation),
    "LIST",
    [LLSTRING(Setting_Animation), LLSTRING(Setting_Animation_Desc)],
    [[0, 1, 2], [LLSTRING(Setting_Animation_Off), LLSTRING(Setting_Animation_Looting), LLSTRING(Setting_Animation_Always)], 0]
] call EFUNC(main,addSetting);

// ----- Searching -----

// For everyone alike: a mission decides how much searching it wants.
[
    QGVAR(searchTime),
    "SLIDER",
    [LLSTRING(Setting_SearchTime), LLSTRING(Setting_SearchTime_Desc)],
    [0, 3, 0.4, 2]
] call EFUNC(main,addSetting);

[
    QGVAR(searchBodies),
    "CHECKBOX",
    [LLSTRING(Setting_SearchBodies), LLSTRING(Setting_SearchBodies_Desc)],
    true
] call EFUNC(main,addSetting);

// Living persons apart from bodies: a mission may want the dead searched, but not the comrade beside you.
[
    QGVAR(searchPersons),
    "CHECKBOX",
    [LLSTRING(Setting_SearchPersons), LLSTRING(Setting_SearchPersons_Desc)],
    true
] call EFUNC(main,addSetting);

[
    QGVAR(searchContainers),
    "CHECKBOX",
    [LLSTRING(Setting_SearchContainers), LLSTRING(Setting_SearchContainers_Desc)],
    true
] call EFUNC(main,addSetting);

[
    QGVAR(searchGround),
    "CHECKBOX",
    [LLSTRING(Setting_SearchGround), LLSTRING(Setting_SearchGround_Desc)],
    false
] call EFUNC(main,addSetting);

// Each player's own: some open the window and keep walking keys under their fingers.
[
    QGVAR(moveToStop),
    "CHECKBOX",
    [LLSTRING(Setting_MoveToStop), LLSTRING(Setting_MoveToStop_Desc)],
    [CBA_SETTINGS_EINV, LLSTRING(SubCategory_Searching)],
    true,
    0
] call CBA_fnc_addSetting;

// ----- Living persons -----

// For everyone alike: who may open whom and what they may change there is the mission's rule - asked by
// the window and again on the machine where the person is local (fnc_personGuard).
[
    QGVAR(personNotify),
    "CHECKBOX",
    [LLSTRING(Setting_PersonNotify), LLSTRING(Setting_PersonNotify_Desc)],
    true
] call EFUNC(main,addSetting);

[
    QGVAR(personOpen),
    "LIST",
    [LLSTRING(Setting_PersonOpen), LLSTRING(Setting_PersonOpen_Desc)],
    [[ACCESS_EVERYONE, ACCESS_HELPLESS, ACCESS_NONE], [LLSTRING(Option_Everyone), LLSTRING(Option_Helpless), LLSTRING(Option_Unconscious)], 0]
] call EFUNC(main,addSetting);

[
    QGVAR(personItems),
    "LIST",
    [LLSTRING(Setting_PersonItems), LLSTRING(Setting_PersonItems_Desc)],
    [[ACCESS_EVERYONE, ACCESS_HELPLESS, ACCESS_NONE], [LLSTRING(Option_Everyone), LLSTRING(Option_Helpless), LLSTRING(Option_LookOnly)], 0]
] call EFUNC(main,addSetting);

// Not on a conscious soldier by default - as with ACE's disarming, a rifle comes out of the hands of
// captives and the unconscious only.
[
    QGVAR(personWorn),
    "LIST",
    [LLSTRING(Setting_PersonWorn), LLSTRING(Setting_PersonWorn_Desc)],
    [[ACCESS_EVERYONE, ACCESS_HELPLESS, ACCESS_NONE], [LLSTRING(Option_Everyone), LLSTRING(Option_Helpless), LLSTRING(Option_Nobody)], 1]
] call EFUNC(main,addSetting);

// ----- Nearby -----

// Each player's own taste - some want to see only what they opened. A mission can still force it.
[
    QGVAR(showNearby),
    "CHECKBOX",
    [LLSTRING(Setting_ShowNearby), LLSTRING(Setting_ShowNearby_Desc)],
    [CBA_SETTINGS_EINV, LLSTRING(SubCategory_Nearby)],
    true,
    0
] call CBA_fnc_addSetting;

// ----- Magazines -----

// Each player's own eyes. A mission can still force it.
[
    QGVAR(magazineFillBar),
    "CHECKBOX",
    [LLSTRING(Setting_MagazineFillBar), LLSTRING(Setting_MagazineFillBar_Desc)],
    [CBA_SETTINGS_EINV, LLSTRING(SubCategory_Magazines)],
    true,
    0
] call CBA_fnc_addSetting;

// Each player's own eyes, as the bar: the words take room from a small tile's picture.
[
    QGVAR(magazineText),
    "CHECKBOX",
    [LLSTRING(Setting_MagazineText), LLSTRING(Setting_MagazineText_Desc)],
    [CBA_SETTINGS_EINV, LLSTRING(SubCategory_Magazines)],
    true,
    0
] call CBA_fnc_addSetting;
