#include "script_component.hpp"
#include "defines.hpp"

ADDON = false;

#include "XEH_PREP.hpp"

// The wizard's steps: id, name in the stringtable, the function that draws it. Group rules (@group > ...)
// have no step of their own: they are edited in the Review step's text, like any statement. The pills
// count from 1 (the draw functions' "Step 1, Start" is the first entry), not from the array's index.
GVAR(steps) = [
    ["start", LSTRING(Step_Start), QFUNC(drawStart)],
    ["items", LSTRING(Step_Items), QFUNC(drawItems)],
    ["containers", LSTRING(Step_Containers), QFUNC(drawContainers)],
    ["review", LSTRING(Step_Review), QFUNC(drawReview)]
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

// The setup being edited. Nothing of it reaches the game before Save:
//   origin        - the text in use when the wizard opened; originSource what the source it saves to
//                   held then, [value, priority] - someone else saving meanwhile changes that (fnc_save)
//   draft         - the text as the rules engine reads it (einv_items_fnc_parseRules), draftText the
//                   same written out again, draftRules compiled, draftCache item answers under it
//   parseWarnings - what the engine left out of the text the draft came from
//   clean         - the draft as it was last saved or loaded; anything else is a change
//   sourceEmpty   - the source it saves to holds no setup of its own yet, while clean is not the
//                   default: Save stays possible without a change (fnc_sourceEmpty)
//   undo, redo    - earlier and undone texts, the latest last
GVAR(origin) = "";
GVAR(originSource) = [];
GVAR(draft) = createHashMap;
GVAR(draftText) = "";
GVAR(draftRules) = createHashMap;
GVAR(draftCache) = createHashMap;
GVAR(parseWarnings) = [];
GVAR(clean) = "";
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

// What the steps keep between their redraws: keep the own rules when picking another preset on the
// Start step, and whether its Advanced fold is open; Review's folds - the saved drafts, the text -,
// which text it shows - 0 own, 1 full, 2 CBA line -, whether the own one is open to typing, what is
// typed into it and not yet applied and what it was given to show; the saved draft picked; the text
// pasted into the import box; the banner after someone else changed the setup; and the footer's hint,
// [text, theme colour]. And the setups the draft is compared with, read once each (fnc_changeRows).
GVAR(keepOwn) = true;
GVAR(startAdvanced) = false;
GVAR(reviewDrafts) = false;
GVAR(reviewText) = false;
GVAR(exportMode) = 0;
GVAR(textEdit) = false;
GVAR(rawText) = "";
GVAR(rawShown) = "";
GVAR(draftPick) = "";
GVAR(changeRefs) = createHashMap;
GVAR(importText) = "";
GVAR(banner) = false;
GVAR(hint) = ["", "text2"];

// The Items and Containers steps: per step ("items", "containers") the list's [search text, chip, own
// rules only, page] (fnc_drawClassList), and which typing is the last (fnc_drawResults waits for it); the
// edits not applied yet, by lowercase class - a canvas each (fnc_canvasFromBlocks; fnc_drawCellEditor,
// and fnc_drawItemEditor with the stack); how the Containers step draws - 0 Paint, 1 Blocks - and the
// colour it paints with (0 none, else 1 to PAINT_COUNT), both kept for the whole session; what the "Same
// as another class" popover shows (fnc_drawSameAs); and the own rules by class, worked out once per draft
// text (fnc_ownClassRules). The class index itself is in uiNamespace (fnc_buildIndex).
GVAR(listState) = createHashMap;
GVAR(searchToken) = 0;
GVAR(cellWork) = createHashMap;
GVAR(itemWork) = createHashMap;
GVAR(cellMode) = 0;
GVAR(cellBrush) = 1;
GVAR(sameAs) = createHashMap;
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

// On every machine, the server's included: it is the server's value that counts (fnc_canOpen).
#include "initSettings.inc.sqf"

if (hasInterface) then {
    #include "initEntryPoints.inc.sqf"

    // The setup changed - saved here, by an admin, by a mission script: an open wizard takes it in. Its
    // own redraw deletes controls, so it runs a moment later rather than inside the event.
    [QEGVAR(items,rulesChanged), {
        if (isNull (uiNamespace getVariable [QGVAR(display), displayNull])) exitWith {};

        [FUNC(onRulesChanged)] call FUNC(defer);
    }] call CBA_fnc_addEventHandler;
};

ADDON = true;
