// Settings are ordered by topic, and within a topic numbers, then switches, then lists, then text boxes.

// ----- General -----

// Each player's own choice by default - a mission can still force it. In multiplayer it only decides the
// player's own gear (fnc_onInventoryOpened).
[
    QGVAR(replaceVanilla),
    "CHECKBOX",
    [LLSTRING(Setting_ReplaceVanilla), LLSTRING(Setting_ReplaceVanilla_Desc)],
    [CBA_SETTINGS_EINV, LLSTRING(SubCategory_General)],
    true,
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
    [CBA_SETTINGS_EINV, LLSTRING(SubCategory_Sounds)],
    true,
    1
] call CBA_fnc_addSetting;

// ----- Animation -----

// For everyone alike: whether others can see who loots is part of a mission's game.
[
    QGVAR(animation),
    "LIST",
    [LLSTRING(Setting_Animation), LLSTRING(Setting_Animation_Desc)],
    [CBA_SETTINGS_EINV, LLSTRING(SubCategory_Animation)],
    [[0, 1, 2], [LLSTRING(Setting_Animation_Off), LLSTRING(Setting_Animation_Looting), LLSTRING(Setting_Animation_Always)], 1],
    1
] call CBA_fnc_addSetting;

// ----- Searching -----

// For everyone alike: a mission decides how much searching it wants.
[
    QGVAR(searchTime),
    "SLIDER",
    [LLSTRING(Setting_SearchTime), LLSTRING(Setting_SearchTime_Desc)],
    [CBA_SETTINGS_EINV, LLSTRING(SubCategory_Searching)],
    [0, 3, 0.4, 2],
    1
] call CBA_fnc_addSetting;

[
    QGVAR(searchBodies),
    "CHECKBOX",
    [LLSTRING(Setting_SearchBodies), LLSTRING(Setting_SearchBodies_Desc)],
    [CBA_SETTINGS_EINV, LLSTRING(SubCategory_Searching)],
    true,
    1
] call CBA_fnc_addSetting;

// Living persons apart from bodies: a mission may want the dead searched, but not the comrade beside you.
[
    QGVAR(searchPersons),
    "CHECKBOX",
    [LLSTRING(Setting_SearchPersons), LLSTRING(Setting_SearchPersons_Desc)],
    [CBA_SETTINGS_EINV, LLSTRING(SubCategory_Searching)],
    true,
    1
] call CBA_fnc_addSetting;

[
    QGVAR(searchContainers),
    "CHECKBOX",
    [LLSTRING(Setting_SearchContainers), LLSTRING(Setting_SearchContainers_Desc)],
    [CBA_SETTINGS_EINV, LLSTRING(SubCategory_Searching)],
    true,
    1
] call CBA_fnc_addSetting;

[
    QGVAR(searchGround),
    "CHECKBOX",
    [LLSTRING(Setting_SearchGround), LLSTRING(Setting_SearchGround_Desc)],
    [CBA_SETTINGS_EINV, LLSTRING(SubCategory_Searching)],
    false,
    1
] call CBA_fnc_addSetting;

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
    [CBA_SETTINGS_EINV, LLSTRING(SubCategory_Persons)],
    true,
    1
] call CBA_fnc_addSetting;

[
    QGVAR(personOpen),
    "LIST",
    [LLSTRING(Setting_PersonOpen), LLSTRING(Setting_PersonOpen_Desc)],
    [CBA_SETTINGS_EINV, LLSTRING(SubCategory_Persons)],
    [[ACCESS_EVERYONE, ACCESS_HELPLESS, ACCESS_NONE], [LLSTRING(Option_Everyone), LLSTRING(Option_Helpless), LLSTRING(Option_Unconscious)], 0],
    1
] call CBA_fnc_addSetting;

[
    QGVAR(personItems),
    "LIST",
    [LLSTRING(Setting_PersonItems), LLSTRING(Setting_PersonItems_Desc)],
    [CBA_SETTINGS_EINV, LLSTRING(SubCategory_Persons)],
    [[ACCESS_EVERYONE, ACCESS_HELPLESS, ACCESS_NONE], [LLSTRING(Option_Everyone), LLSTRING(Option_Helpless), LLSTRING(Option_LookOnly)], 0],
    1
] call CBA_fnc_addSetting;

// Not on a conscious soldier by default - as with ACE's disarming, a rifle comes out of the hands of
// captives and the unconscious only.
[
    QGVAR(personWorn),
    "LIST",
    [LLSTRING(Setting_PersonWorn), LLSTRING(Setting_PersonWorn_Desc)],
    [CBA_SETTINGS_EINV, LLSTRING(SubCategory_Persons)],
    [[ACCESS_EVERYONE, ACCESS_HELPLESS, ACCESS_NONE], [LLSTRING(Option_Everyone), LLSTRING(Option_Helpless), LLSTRING(Option_Nobody)], 1],
    1
] call CBA_fnc_addSetting;

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
