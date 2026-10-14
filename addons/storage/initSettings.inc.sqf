// Settings are ordered by topic, and within a topic numbers, then switches, then lists, then text boxes.

// ----- Nearby -----

// The same reach for everyone: a mission decides how far a player loots without walking - and how far away
// anything may still be changed while the window is open (fnc_inReach).
[
    QGVAR(nearbyRange),
    "SLIDER",
    [LLSTRING(Setting_NearbyRange), LLSTRING(Setting_NearbyRange_Desc)],
    [CBA_SETTINGS_EINV, LELSTRING(gui,SubCategory_Nearby)],
    [1, 5, 3, 1],
    1
] call CBA_fnc_addSetting;

// ----- Containers -----

// The same for everyone: the machine that owns a unit moves its surplus, the server's AI included
// (fnc_opMigrate). A switch for a mission that wants the engine's overfilled containers left alone.
[
    QGVAR(migrate),
    "CHECKBOX",
    [LLSTRING(Setting_Migrate), LLSTRING(Setting_Migrate_Desc)],
    [CBA_SETTINGS_EINV, LLSTRING(SubCategory_Containers)],
    true,
    1
] call CBA_fnc_addSetting;

// The same for everyone, like the rules: every machine has to agree on a container's compartments, or
// a layout worked out on one would not fit on another. The older way to size containers by class -
// the items addon reads it as rules of its own, after the rules text (einv_items_fnc_compileRules),
// so it still wins over it. A ";" turns into a comma as it is typed (einv_items_fnc_sanitizeText).
[
    QGVAR(containerTable),
    "EDITBOX",
    [LLSTRING(Setting_ContainerTable), LLSTRING(Setting_ContainerTable_Desc)],
    [CBA_SETTINGS_EINV, LLSTRING(SubCategory_Containers)],
    ["", false, EFUNC(items,sanitizeText)],
    1,
    {[] call EFUNC(items,loadRules)}
] call CBA_fnc_addSetting;

// ----- Debug -----

// Each machine's own: a test switches it on where it looks - on a dedicated server through the server's
// settings - and nothing else changes. Off, every line costs one variable read.
[
    QGVAR(debugDrop),
    "CHECKBOX",
    [LLSTRING(Setting_DebugDrop), LLSTRING(Setting_DebugDrop_Desc)],
    [CBA_SETTINGS_EINV, LLSTRING(SubCategory_Debug)],
    false,
    0
] call CBA_fnc_addSetting;
