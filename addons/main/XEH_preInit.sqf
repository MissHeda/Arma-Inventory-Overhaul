#include "script_component.hpp"

ADDON = false;

#include "XEH_PREP.hpp"

// The settings of the mod that are the same for everyone - the server's or the mission's to decide. Each one is a
// CBA setting of its own, a row in the category "Arma Inventory Overhaul - Server" of CBA's Addon Options, and at
// the same time a control on the setup wizard's General page. Both edit the very same CBA value, so they never
// disagree: what is set in CBA's menu shows in the wizard, what the wizard saves shows in CBA's menu. Every addon
// registers its own with fnc_addSetting, in its initSettings.inc.sqf: it calls CBA_fnc_addSetting and keeps what
// the wizard needs to draw the setting.
//   serverSettings  - name (the variable's, aio_gui_searchTime) -> its definition, a HashMap
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
        "aio_gui_searchTime", "aio_gui_searchTimeUniform", "aio_gui_searchTimeVest", "aio_gui_searchTimeBackpack",
        "aio_gui_searchTimeCrate", "aio_gui_searchTimeVehicle", "aio_gui_searchTimeGround", "aio_gui_searchTimeBody",
        "aio_storage_nearbyRange", "aio_storage_stackMultiplier", "aio_gui_handDrop", "aio_gui_handMove", "aio_gui_handEquip",
        "aio_gui_waitMove", "aio_gui_waitDrop", "aio_gui_waitWorn", "aio_gui_waitEquip",
        "aio_gui_searchBodies", "aio_gui_searchPersons",
        "aio_gui_searchContainers", "aio_gui_searchZeus", "aio_gui_searchGround", "aio_gui_searchOnClick", "aio_gui_soundsWorld"
    ]],
    ["persons", ELSTRING(setup,Topic_persons), ["aio_gui_personNotify", "aio_gui_personOpen", "aio_gui_personItems", "aio_gui_personWorn"]],
    ["containers", ELSTRING(storage,SubCategory_Containers), ["aio_storage_migrate", "aio_storage_useUniform", "aio_storage_useVest", "aio_storage_useBackpack"]],
    ["weight", ELSTRING(weight,SubCategory_Weight), ["aio_weight_enabled", "aio_weight_heavyAt", "aio_weight_overloadedAt", "aio_weight_criticalAt", "aio_weight_effects"]],
    ["extras", ELSTRING(setup,Topic_extras), ["aio_hotbar_enabled", "aio_magazines_repack", "aio_locks_zeusOpens"]],
    ["arsenal", ELSTRING(setup,Topic_arsenal), ["aio_arsenal_biArsenal", "aio_arsenal_biMessage"]],
    ["look", ELSTRING(setup,Topic_look), ["aio_gui_playerColours"]],
    ["grids", ELSTRING(items,SubCategory_Grids), ["aio_items_massPerCell", "aio_items_stackSmall"]]
];

#include "initSettings.inc.sqf"

// The test builds 0.4.27 to 0.5.42 kept all these settings in one CBA text box, aio_main_settings, which is no
// setting any more. What such a box still holds - in the server's profile or file, the mission's cba_settings.sqf
// or its Eden attributes - is put into the settings of its own once, before CBA puts the values into effect
// (fnc_migrateSettings). Eden has no such moment: there it is done as the wizard or CBA's menu opens.
["CBA_beforeSettingsInitialized", {
    [] call FUNC(migrateSettings);
}] call CBA_fnc_addEventHandler;

ADDON = true;
