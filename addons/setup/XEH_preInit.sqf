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

// The server settings the General step shows, and the topics they are under, are main's: einv_main_serverSettings
// and einv_main_topics, which CBA's menu uses for its sub-categories as well.

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
//                   held then for the rules, name -> [value, priority] - someone else saving meanwhile
//                   changes that (fnc_save)
//   draft         - the text as the rules engine reads it (einv_items_fnc_parseRules), draftText the
//                   same written out again, draftRules compiled, draftCache item answers under it
//   parseWarnings - what the engine left out of the text the draft came from
//   clean         - the draft as it was last saved or loaded; anything else is a change
//   draftSettings, draftSettingsText, cleanSettings - the same for the server settings, as one short text of the
//                   ones off their defaults (fnc_activeSettings): draftSettings holds what the text names, setting's
//                   name -> value (einv_main_fnc_parseSettings), draftSettingsText the text written out again. Clean
//                   follows every change made elsewhere at once, setting by setting (fnc_onSettingChanged); Save
//                   writes each setting whose draft differs from it
//   sourceEmpty   - the source it saves to holds no rules of its own yet, while clean is not the
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
GVAR(drawn) = 0;
GVAR(theme) = createHashMap;

// What the steps keep between their redraws: which text the Export box shows - 0 own rules, 1 full, 2 the
// line for a cba_settings.sqf -; the text pasted into the import box; the banner after
// someone else changed the setup; the footer's hint, [text, theme colour]; and what the General step keeps -
// the kind settings as stepped and not written yet, per kind: [fixed, across, down] (fnc_drawGeneral). And the
// setups the draft is compared with, read once each (fnc_changeRows), and what a class would be without its own
// rule, per draft text and class (fnc_classDefault).
GVAR(exportMode) = 2;
GVAR(changeRefs) = createHashMap;
GVAR(importText) = "";
GVAR(banner) = false;
GVAR(hint) = ["", "text2"];
GVAR(kindEdit) = createHashMap;
GVAR(defaultCache) = createHashMap;

// The Items and Containers steps: per step ("items", "containers") the list's [search text, chip, own
// rules only, page] (fnc_drawClassList), and which typing is the last (fnc_drawResults waits for it); the
// edits not applied yet, by lowercase class - a canvas each (fnc_canvasFromBlocks; fnc_drawCellEditor,
// and fnc_drawItemEditor with the stack); the compartment picked on the Paint way, by lowercase class - the places it had (cellPick,
// fnc_canvasPick); how the Containers step draws - 0 Paint, 1 Blocks - and the
// colour it paints with (0 none, else 1 to PAINT_COUNT; -1 picks a compartment by a click), both kept for the whole session; what the "Same
// as another class" popover shows (fnc_drawSameAs); the picture edits of the Containers step not applied yet, by
// lowercase class (boxWork: "iconPercent", "pictureText"), and what the picture picker shows (picker); and the own rules by class, worked out once per draft
// text (fnc_ownClassRules). The class index itself is in uiNamespace (fnc_buildIndex).
GVAR(listState) = createHashMap;
GVAR(searchToken) = 0;
GVAR(cellWork) = createHashMap;
GVAR(cellPick) = createHashMap;
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

    // The rules changed - saved here, by an admin, by a mission script: an open wizard takes them in. Its
    // own redraw deletes controls, so it runs a moment later rather than inside the event.
    [QEGVAR(items,rulesChanged), {
        if (isNull (uiNamespace getVariable [QGVAR(display), displayNull])) exitWith {};

        [FUNC(onRulesChanged)] call FUNC(defer);
    }] call CBA_fnc_addEventHandler;

    // A server setting changed - in CBA's menu, by the wizard's own Save, by an admin elsewhere, by a mission
    // script: the open wizard's row follows it (fnc_onSettingChanged). The names wait in settingsQueue, so a
    // dozen confirmed at once in CBA's menu are one redraw. CBA raises CBA_SettingChanged once its settings
    // are ready; before that - in Eden, which never gets that far - only its own refresh event, after which
    // CBA has set the variable.
    GVAR(settingsQueue) = [];

    private _fnc_queue = {
        params ["_setting"];

        if (isNull (uiNamespace getVariable [QGVAR(display), displayNull])) exitWith {};
        if !(_setting in (missionNamespace getVariable [QEGVAR(main,serverSettings), createHashMap])) exitWith {};

        if (GVAR(settingsQueue) isEqualTo []) then {
            [FUNC(onSettingChanged)] call FUNC(defer);
        };

        GVAR(settingsQueue) pushBackUnique _setting;
    };

    ["CBA_SettingChanged", {
        params [["_setting", "", [""]]];

        [_setting] call (_thisArgs select 0);
    }, [_fnc_queue]] call CBA_fnc_addEventHandlerArgs;

    ["cba_settings_refreshSetting", {
        params [["_setting", "", [""]]];

        if (!isNil "cba_settings_ready") exitWith {};

        [_setting] call (_thisArgs select 0);
    }, [_fnc_queue]] call CBA_fnc_addEventHandlerArgs;
};

ADDON = true;
