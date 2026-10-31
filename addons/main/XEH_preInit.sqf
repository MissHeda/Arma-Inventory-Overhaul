#include "script_component.hpp"

ADDON = false;

#include "XEH_PREP.hpp"

// The settings of the mod that are the same for everyone - the server's or the mission's to decide. Each one is a
// CBA setting of its own, a row in the category "Arma Inventory Overhaul - Server" of CBA's Addon Options, and at
// the same time a control on the setup wizard's General page. Both edit the very same CBA value, so they never
// disagree: what is set in CBA's menu shows in the wizard, what the wizard saves shows in CBA's menu. Every addon
// registers its own with fnc_addSetting, in its initSettings.inc.sqf: it calls CBA_fnc_addSetting and keeps what
// the wizard needs to draw the setting.
//   serverSettings  - name (the variable's, einv_gui_searchTime) -> its definition, a HashMap
//   serverKeys      - key (the name without the prefix, lowercase) -> name; the key is how the wizard's own text
//                     of the settings names one (fnc_parseSettings, fnc_writeSettings)
//   serverOrder     - the names in the order they were registered
//   retiredSettings - keys of settings the mod no longer has; a text that still names one reads clean (fnc_parseSettings)
GVAR(serverSettings) = createHashMap;
GVAR(serverKeys) = createHashMap;
GVAR(serverOrder) = [];
GVAR(retiredSettings) = ["gui_animation"];

// The topics the server settings are shown under, in the wizard and in CBA's menu alike: [id, CBA's sub-category
// (a stringtable key), [setting's name, ...]]. The wizard names a topic by its id (Topic_<id> of its stringtable)
// and shows its settings in the order given here - numbers before switches, switches before lists, lists before
// text boxes, but for the master switch of the weight tiers, first of its topic. CBA sorts its sub-categories by
// name and the settings in one by the order they were registered in. "containers" shares CBA's sub-category with
// the older container table, "grids" holds the settings the wizard draws no control for (hidden), beside the
// rules. A setting that is registered but named nowhere here goes under "Other" in both; one whose addon is not
// loaded is simply not there.
GVAR(topics) = [
    ["looting", ELSTRING(setup,Topic_looting), [
        "einv_gui_searchTime", "einv_gui_searchTimeUniform", "einv_gui_searchTimeVest", "einv_gui_searchTimeBackpack",
        "einv_gui_searchTimeCrate", "einv_gui_searchTimeVehicle", "einv_gui_searchTimeGround", "einv_gui_searchTimeBody",
        "einv_storage_nearbyRange", "einv_storage_stackMultiplier", "einv_gui_handDrop", "einv_gui_handMove", "einv_gui_handEquip",
        "einv_gui_waitMove", "einv_gui_waitDrop", "einv_gui_waitWorn", "einv_gui_waitEquip",
        "einv_gui_searchBodies", "einv_gui_searchPersons",
        "einv_gui_searchContainers", "einv_gui_searchZeus", "einv_gui_searchGround", "einv_gui_searchOnClick", "einv_gui_soundsWorld"
    ]],
    ["persons", ELSTRING(setup,Topic_persons), ["einv_gui_personNotify", "einv_gui_personOpen", "einv_gui_personItems", "einv_gui_personWorn"]],
    ["containers", ELSTRING(storage,SubCategory_Containers), ["einv_storage_migrate", "einv_storage_useUniform", "einv_storage_useVest", "einv_storage_useBackpack"]],
    ["weight", ELSTRING(weight,SubCategory_Weight), ["einv_weight_enabled", "einv_weight_heavyAt", "einv_weight_overloadedAt", "einv_weight_criticalAt", "einv_weight_effects"]],
    ["extras", ELSTRING(setup,Topic_extras), ["einv_hotbar_enabled", "einv_magazines_repack", "einv_locks_zeusOpens"]],
    ["arsenal", ELSTRING(setup,Topic_arsenal), ["einv_arsenal_biArsenal", "einv_arsenal_biMessage"]],
    ["look", ELSTRING(setup,Topic_look), ["einv_gui_playerColours"]],
    ["grids", ELSTRING(items,SubCategory_Grids), ["einv_items_massPerCell", "einv_items_stackSmall"]]
];

#include "initSettings.inc.sqf"

// The test builds 0.4.27 to 0.5.42 kept all these settings in one CBA text box, einv_main_settings, which is no
// setting any more. What such a box still holds - in the server's profile or file, the mission's cba_settings.sqf
// or its Eden attributes - is put into the settings of its own once, before CBA puts the values into effect
// (fnc_migrateSettings). Eden has no such moment: there it is done as the wizard or CBA's menu opens.
["CBA_beforeSettingsInitialized", {
    [] call FUNC(migrateSettings);
}] call CBA_fnc_addEventHandler;

ADDON = true;
