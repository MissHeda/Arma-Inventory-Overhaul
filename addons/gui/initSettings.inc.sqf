// Settings are ordered by topic, and within a topic numbers, then switches, then lists, then text boxes.
//
// What is the same for everyone (a server's or a mission's to decide) is registered with aio_main_fnc_addSetting: it
// has no row in CBA's menu but a control on the setup wizard's General page, and its value comes from the one
// text box aio_main_settings (addons/main). The variable, its name, its kind of value and its script are as they were.

// ----- General -----

// The three sizes below are also set in the window, in the size popover under its button in the header (fnc_openSizeMenu),
// which writes them here: each one's script shows a change made here in an open window and in the popover at once
// (fnc_sizeChanged), and the popover shows what CBA has.

// Each player's own eyes and screen: some find the pictures too small to make out. Read when a window
// opens (fnc_getCell); capped where the columns would not fit. A tenth above the plain size by default: at 1
// a one-cell tile shows two or three letters of an item's name.
[
    QGVAR(cellScale),
    "SLIDER",
    [LLSTRING(Setting_CellScale), LLSTRING(Setting_CellScale_Desc)],
    [CBA_SETTINGS_AIO_CLIENT, LLSTRING(SubCategory_General)],
    [CELL_SCALE_MIN, CELL_SCALE_MAX, CELL_SCALE_DEFAULT, 2],
    0,
    {[] call FUNC(sizeChanged)}
] call CBA_fnc_addSetting;

// Each player's own eyes: the window's words grow and shrink with the tiles, and this on top of that (fnc_textScale) - larger
// words on small tiles for a player who found them hard to read, smaller ones for a window that felt too big.
[
    QGVAR(textSize),
    "SLIDER",
    [LLSTRING(Setting_TextSize), LLSTRING(Setting_TextSize_Desc)],
    [CBA_SETTINGS_AIO_CLIENT, LLSTRING(SubCategory_General)],
    [TEXT_SIZE_MIN, TEXT_SIZE_MAX, TEXT_SIZE_DEFAULT, 2],
    0,
    {[] call FUNC(sizeChanged)}
] call CBA_fnc_addSetting;

// Each player's own eyes: a tall crate or vehicle of what is looted shows this many rows at a time, with a bar that turns
// the pages (fnc_pageRows, fnc_viewBlocks). 0, or MAX_ROWS (the tallest a container gets), shows the whole container as
// before. Read whenever a container is drawn.
[
    QGVAR(pageRows),
    "SLIDER",
    [LLSTRING(Setting_PageRows), LLSTRING(Setting_PageRows_Desc)],
    [CBA_SETTINGS_AIO_CLIENT, LLSTRING(SubCategory_General)],
    [0, MAX_ROWS, PAGE_ROWS_DEFAULT, 0],
    0,
    {[] call FUNC(sizeChanged)}
] call CBA_fnc_addSetting;

// Each player's own eyes.
[
    QGVAR(compareTooltip),
    "CHECKBOX",
    [LLSTRING(Setting_CompareTooltip), LLSTRING(Setting_CompareTooltip_Desc)],
    [CBA_SETTINGS_AIO_CLIENT, LLSTRING(SubCategory_General)],
    true,
    0
] call CBA_fnc_addSetting;

// Each player's own eyes: the name takes room from a small tile's picture, and the name at the mouse says it
// anyway. Read as tiles are drawn (fnc_createTile), so a change shows at the next build; off unless asked for.
[
    QGVAR(tileNames),
    "CHECKBOX",
    [LLSTRING(Setting_TileNames), LLSTRING(Setting_TileNames_Desc)],
    [CBA_SETTINGS_AIO_CLIENT, LLSTRING(SubCategory_General)],
    false,
    0
] call CBA_fnc_addSetting;

// Each player's own taste: where the loot column opens - left of their storage column, which then never moves
// (default), or at the right edge with the storage column moving in, as it did before. Read at every build
// (fnc_layoutGlass), so an open window follows at its next one.
[
    QGVAR(lootSide),
    "LIST",
    [LLSTRING(Setting_LootSide), LLSTRING(Setting_LootSide_Desc)],
    [CBA_SETTINGS_AIO_CLIENT, LLSTRING(SubCategory_General)],
    [["left", "right"], [LLSTRING(Setting_LootSide_Left), LLSTRING(Setting_LootSide_Right)], 0],
    0
] call CBA_fnc_addSetting;

// Each player's own: how long the window takes to draw, written to the RPT for a report of stutters
// (fnc_build, fnc_refresh). Read at every build and redraw.
[
    QGVAR(debugTiming),
    "CHECKBOX",
    [LLSTRING(Setting_DebugTiming), LLSTRING(Setting_DebugTiming_Desc)],
    [CBA_SETTINGS_AIO_CLIENT, LLSTRING(SubCategory_General)],
    false,
    0
] call CBA_fnc_addSetting;

// Each player's colours as text - the colour popover's own, written here whenever it closes (fnc_paletteSettle), so they can
// be copied or pasted in Configure Addons. Pasted here, they are taken (fnc_paletteImport). A server or mission that forces it
// gives everyone these colours, and the palette button goes (fnc_paletteForced, fnc_palette).
[
    QGVAR(paletteText),
    "EDITBOX",
    [LLSTRING(Setting_PaletteText), LLSTRING(Setting_PaletteText_Desc)],
    [CBA_SETTINGS_AIO_CLIENT, LLSTRING(SubCategory_General)],
    "",
    0,
    {
        params ["_text"];

        if ([] call FUNC(paletteForced)) exitWith {
            if (!isNull (uiNamespace getVariable [QGVAR(display), displayNull])) then {
                [] call FUNC(buildSoon);
            };
        };

        [_text] call FUNC(paletteImport);
    }
] call CBA_fnc_addSetting;

// ----- Sounds -----

// A player's own sound volumes are no settings here: they are set in the window, in the dropdown under the speaker
// in the header (fnc_openSoundMenu), and kept in the profile.

// For everyone alike: whether looting can be heard is part of a mission's game.
[
    QGVAR(soundsWorld),
    "CHECKBOX",
    [LLSTRING(Setting_SoundsWorld), LLSTRING(Setting_SoundsWorld_Desc)],
    true
] call EFUNC(main,addSetting);

// ----- Searching -----

// For everyone alike: a mission decides how much searching it wants.
[
    QGVAR(searchTime),
    "SLIDER",
    [LLSTRING(Setting_SearchTime), LLSTRING(Setting_SearchTime_Desc)],
    [0, 3, 0.25, 2]
] call EFUNC(main,addSetting);

// How long each kind of box takes, as a factor of the time per cell above (fnc_searchTime): 1 is that time, 2 twice as long,
// 0 shows that kind at once. A uniform's, vest's or backpack's own factor counts wherever it is - worn, on the ground, in a
// crate -, and what a body wears takes the body's factor on top of it. Read when an item comes up to be searched.
[
    QGVAR(searchTimeUniform),
    "SLIDER",
    [LLSTRING(Setting_SearchTimeUniform), LLSTRING(Setting_SearchTimeUniform_Desc)],
    [0, 5, 1, 2]
] call EFUNC(main,addSetting);

[
    QGVAR(searchTimeVest),
    "SLIDER",
    [LLSTRING(Setting_SearchTimeVest), LLSTRING(Setting_SearchTimeVest_Desc)],
    [0, 5, 1, 2]
] call EFUNC(main,addSetting);

[
    QGVAR(searchTimeBackpack),
    "SLIDER",
    [LLSTRING(Setting_SearchTimeBackpack), LLSTRING(Setting_SearchTimeBackpack_Desc)],
    [0, 5, 1, 2]
] call EFUNC(main,addSetting);

[
    QGVAR(searchTimeCrate),
    "SLIDER",
    [LLSTRING(Setting_SearchTimeCrate), LLSTRING(Setting_SearchTimeCrate_Desc)],
    [0, 5, 1, 2]
] call EFUNC(main,addSetting);

[
    QGVAR(searchTimeVehicle),
    "SLIDER",
    [LLSTRING(Setting_SearchTimeVehicle), LLSTRING(Setting_SearchTimeVehicle_Desc)],
    [0, 5, 1, 2]
] call EFUNC(main,addSetting);

[
    QGVAR(searchTimeGround),
    "SLIDER",
    [LLSTRING(Setting_SearchTimeGround), LLSTRING(Setting_SearchTimeGround_Desc)],
    [0, 5, 1, 2]
] call EFUNC(main,addSetting);

[
    QGVAR(searchTimeBody),
    "SLIDER",
    [LLSTRING(Setting_SearchTimeBody), LLSTRING(Setting_SearchTimeBody_Desc)],
    [0, 5, 1, 2]
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

// Zeus fills a crate with what the players are meant to find, and a search on top of that is often not wanted: off leaves
// the crates and vehicles the game master places out of the search. One object can be turned back on from Zeus (compat_zen).
[
    QGVAR(searchZeus),
    "CHECKBOX",
    [LLSTRING(Setting_SearchZeus), LLSTRING(Setting_SearchZeus_Desc)],
    true
] call EFUNC(main,addSetting);

[
    QGVAR(searchGround),
    "CHECKBOX",
    [LLSTRING(Setting_SearchGround), LLSTRING(Setting_SearchGround_Desc)],
    false
] call EFUNC(main,addSetting);

// Searching starts on a click on the box's Search button, as in Tarkov; off starts every box by itself, as before.
[
    QGVAR(searchOnClick),
    "CHECKBOX",
    [LLSTRING(Setting_SearchOnClick), LLSTRING(Setting_SearchOnClick_Desc)],
    true
] call EFUNC(main,addSetting);

// Each player's own: some open the window and keep walking keys under their fingers.
[
    QGVAR(moveToStop),
    "CHECKBOX",
    [LLSTRING(Setting_MoveToStop), LLSTRING(Setting_MoveToStop_Desc)],
    [CBA_SETTINGS_AIO_CLIENT, LLSTRING(SubCategory_Searching)],
    true,
    0
] call CBA_fnc_addSetting;

// ----- Item-moving queue (the wizard shows these under "Looting and searching") -----

// For everyone alike: how long the hands are busy is part of a mission's pace. In seconds, 0 is no wait at all. What waits is
// told by the switches below; each action that waits takes its turn in the window's queue (fnc_queueMoves, fnc_animateQueue).
// Read when the action is queued, so a change reaches what is queued afterwards.
[
    QGVAR(handDrop),
    "SLIDER",
    [LLSTRING(Setting_HandDrop), LLSTRING(Setting_HandDrop_Desc)],
    [0, 3, 0.3, 2]
] call EFUNC(main,addSetting);

[
    QGVAR(handMove),
    "SLIDER",
    [LLSTRING(Setting_HandMove), LLSTRING(Setting_HandMove_Desc)],
    [0, 3, 0.4, 2]
] call EFUNC(main,addSetting);

[
    QGVAR(handEquip),
    "SLIDER",
    [LLSTRING(Setting_HandEquip), LLSTRING(Setting_HandEquip_Desc)],
    [0, 5, 1, 2]
] call EFUNC(main,addSetting);

// What waits for the hands at all (fnc_queueTime). A drag out of the window never does, whatever these say. The things
// worn on the body - uniform, vest, backpack, headgear - are put on and taken off at once unless told otherwise; they
// are the ones a player does in a hurry.
[
    QGVAR(waitMove),
    "CHECKBOX",
    [LLSTRING(Setting_WaitMove), LLSTRING(Setting_WaitMove_Desc)],
    true
] call EFUNC(main,addSetting);

[
    QGVAR(waitDrop),
    "CHECKBOX",
    [LLSTRING(Setting_WaitDrop), LLSTRING(Setting_WaitDrop_Desc)],
    true
] call EFUNC(main,addSetting);

[
    QGVAR(waitWorn),
    "CHECKBOX",
    [LLSTRING(Setting_WaitWorn), LLSTRING(Setting_WaitWorn_Desc)],
    false
] call EFUNC(main,addSetting);

[
    QGVAR(waitEquip),
    "CHECKBOX",
    [LLSTRING(Setting_WaitEquip), LLSTRING(Setting_WaitEquip_Desc)],
    false
] call EFUNC(main,addSetting);

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
    [CBA_SETTINGS_AIO_CLIENT, LLSTRING(SubCategory_Nearby)],
    true,
    0
] call CBA_fnc_addSetting;

// ----- Magazines -----

// Each player's own eyes. A mission can still force it.
[
    QGVAR(magazineFillBar),
    "CHECKBOX",
    [LLSTRING(Setting_MagazineFillBar), LLSTRING(Setting_MagazineFillBar_Desc)],
    [CBA_SETTINGS_AIO_CLIENT, LLSTRING(SubCategory_Magazines)],
    true,
    0
] call CBA_fnc_addSetting;

// Each player's own eyes, as the bar: the words take room from a small tile's picture.
[
    QGVAR(magazineText),
    "CHECKBOX",
    [LLSTRING(Setting_MagazineText), LLSTRING(Setting_MagazineText_Desc)],
    [CBA_SETTINGS_AIO_CLIENT, LLSTRING(SubCategory_Magazines)],
    true,
    0
] call CBA_fnc_addSetting;

// ----- Look -----

// For everyone alike: a server or a mission may want one look for all. A player's own colours (accent, secondary colour, panels and
// their transparency, cells, tiles, text, lines) are picked in the window, in the popover under the palette button in the header
// (fnc_openPaletteMenu), and kept in the profile. Off: no palette button, and what players saved is ignored (fnc_paletteAllowed,
// fnc_palette) - everyone gets the Arma colour of their own profile and the themes' own colours. A window that is open is built
// again for it.
[
    QGVAR(playerColours),
    "CHECKBOX",
    [LLSTRING(Setting_PlayerColours), LLSTRING(Setting_PlayerColours_Desc)],
    true,
    {
        if (!isNull (uiNamespace getVariable [QGVAR(display), displayNull])) then {
            [] call FUNC(buildSoon);
        };
    }
] call EFUNC(main,addSetting);
