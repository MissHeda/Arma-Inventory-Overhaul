// Settings are ordered by topic, and within a topic numbers, then switches, then lists, then text boxes.
//
// What is the same for everyone (a server's or a mission's to decide) is registered with einv_main_fnc_addSetting: it
// has no row in CBA's menu but a control on the setup wizard's General page, and its value comes from the one
// text box einv_main_settings (addons/main). The variable, its name, its kind of value and its script are as they were.

// ----- Grids -----

// Everything here is the same for everyone: every machine has to agree on how big an item is and how
// a container is split up, or a layout worked out on one would not fit on another.
//
// All of them feed one set of rules (fnc_compileRules). Each script asks for it to be compiled again
// (fnc_loadRules), which only happens when something it reads really changed - when the settings are
// read at the start, the first script compiles and the others find nothing to do.
//
// What wins, from the top: the tables (sizes, stacks, container sizes) - the rules text - an item's
// own mod - the preset the text builds on - the built-in fallback. See fnc_getInfo.

// Since the rules: config mass per cell when neither the rules text (cell=) nor its preset sets one.
[
    QGVAR(massPerCell),
    "SLIDER",
    [LLSTRING(Setting_MassPerCell), LLSTRING(Setting_MassPerCell_Desc)],
    [2, 20, DEFAULT_MASS_PER_CELL, 0],
    {[] call FUNC(loadRules)},
    true
] call EFUNC(main,addSetting);

// Since the rules: the preset's small items (@item_small), as long as it is moved off its default.
[
    QGVAR(stackSmall),
    "SLIDER",
    [LLSTRING(Setting_StackSmall), LLSTRING(Setting_StackSmall_Desc)],
    [1, 50, DEFAULT_STACK_SMALL, 0],
    {[] call FUNC(loadRules)},
    true
] call EFUNC(main,addSetting);

// The setup: a short text of rules on top of a preset. The third value is CBA's sanitizer, run on
// every key press in its row: a ";" would break CBA's own export and every cba_settings.sqf line
// holding the text, so it turns into a comma, and quotes, "#" and backslashes go.
[
    QGVAR(rules),
    "EDITBOX",
    [LLSTRING(Setting_Rules), LLSTRING(Setting_Rules_Desc)],
    [CBA_SETTINGS_EINV, LLSTRING(SubCategory_Grids)],
    [DEFAULT_RULES, false, FUNC(sanitizeText)],
    1,
    {[] call FUNC(loadRules)}
] call CBA_fnc_addSetting;

// The older tables by class. They still work and win over the rules text - they are read as rules
// of their own, after it.
[
    QGVAR(sizeTable),
    "EDITBOX",
    [LLSTRING(Setting_SizeTable), LLSTRING(Setting_SizeTable_Desc)],
    [CBA_SETTINGS_EINV, LLSTRING(SubCategory_Grids)],
    ["", false, FUNC(sanitizeText)],
    1,
    {[] call FUNC(loadRules)}
] call CBA_fnc_addSetting;

[
    QGVAR(stackTable),
    "EDITBOX",
    [LLSTRING(Setting_StackTable), LLSTRING(Setting_StackTable_Desc)],
    [CBA_SETTINGS_EINV, LLSTRING(SubCategory_Grids)],
    ["", false, FUNC(sanitizeText)],
    1,
    {[] call FUNC(loadRules)}
] call CBA_fnc_addSetting;
