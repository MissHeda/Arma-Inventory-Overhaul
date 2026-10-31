// Settings are ordered by topic, and within a topic numbers, then switches, then lists, then text boxes.
//
// What is the same for everyone (a server's or a mission's to decide) is registered with aio_main_fnc_addSetting: it
// has no row in CBA's menu but a control on the setup wizard's General page, and its value comes from the one
// text box aio_main_settings (addons/main). The variable, its name, its kind of value and its script are as they were.

// ----- Nearby -----

// The same reach for everyone: a mission decides how far a player loots without walking - and how far away
// anything may still be changed while the window is open (fnc_inReach).
[
    QGVAR(nearbyRange),
    "SLIDER",
    [LLSTRING(Setting_NearbyRange), LLSTRING(Setting_NearbyRange_Desc)],
    [1, 5, 3, 1]
] call EFUNC(main,addSetting);

// The same for everyone, like the layout it changes: the machine that owns a crate or a pile cuts its tiles, the
// others read them, and all of them have to agree on how big a tile can be. In a crate, a vehicle or a pile on
// the ground a class that stacks stacks this many times higher (fnc_stackFor); what is worn is not touched. 1 is off.
[
    QGVAR(stackMultiplier),
    "SLIDER",
    [LLSTRING(Setting_StackMultiplier), LLSTRING(Setting_StackMultiplier_Desc)],
    [1, 10, 5, 0]
] call EFUNC(main,addSetting);

// ----- Containers -----

// The same for everyone: the machine that owns a unit moves its surplus, the server's AI included
// (fnc_opMigrate). A switch for a mission that wants the engine's overfilled containers left alone.
[
    QGVAR(migrate),
    "CHECKBOX",
    [LLSTRING(Setting_Migrate), LLSTRING(Setting_Migrate_Desc)],
    true
] call EFUNC(main,addSetting);

// The same for everyone, like the rules: every machine has to agree on a container's compartments, or
// a layout worked out on one would not fit on another. The older way to size containers by class -
// the items addon reads it as rules of its own, after the rules text (aio_items_fnc_compileRules),
// so it still wins over it. A ";" turns into a comma as it is typed (aio_items_fnc_sanitizeText).
[
    QGVAR(containerTable),
    "EDITBOX",
    [LLSTRING(Setting_ContainerTable), LLSTRING(Setting_ContainerTable_Desc)],
    [CBA_SETTINGS_AIO_SERVER, LLSTRING(SubCategory_Containers)],
    ["", false, EFUNC(items,sanitizeText)],
    1,
    {[] call EFUNC(items,loadRules)}
] call CBA_fnc_addSetting;

// ----- Use from containers -----

// The same for everyone: what can be used from the backpack, the vest and the uniform. Everything is how the
// game works; the others make the carried gear matter - grenades and magazines in the backpack are reserve,
// not at hand. Items opt back in per container with use= (the setup wizard's "Can be used from"). The
// engine's own reload key is held to it (fnc_reloadGuard), a reload from the action menu is taken back
// (fnc_onReloaded) and the throw key is held back when only closed grenades are left (fnc_throwGuard,
// fnc_throwTick); what the hotbar, the window's menus and the padlocks on the tiles say follows fnc_useState.
// Strict (hidden) goes further: what it blocks is kept out of the container altogether, in a hidden holder on
// the unit (op "strict", fnc_opStrict), so nothing but this mod can reach it - the setting's text says what
// that may break.
#define USE_OPTIONS [[USE_ALL, USE_LIST, USE_NONE, USE_STRICT], [LLSTRING(Option_UseAll), LLSTRING(Option_UseList), LLSTRING(Option_UseNone), LLSTRING(Option_UseStrict)], 0]

[
    QGVAR(useUniform),
    "LIST",
    [LLSTRING(Setting_UseUniform), LLSTRING(Setting_UseUniform_Desc)],
    USE_OPTIONS,
    {[] call FUNC(useRefresh)}
] call EFUNC(main,addSetting);

[
    QGVAR(useVest),
    "LIST",
    [LLSTRING(Setting_UseVest), LLSTRING(Setting_UseVest_Desc)],
    USE_OPTIONS,
    {[] call FUNC(useRefresh)}
] call EFUNC(main,addSetting);

[
    QGVAR(useBackpack),
    "LIST",
    [LLSTRING(Setting_UseBackpack), LLSTRING(Setting_UseBackpack_Desc)],
    USE_OPTIONS,
    {[] call FUNC(useRefresh)}
] call EFUNC(main,addSetting);

#undef USE_OPTIONS
