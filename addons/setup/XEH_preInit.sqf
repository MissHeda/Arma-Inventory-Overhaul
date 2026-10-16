#include "script_component.hpp"
#include "defines.hpp"

ADDON = false;

#include "XEH_PREP.hpp"

// The wizard's steps: id, name in the stringtable, the function that draws it. Group rules (@group > ...)
// have no step of their own: they are edited as text where Export shows the setup, like any statement. The
// pills count from 1 (the draw functions' "Step 1, General" is the first entry), not from the array's index. The
// ids are what others look a page up by (the inventory's "Settings for ..." row finds "items" and "containers"):
// keep them, whatever the order.
GVAR(steps) = [
    ["general", LSTRING(Step_General), QFUNC(drawGeneral)],
    ["items", LSTRING(Step_Items), QFUNC(drawItems)],
    ["containers", LSTRING(Step_Containers), QFUNC(drawContainers)]
];

// The server settings the General step shows, by topic: [topic id (its name is Topic_<id> in the stringtable),
// [setting's name, ...] in the order they are shown]. A setting is registered by its own addon
// (einv_main_fnc_addSetting) - one whose addon is not loaded is left out here, one that is registered but named
// nowhere in this list goes under "Other" after them. Numbers come before switches, switches before lists, lists
// before text boxes within a topic - but for the master switch of the weight tiers, first of its topic.
GVAR(topics) = [
    ["looting", [
        "einv_gui_searchTime", "einv_storage_nearbyRange", "einv_gui_searchBodies", "einv_gui_searchPersons",
        "einv_gui_searchContainers", "einv_gui_searchGround", "einv_gui_soundsWorld", "einv_gui_animation"
    ]],
    ["persons", ["einv_gui_personNotify", "einv_gui_personOpen", "einv_gui_personItems", "einv_gui_personWorn"]],
    ["containers", ["einv_storage_migrate", "einv_storage_useUniform", "einv_storage_useVest", "einv_storage_useBackpack"]],
    ["weight", ["einv_weight_enabled", "einv_weight_heavyAt", "einv_weight_overloadedAt", "einv_weight_criticalAt", "einv_weight_effects"]],
    ["extras", ["einv_hotbar_enabled", "einv_magazines_repack", "einv_locks_zeusOpens"]],
    ["arsenal", ["einv_arsenal_biArsenal", "einv_arsenal_biMessage"]]
];

// How the open wizard was opened and where it may save (fnc_onLoad, fnc_canEdit):
//   mode      - "menu" from CBA's Addon Options, "direct" from everywhere else
//   target    - fnc_canEdit's answer; readOnly when it may not save at all
//   override  - save forced over the mission's own setup (priority 2), and what it was when opened
GVAR(mode) = "direct";
GVAR(target) = createHashMap;
GVAR(readOnly) = true;
GVAR(override) = false;
GVAR(cleanOverride) = false;

// The setup being edited - two texts, the rules and the server settings. Nothing of it reaches the game before
// Save:
//   origin        - the rules text in use when the wizard opened; originSource what the source it saves to
//                   held then for each of the two settings, name -> [value, priority] - someone else saving
//                   meanwhile changes that (fnc_save)
//   draft         - the text as the rules engine reads it (einv_items_fnc_parseRules), draftText the
//                   same written out again, draftRules compiled, draftCache item answers under it
//   parseWarnings - what the engine left out of the text the draft came from
//   clean         - the draft as it was last saved or loaded; anything else is a change
//   originSettings, draftSettings, draftSettingsText, cleanSettings - the same for the
//                   server settings: draftSettings holds what the text names, setting's name -> value
//                   (einv_main_fnc_parseSettings), draftSettingsText the text written out again
//   sourceEmpty   - the source it saves to holds no setup of its own yet, while clean is not the
//                   default: Save stays possible without a change (fnc_sourceEmpty)
//   undo, redo    - earlier and undone setups, [rules text, settings text], the latest last
GVAR(origin) = "";
GVAR(originSource) = createHashMap;
GVAR(draft) = createHashMap;
GVAR(draftText) = "";
GVAR(draftRules) = createHashMap;
GVAR(draftCache) = createHashMap;
GVAR(parseWarnings) = [];
GVAR(clean) = "";
GVAR(originSettings) = "";
GVAR(draftSettings) = createHashMap;
GVAR(draftSettingsText) = "";
GVAR(cleanSettings) = "";
GVAR(sourceEmpty) = false;
GVAR(undo) = [];
GVAR(redo) = [];

// The window: which step is open, a class to look at and the classes picked (the later steps), what the
// open step does with keys, and the look - the inventory's theme.
GVAR(step) = 0;
GVAR(focus) = "";
GVAR(selection) = createHashMap;
GVAR(stepKey) = {false};
GVAR(theme) = createHashMap;

// What the steps keep between their redraws: which text the Export box shows - 0 own rules, 1 full, 2 the
// line for a cba_settings.sqf -; the saved draft picked; the text pasted into the import box; the banner after
// someone else changed the setup; the footer's hint, [text, theme colour]; and what the General step keeps -
// the kind settings as stepped and not written yet, per kind: [fixed, across, down] (fnc_drawGeneral). And the
// setups the draft is compared with, read once each (fnc_changeRows), and what a class would be without its own
// rule, per draft text and class (fnc_classDefault).
GVAR(exportMode) = 2;
GVAR(draftPick) = "";
GVAR(changeRefs) = createHashMap;
GVAR(importText) = "";
GVAR(banner) = false;
GVAR(hint) = ["", "text2"];
GVAR(kindEdit) = createHashMap;
GVAR(defaultCache) = createHashMap;

// The Items and Containers steps: per step ("items", "containers") the list's [search text, chip, own
// rules only, page] (fnc_drawClassList), and which typing is the last (fnc_drawResults waits for it); the
// edits not applied yet, by lowercase class - a canvas each (fnc_canvasFromBlocks; fnc_drawCellEditor,
// and fnc_drawItemEditor with the stack); how the Containers step draws - 0 Paint, 1 Blocks - and the
// colour it paints with (0 none, else 1 to PAINT_COUNT), both kept for the whole session; what the "Same
// as another class" popover shows (fnc_drawSameAs); the picture edits of the Containers step not applied yet, by
// lowercase class (boxWork: "iconPercent", "pictureText"), and what the picture picker shows (picker); and the own rules by class, worked out once per draft
// text (fnc_ownClassRules). The class index itself is in uiNamespace (fnc_buildIndex).
GVAR(listState) = createHashMap;
GVAR(searchToken) = 0;
GVAR(cellWork) = createHashMap;
GVAR(itemWork) = createHashMap;
GVAR(cellMode) = 0;
GVAR(cellBrush) = 1;
GVAR(sameAs) = createHashMap;
GVAR(boxWork) = createHashMap;
GVAR(picker) = createHashMap;
GVAR(ownClasses) = [];

// The inheritance tree, per step: whether the list shows the tree and from which class (treeState: "on",
// "root" - a lowercase class, "" for the one picked -, "page"), and what an edit is for (editScope: "class"
// for the one picked, "tree" for it and every class built on it - fnc_editScope). The text pasted into
// the editors' import box.
GVAR(treeState) = createHashMap;
GVAR(editScope) = createHashMap;
GVAR(classImportText) = "";

// Who and what the inventory showed when the wizard was opened from it, to open it again afterwards
// (fnc_openFromGame).
GVAR(reopenInventory) = [];

if (hasInterface) then {
    #include "initEntryPoints.inc.sqf"

    // The setup changed - saved here, by an admin, by a mission script: an open wizard takes it in. Its
    // own redraw deletes controls, so it runs a moment later rather than inside the event. The rules and the
    // server settings are two settings, each one's change an event of its own.
    {
        [_x, {
            if (isNull (uiNamespace getVariable [QGVAR(display), displayNull])) exitWith {};

            [FUNC(onRulesChanged)] call FUNC(defer);
        }] call CBA_fnc_addEventHandler;
    } forEach [QEGVAR(items,rulesChanged), QEGVAR(main,settingsChanged)];
};

ADDON = true;
