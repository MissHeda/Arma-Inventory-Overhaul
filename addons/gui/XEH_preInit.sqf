#include "script_component.hpp"
#include "defines.hpp"

ADDON = false;

#include "XEH_PREP.hpp"

// Who the window is open for and what it looks into: the containers the engine named when the
// inventory was asked for (fnc_onInventoryOpened).
GVAR(unit) = objNull;
GVAR(container) = objNull;
GVAR(secondary) = objNull;
GVAR(openedAt) = -1;

// The living person the window looks into and how - "whole" or by the "backpack", "" for none - set by
// fnc_open, watched by fnc_onFrame: a person walks off by themselves.
GVAR(person) = objNull;
GVAR(personMode) = "";

// The unit's InventoryOpened handler and the vanilla inventory that comes up behind it (fnc_initUnit,
// fnc_onInventoryOpened, fnc_guardVanilla, fnc_open): the frame the handler last answered, when it was last
// put behind the other handlers of the event, and - in uiNamespace - the vanilla inventories the guard
// closed that may still be held, [display, ...]: no window is made while one is, it would be its child.
GVAR(askedFrame) = -1e9;
GVAR(handlerAgain) = -1e9;
uiNamespace setVariable [QGVAR(closing), []];

// The open window was made on the guard's guess, not on what the engine named (fnc_guardVanilla, fnc_open): the
// engine's opening that comes after it takes its place (fnc_onInventoryOpened). And the frame an opening that was
// asked for last waited for a vanilla inventory to go: a guess made meanwhile gives way to it.
GVAR(openGuess) = false;
GVAR(openWaiting) = -1e9;

// What runs the open window's frame (fnc_onFrame): [driver, id] - "pfh", a CBA per-frame handler, or
// "draw3d", a Draw3D mission event handler (fnc_startFrame, fnc_stopFrame) - and ["", -1] while none runs.
// When it next checks whether the window should still be open, and when it next compares the contents
// with what it shows.
GVAR(frameDriver) = ["", -1];
GVAR(nextCheck) = 0;
GVAR(nextSignature) = 0;

// The hook table of a window that attaches to this one (fnc_attach), name -> CODE or flag - empty for the
// inventory itself, whose behaviour is then exactly the plain one (fnc_isInventoryMode, fnc_hook). The
// places a drag can end on that are no grid or slot, uiNamespace zones, [[rect, id], ...], are filled by
// whoever draws the area and emptied by every build (fnc_build).
GVAR(hooks) = createHashMap;
uiNamespace setVariable [QGVAR(zones), []];

// What is on the window, all of it made by fnc_build and gone with the next rebuild:
//   created  - the controls made on the display itself (a group takes its own controls with it)
//   grids    - each a HashMap (fnc_createGrid)
//   foldAreas - where a drag may let go to be laid down in a folded container's hidden rows: HashMaps "rel", "parent",
//              "size", "container" (fnc_drawSection, fnc_updateDrag)
//   pageAreas - the arrows of the page bars (fnc_drawPageBar): HashMaps "rel", "parent", "size", "grid", "step" - a dragged
//              item held over one turns the page (fnc_updateDrag)
//   slots    - hover areas of the dedicated slots, [[x, y, w, h] on the screen, class, caption] and,
//              optionally, its place in a scrolling group and its weapon array (see fnc_drawSlot)
//   hover    - what the mouse is on: ["tile", grid index, tile index], ["slot", slot index] or []
//   hint     - the footer's hint, which names what the mouse is on
//   theme    - the theme it was drawn with; context - what it showed (see fnc_build)
// The ones holding controls live in uiNamespace: the mission namespace is saved with the game and
// cannot hold controls - "does not support serialization" (seen in the ACE Arsenal, 2026-10-07).
uiNamespace setVariable [QGVAR(created), []];
uiNamespace setVariable [QGVAR(grids), []];
uiNamespace setVariable [QGVAR(foldAreas), []];
uiNamespace setVariable [QGVAR(pageAreas), []];
uiNamespace setVariable [QGVAR(slots), []];
GVAR(hover) = [];
GVAR(lastMouse) = [];
uiNamespace setVariable [QGVAR(hint), controlNull];
uiNamespace setVariable [QGVAR(hoverRing), []];
GVAR(theme) = createHashMap;
GVAR(context) = createHashMap;

// Moving items with the mouse (fnc_onMouseButton): the tile pressed on as [grid index, tile index,
// mouse position, grabbed cell [col, row] within the tile, Ctrl held] or [], whether it is being
// dragged, and where it would land or []: ["grid", grid index, col, row, fits, why not, "", place] -
// place false when the cell is taken in a kit's grid, whose layout finds it one -, ["slot", slot
// index, 0, 0, fits, why not, slot id], ["kitTile", grid index, tile index, 0, fits, why not] onto a
// kit's tile (aio_compat_efak), ["ground", -1, 0, 0, true, ""] or, while several tiles are dragged
// together, ["group", grid index, mode, kit tile index or -1, fits, why not] with the mode "keep",
// "pack", "kit" or "none" (fnc_groupMode), its plan kept in dragRoom. Its ghost and footprint are
// controls, so they live in uiNamespace (dragGhost, dragFootprint).
GVAR(press) = [];

// A window button pressed whose focus went back while it was held: [control, left button], fnc_onFrame / fnc_onMouseButton.
GVAR(pressedButton) = [];
GVAR(dragging) = false;
GVAR(dragTarget) = [];
GVAR(dragRoom) = createHashMap;

// A hotbar slot's binding being dragged (fnc_startStripDrag): [slot number, ghost control, the strip's box
// [left, top, right, bottom] or [], what the hint last said] - or [] when none is. The press that began it
// stays in GVAR(press) until it ends, so nothing is built meanwhile.
GVAR(stripDrag) = [];
GVAR(lastButton) = [];

// The button whose press stopped a repack: its release is no click (fnc_onMouseButton).
GVAR(swallowUp) = -1;

// What is held while dragging: its size as it is held, [w, h] - turned with R (fnc_rotateDrag) - and how
// many of a stack go, changed with the mouse wheel (fnc_onMouseZ) or the middle button (all of it).
GVAR(dragSize) = [1, 1];

// ... and which way round: 1 turned a quarter clockwise. Apart from the size, as a shaped item in a
// square box turns without changing it (fnc_rotateDrag).
GVAR(dragRot) = 0;
GVAR(dragCount) = 1;
GVAR(middleHeld) = false;
GVAR(lastWheel) = -1;

// The last plain click on a tile, [[grid index, tile index], time], to tell a double click.
GVAR(lastClick) = [[], -1];

// The tiles selected (fnc_select): refs [holder, key, block, col, row] - so they survive every rebuild and
// another player's rearranging -, the side they are on, "own" or "loot" ("" for none), and the one a
// Shift+click counts from, a ref or []. The controls that show it are made by fnc_drawSelection and live
// in uiNamespace (selectionFrames).
GVAR(selection) = [];
GVAR(selectionSide) = "";
GVAR(selectionAnchor) = [];
uiNamespace setVariable [QGVAR(selectionFrames), []];

// A press on an empty cell of a column (fnc_onMouseButton): [Ctrl held, mouse] or [] for none. Let go in place it
// is a click that clears the selection; dragged away it does nothing.
GVAR(emptyPress) = [];
GVAR(tipHeld) = false;

// The tiles dragged together while several are selected, [grid index, tile index] each, or [] for a single
// item (fnc_startDrag, fnc_updateDrag). The footprints and the pictures at the mouse are controls, so they
// live in uiNamespace (dragFootprints, dragGhosts).
GVAR(dragGroup) = [];
uiNamespace setVariable [QGVAR(dragFootprints), []];
uiNamespace setVariable [QGVAR(dragGhosts), []];

// The green highlights of the slots that take what is dragged: made once per build by slot number (glowCache,
// slot number -> [[box, parent], controls], fnc_glowSlot), ahead of time by fnc_warmTargets (glowNext: the next
// slot number to look at), shown by a drag (dragGlow: the controls shown, fnc_showTargets) and only hidden by
// its end (fnc_endDrag). A build empties all three along with the controls.
uiNamespace setVariable [QGVAR(glowCache), createHashMap];
uiNamespace setVariable [QGVAR(glowNext), 0];
uiNamespace setVariable [QGVAR(dragGlow), []];

// What each section of the columns drew that a later redraw needs (fnc_drawSection): its container, the
// weight text and the button on its caption line - controls, so in uiNamespace.
uiNamespace setVariable [QGVAR(sectionInfo), []];

// The pieces of the window that are drawn again on their own - the weight card and the hotbar's counts -,
// key -> [outer group, inner group, code, arguments, position] (fnc_drawPart, fnc_redrawPart): controls, so
// in uiNamespace, emptied by every build.
uiNamespace setVariable [QGVAR(parts), createHashMap];

// How many times the window was built: a button that finds its section by its place in sectionInfo
// carries the build it was drawn in, so its click a frame later never lands on another build's section.
GVAR(buildCount) = 0;

// Loot still to be searched, [container, class, row, col, cells, compartment] in the order it is revealed, box after box,
// each box's seal (class "") before its items (fnc_markHidden, fnc_onFrame).
GVAR(searchQueue) = [];

// Where the window's panels are, [x, y, w, h] on the screen: a dragged item let go outside all of them
// goes on the ground (fnc_updateDrag).
GVAR(panels) = [];

// The player's equipment column of the last build, [x, y, w, h] - [] for none: anything let go over it
// goes into the slot that takes it (fnc_updateDrag).
GVAR(equipmentRect) = [];

// The unit's storage column of the last build, [x, y, w, h] - [] for none (fnc_drawColumn): a uniform,
// vest or backpack let go on it off its grids is put on; while the unit wears none of them, anything else
// let go there is refused (fnc_updateDrag).
GVAR(storageRect) = [];
GVAR(lootRect) = [];

// The boxes searched now, side by side (fnc_animateSearch): one run per box that has something queued and is not stopped,
// [container, the entry being searched as it stood in the queue, when it was started, how long it takes]. searchDirty: the
// queue or the stopped boxes changed, so the runs are matched with them again in the next frame; searchSynced is the queue
// they were matched with (a build or a find puts a new one in its place). searchStarted is -1 while no box searches, else
// the frame of the last step (fnc_onFrame asks it). When the next rustle plays, and the last frame of searching.
GVAR(searchRuns) = [];
// The marks on the tiles being searched (fnc_searchMarks).
GVAR(searchMarks) = [];
GVAR(searchDirty) = false;
GVAR(searchSynced) = [];
GVAR(searchStarted) = -1;
GVAR(searchSoundAt) = 0;
GVAR(searchLast) = 0;

// What this player knows of the containers that move about (fnc_searchRecord): the id a uniform, vest or backpack carries
// (aio_storage_searchState) -> [["known", class -> count], ["unsealed", true]]. Kept for the whole mission and never
// broadcast, so a body's backpack this player searched stays searched on the ground, in a crate or on another body.
GVAR(searchMemory) = createHashMap;

// The sealed block a drag is held over (fnc_animateStatus): its seal info while it shows "Search it first".
GVAR(sealDragOver) = createHashMap;

// The boxes whose search the player stopped (the button in the caption line, fnc_stopStatus): their containers. Nothing of
// them is searched until the button says "Search" again; the window's own state, empty for every window.
GVAR(searchPaused) = [];

// With "Search starts on click" (aio_gui_searchOnClick): the boxes that wait for the click, and the boxes the window has met
// (so a rebuild does not make a searched or stopped box wait again). The window's own state.
GVAR(searchIdle) = [];
GVAR(searchSeen) = [];

// The hands' queue (fnc_queueMoves): the actions waiting for the hands, in order, each a HashMap - "id", "move" (the
// move fnc_sendMoves was given), "options", "hand" ("drop", "move" or "equip"), "time" (seconds), "sources" (the tiles it
// takes from, as the moves in flight name them), "slot" ([unit, slot] of a worn item it takes off), "box" (the container
// whose caption line says it, objNull for none), "fx" (the one control that marks a worn item's slot, made by fnc_drawQueue)
// and what fnc_drawQueue keeps to tell whether its marks are still good: "tiles" ([[grid, tile], ...] it marked), "marks"
// (those tiles' surfaces) and "slotAt". Only the first runs; handStarted is when it began (-1: not yet), handLast the last
// frame of the queue, handId counts the entries made. queueDirty: entries were queued or cancelled, so the marks are brought
// up to date in the next frame (fnc_animateQueue), once - queueFrom is the first place in the queue that needs it (entries
// added at the end leave the ones before them alone). handWaiting is the queue's sources by cell, "col_row" ->
// [[holder, key, block], ...] (fnc_queueIndex): asking whether a tile waits is one look, however long the queue is. "hint" on an
// entry is the tile it was queued for (fnc_queueTiles). roomCache is the room each target container has for the quick move
// key (fnc_roomFor), one entry per container.
// handBoxes is what the caption lines say: one HashMap per box that has something waiting - "holder", "verb" ("grab", "put", "drop"
// or "move"), "total" and "done" of the entries of this run (fnc_queueMoves adds, fnc_runQueue and fnc_cancelQueued count). A
// box is dropped from it once nothing of it waits. instantFrame is the frame a drag let go in: what the drag sends goes at once
// (fnc_endDrag, fnc_queueTime).
GVAR(handQueue) = [];
GVAR(handStarted) = -1;
GVAR(handLast) = 0;
GVAR(handId) = 0;
GVAR(queueDirty) = false;
GVAR(queueFrom) = 0;
GVAR(handWaiting) = createHashMap;
GVAR(handBoxes) = [];
GVAR(instantFrame) = -1;
GVAR(roomCache) = [];
GVAR(quickHeldKey) = -1;

// The sounds: each item class's family, each family's actions as read from CfgAioSounds, when each sound last
// played and which variant, the files found for config paths, the weapons' reload sounds, the ground under the
// player, when others may next hear a sound and a search tick, and the reload sound playing now (fnc_playSound).
GVAR(soundFamilies) = createHashMap;
GVAR(soundDefs) = createHashMap;
GVAR(soundLast) = createHashMap;
GVAR(soundFiles) = createHashMap;
GVAR(reloadSounds) = createHashMap;
GVAR(surfaceCache) = [];
GVAR(noiseNext) = 0;
GVAR(noiseSearchNext) = 0;
GVAR(reloadSoundId) = -1;

// What the window was opened on, the vehicle and place the soldier had then (fnc_checkTaken), why the window
// closed ("move", "taken" or "").
GVAR(openedOn) = objNull;
GVAR(openParent) = objNull;
GVAR(openPos) = [];
GVAR(closeReason) = "";

// Moving stops looting: DIK code -> movement action, and the actions held already when the window opened
// (fnc_open, fnc_onKeyDown).
GVAR(moveKeys) = createHashMap;
GVAR(moveHeld) = [];

// Uniforms, vests and backpacks lying in a container that are open in the loot column, as [class,
// container object, container it lies in] (fnc_openNested); fnc_build adds its key there, the key of the
// container it lies in when that one is open too, and when it went missing - an object the engine made
// anew is found again by its key.
GVAR(opened) = [];

// The search field: what is typed, and whether it had the cursor when the window was built again
// (fnc_drawFilter, fnc_applyFilter).
GVAR(filter) = "";
GVAR(filterFocus) = false;

// The category chosen at the side of a loot box (fnc_drawGroupStrip, fnc_setGroup): [[container, group], ...], one pair per
// box that has one - the id of a category, one of ITEM_GROUPS or one the setup defines; a box with none shows everything. It fades
// the tiles of its box that are not of the category as the search field does (fnc_applyFilter).
GVAR(groupFilters) = [];
// Which group of categories the strip of a box shows when there are more than its fields hold (fnc_stripMore): [[container, page], ...].
GVAR(stripPages) = [];
// Whether the caption lines hold a chip that moves every frame (fnc_updateStatus, fnc_animateStatus), and the last whole
// second of the search's time it said.
GVAR(statusLive) = false;
GVAR(statusSecond) = -1;

// Where the mouse was when the name beside it was last placed (fnc_onFrame).
GVAR(tooltipAt) = [];

// The inspect card: [class, count, rounds, attachments] or [], where it was last put [x, y] or [], and
// while its title is held, where the mouse holds it [dx, dy] (fnc_inspect, fnc_drawInspect, fnc_onFrame).
GVAR(inspect) = [];
GVAR(inspectPos) = [];
GVAR(inspectMove) = [];

// Its picture box in 2D or 3D ("2d", "3d" - kept in the profile), the 3D view's scene, where the mouse was while it turns the
// item [x, y] or [], the frame the wheel last zoomed in, and per class whether there is a model to show
// (fnc_drawInspect, fnc_inspect3D, fnc_onFrame, fnc_hasModel).
GVAR(inspectView) = profileNamespace getVariable [QGVAR(inspectView), "2d"];
GVAR(scene3D) = createHashMap;
GVAR(inspect3DTurn) = [];
GVAR(lastWheel3D) = -1;
GVAR(hasModel) = createHashMap;

// The kits and pouches open in floating windows of their own (aio_compat_efak, fnc_drawWindows), each
// known by its key: the order they lie in, bottom first - the last one is on top -, where each was put
// [x, y], the tile one was opened from [x, y, w, h] - only its first draw places it by that -, which ones
// fade in at their next draw, how far down each one's body was scrolled, in screen height, and while a
// title is held [key, dx, dy] (fnc_onFrame moves it). The free middle of the last build, [x, y, w, h] or
// [], is where a window likes to open (fnc_placeWindow). The windows' records hold controls, so they live
// in uiNamespace (windows), with the window groups that went and are deleted on the next frame
// (windowTrash) and the scroll positions put back a frame after their groups were made (scrollRestore,
// [group, pixels, frame]).
GVAR(windowOrder) = [];
GVAR(windowPos) = createHashMap;
GVAR(windowAnchor) = createHashMap;
GVAR(windowFresh) = [];
GVAR(windowScroll) = createHashMap;
GVAR(windowMove) = [];
GVAR(middle) = [];
uiNamespace setVariable [QGVAR(windows), []];
uiNamespace setVariable [QGVAR(windowTrash), []];
uiNamespace setVariable [QGVAR(scrollRestore), []];

// Sections folded away to their caption, by container (fnc_toggleSection), for the whole mission.
GVAR(collapsed) = [];

// Tall compartments whose empty rows the player opened (fnc_viewBlocks, fnc_toggleRows), by holder, for
// the whole mission.
GVAR(expanded) = [];

// The page each tall compartment of what is looted is turned to, [[holder, compartment, page], ...], for the whole
// mission (fnc_pageOf, fnc_viewBlocks), and the pages a search moved, [[holder, compartment, page it was on], ...],
// given back when the search is emptied (fnc_applyFilter). pageHover is what a dragged item is held over: [which
// arrow, since when] (fnc_updateDrag).
GVAR(pages) = [];
GVAR(pagesMoved) = [];
GVAR(pageHover) = [];
// The page a fast run of clicks on a bar has asked for so far, by container and compartment (fnc_pageSoon).
GVAR(pageWanted) = createHashMap;

// What a click asked for that is heavy to do and is run at most once per rest (fnc_coalesce): by key, [code, arguments, when it
// is due or -1, when the key rests until, its gap]. Emptied with every window (fnc_attach, fnc_onUnload).
GVAR(coalesced) = createHashMap;

// The window's sounds, set in the dropdown under the speaker in the header (fnc_openSoundMenu): one volume per kind
// of sound (GVAR(soundGroups), fnc_soundGroup), 0 to 1. Each level is
// [volume, the volume to come back to when its switch is turned on again]; a kind at volume 0 is off. Each player's
// own, kept in the profile when the dropdown closes (fnc_soundSettle). The speaker used to mute with one flag,
// aio_gui_muted (aio_gui_searchMuted before that): a player who had it set starts with every kind off.
GVAR(soundGroups) = ["moves", "magazines", "containers", "search", "other"];
GVAR(soundLevels) = GVAR(soundGroups) apply {[1, 1]};
GVAR(soundDirty) = false;

private _savedMix = profileNamespace getVariable [QGVAR(soundMix), []];

if (
    _savedMix isEqualType [] && {count _savedMix == 2} && {(_savedMix select 0) isEqualType 0}
    && {(_savedMix select 1) isEqualType []} && {count (_savedMix select 1) == count GVAR(soundGroups)}
) then {
    // The first number was a master volume (the dropdown has none now): worked into the levels, so a player who had
    // set one still hears what he set. At 0 it silences the kinds but leaves what they come back to.
    private _master = ((_savedMix select 0) max 0) min 1;

    GVAR(soundLevels) = (_savedMix select 1) apply {
        _x params [["_volume", 1, [0]], ["_last", 1, [0]]];

        [((_volume max 0) min 1) * _master, ((_last max 0) min 1) * ([_master, 1] select (_master <= 0))]
    };
} else {
    private _wasMuted = profileNamespace getVariable [QGVAR(muted), profileNamespace getVariable [QGVAR(searchMuted), false]];

    if (_wasMuted isEqualTo true) then {
        GVAR(soundLevels) = GVAR(soundGroups) apply {[0, 1]};
    };
};

// The order the Sort buttons lay a container out by (fnc_sortHolder, one of SORT_MODES): the one the last
// click chose, each player's own, kept in the profile. The Sort buttons drawn on the window with their label
// and hit area, to show it as it changes (fnc_sortButtons).
GVAR(sortMode) = profileNamespace getVariable [QGVAR(sortMode), SORT_DEFAULT];

if !(GVAR(sortMode) isEqualType "" && {GVAR(sortMode) in SORT_MODES}) then {
    GVAR(sortMode) = SORT_DEFAULT;
};

uiNamespace setVariable [QGVAR(sortButtons), []];

// The window's moves under way, request id (aio_storage_fnc_request) -> [sources, targets, time, feels,
// details] (fnc_sendMoves): sources [[holder, key, block, col, row], ...] are faded and cannot be lifted,
// targets [[holder, block, col, row, w, h], ...] outlined (fnc_drawPending) until the answer is finished;
// time is when it was sent (PENDING_TIMEOUT); feels - how each move sounds - and details - what a hint
// needs to say about each move - one per move in the order of the moves, [] where nothing fills them in.
GVAR(inFlight) = createHashMap;

// Answers that came and are not finished yet, [id, summary, revisions, args, arrived at] each
// (fnc_onAnswer): fnc_onFrame finishes one once this machine reads every revision it names - so a tile
// never shows on its first-fit cell for a frame because the cargo arrived before its place - or
// ANSWER_WAIT seconds after it arrived.
GVAR(answers) = [];

// Holders drawn with places that disagree with their cargo, [holder, root, since] each - holder an
// object or a kit's key - noted by fnc_drawSection, reported to their authority once they drifted for
// DRIFT_WAIT seconds (fnc_requestNormalize). When a kit was last reported, kit key -> time; an object
// keeps that on itself (aio_gui_normalizedAt), at most every DRIFT_REPEAT seconds.
GVAR(drift) = [];
GVAR(driftKits) = createHashMap;

// The outlines fnc_drawPending made on the cells moves are heading for - controls, so in uiNamespace.
uiNamespace setVariable [QGVAR(pendingFrames), []];

// A living person's gear changes only as the server's settings for persons allow, checked on the
// machine that runs each change (aio_storage_fnc_execute). Called by name, so a function compiled again
// while testing is the one asked.
EGVAR(storage,guards) pushBack {_this call FUNC(personGuard)};

// The CBA item context menu's slot for each of this window's slots (fnc_cbaSlotTarget) - CBA's names,
// as its own hooks into the vanilla inventory give them (cba_ui_fnc_initDisplayInventory). Parts with
// no slot there - a launcher's or handgun's second magazine, a binocular's battery - are left out.
GVAR(cbaSlots) = createHashMapFromArray [
    ["primary", "RIFLE"], ["primary_muzzle", "RIFLE_SILENCER"], ["primary_rail", "RIFLE_POINTER"],
    ["primary_optic", "RIFLE_OPTIC"], ["primary_bipod", "RIFLE_BIPOD"], ["primary_mag", "RIFLE_MAGAZINE"],
    ["primary_mag2", "RIFLE_MAGAZINE_GL"],
    ["launcher", "LAUNCHER"], ["launcher_muzzle", "LAUNCHER_SILENCER"], ["launcher_rail", "LAUNCHER_POINTER"],
    ["launcher_optic", "LAUNCHER_OPTIC"], ["launcher_bipod", "LAUNCHER_BIPOD"], ["launcher_mag", "LAUNCHER_MAGAZINE"],
    ["handgun", "PISTOL"], ["handgun_muzzle", "PISTOL_SILENCER"], ["handgun_rail", "PISTOL_POINTER"],
    ["handgun_optic", "PISTOL_OPTIC"], ["handgun_bipod", "PISTOL_BIPOD"], ["handgun_mag", "PISTOL_MAGAZINE"],
    ["binocular", "BINOCULAR"], ["uniform", "UNIFORM"], ["vest", "VEST"], ["backpack", "BACKPACK"],
    ["headgear", "HEADGEAR"], ["goggles", "GOGGLES"], ["nvg", "HMD"],
    ["map", "MAP"], ["gps", "GPS"], ["radio", "RADIO"], ["compass", "COMPASS"], ["watch", "WATCH"]
];

// Where the context menu was opened, to open it there again when a choice of another mod asks to stay
// open (fnc_cbaRun); what the mouse was on then (GVAR(hover)'s form - fnc_redrawTiles closes a menu of a
// tile it draws anew); and the open menu's choices and place [choices, [x, y]] or [], to make it again on
// top (fnc_openMenu, fnc_raiseMenu). Its layer, where it lies and the field that had the focus before live
// in uiNamespace (menu, menuRect, menuFocusBack).
GVAR(menuAt) = [];
GVAR(menuFor) = [];
GVAR(menuState) = [];

// Another window lies over this one - a dialog a choice of another mod opened, or Enhanced First Aid
// Kits' own (fnc_isCovered). The window keeps still meanwhile (fnc_onFrame).
GVAR(covered) = false;

// What the engine's own inventory actions look like (CfgActions Gear and OpenBag), so the person action
// (fnc_addPersonAction) reads exactly like them in every language: "Inventory" with the gear icon,
// "Open %1" for a backpack - and shows in the middle of the screen only as the backpack action does,
// which ACE switches off. A config text may still be a $STR reference.
private _fnc_text = {
    params ["_entry", "_fallback"];

    private _text = getText _entry;

    if ((_text select [0, 1]) isEqualTo "$") then {
        _text = localize (_text select [1]);
    };

    [_text, localize _fallback] select (_text isEqualTo "")
};

GVAR(gearText) = [configFile >> "CfgActions" >> "Gear" >> "text", "STR_ACTION_GEAR"] call _fnc_text;
GVAR(gearIcon) = getText (configFile >> "CfgActions" >> "Gear" >> "textDefault");
GVAR(gearPriority) = getNumber (configFile >> "CfgActions" >> "Gear" >> "priority");
GVAR(openBagText) = [configFile >> "CfgActions" >> "OpenBag" >> "text", "STR_ACTION_OPEN_BAG"] call _fnc_text;
GVAR(openBagWindow) = getNumber (configFile >> "CfgActions" >> "OpenBag" >> "showWindow") == 1;

// ACE medical gives the unconscious an "Inventory" of its own (fnc_personActionCondition).
GVAR(aceInventoryAction) = isClass (configFile >> "CfgPatches" >> "ace_medical_status");

// The agent the person action for agents last found under the crosshair - the one it opens
// (fnc_agentActionCondition, fnc_addAgentAction).
GVAR(actionAgent) = objNull;

// What the containers held when the window was last drawn, in the five parts fnc_getSignature gives:
// the unit's own gear, the list of sections shown, per loot and per storage section what it holds and
// where it lies, and what else the weight card shows. fnc_refresh compares them part by part: an own or
// list change builds the window anew, a change in some sections only draws those again (fnc_redrawTiles),
// with the weight card and the hotbar when they are the unit's own (fnc_redrawPart).
GVAR(signatureParts) = [];

// "Log window timings (debug)" (aio_gui_debugTiming), nothing of it read while the setting is off:
//   redrawCounts - the last redraw of tiles: [tiles kept, tiles made, its milliseconds] (fnc_redrawTiles,
//                  written in the redraw's line by fnc_refresh)
//   phase        - [part of the frame now running, when it began] while fnc_frame times a frame, nil
//                  otherwise: fnc_onFrame says where each part begins (fnc_notePhase)
//   phaseTally   - per part of the frame [milliseconds in all, most in one frame], and "frame" the whole
//                  frames from one to the next, written by fnc_logFrame with the frames' line
//   frameLast    - when the last timed frame began, -1 before the window's first (fnc_startFrame)
GVAR(redrawCounts) = [0, 0, 0];
GVAR(phaseTally) = createHashMap;
GVAR(frameLast) = -1;

// Weight (fnc_drawSection, fnc_previewWeight, fnc_drawCompare), all made by the build and gone with the next one:
//   infoAreas  - [[x, y, w, h], "", "", anchor, kind, args] where the hint has something to say that is
//                no tile and no slot: the weight card and the section captions (fnc_updateHover)
//   weightBar  - the weight card's bar: HashMap parent, rect, load, limits, unit (fnc_drawEquipmentCards)
//   compare    - the comparison card at the mouse, or controlNull; tipShown - whichever of it and the name is
//                on show, with its width and height (fnc_updateHover, fnc_onFrame)
//   weightPreview - the added weight on the weight card while something is dragged
uiNamespace setVariable [QGVAR(infoAreas), []];
uiNamespace setVariable [QGVAR(weightBar), createHashMap];
uiNamespace setVariable [QGVAR(compare), controlNull];
uiNamespace setVariable [QGVAR(tipShown), controlNull];
uiNamespace setVariable [QGVAR(weightPreview), controlNull];

// What the hint says about the keys while something is dragged, [[text, colour key], ...], and what it shows
// now (fnc_startDrag, fnc_dragHint).
GVAR(dragKeys) = [];
GVAR(dragHintShown) = [];

// What lies around the unit and shows as boxes of its own in the loot column, read by fnc_readNearby -
// objects, nearest first. Stays [] with the switch off and in the other windows that attach to this one
// (fnc_isInventoryMode).
GVAR(nearby) = [];

// The look: id, name, theme function, layout function. One since 2026-10-08 - Enhanced First Aid Kits'
// glass with every attachment slot in view; Wardogs, Reforger and Tarkov looks were tried and dropped. Kept as a list so fnc_build stays the same should another look ever come back.
GVAR(styles) = [
    ["main", LSTRING(Title), QFUNC(theme), QFUNC(layoutGlass)]
];
GVAR(style) = "main";

// The player's colours, picked in the popover under the header's palette button (fnc_openPaletteMenu): [accent, secondary, alpha,
// panel, cells, tiles, text, lines, tile alpha] (fnc_palette) - each colour [hue, saturation, value] (0 to 1) or [] for none, the
// panels' alpha and the tiles' alpha PALETTE_ALPHA_MIN to 1 or -1 for none. Each player's own, kept in the profile as
// aio_gui_palette when the popover closes (fnc_paletteSettle); whether the themes use it is the server's to say
// (aio_gui_playerColours, fnc_paletteAllowed).
// Anything in the profile that is not that shape is no choice; what the first version of the palette saved - three entries, a
// colour as [hue, vividness] - still reads (value 1), and so does a palette of four entries from before the cells, tiles, text and
// lines rows (those unset) and a palette of eight entries from before the tiles' own transparency (that one unset). An alpha beyond
// the range is cut to it, and the value of the panels, the cells and the tiles is cut at PALETTE_PANEL_VALUE_MAX as fnc_paletteSet
// cuts it. aio_gui_paletteDirty says there is something to write, and aio_gui_menuRemake that the menu being closed is only
// made again (fnc_closeMenu).
GVAR(palette) = +PALETTE_DEFAULT;
GVAR(paletteDirty) = false;
GVAR(menuRemake) = false;

// What the profile holds, read as fnc_paletteRead reads any palette: nothing usable keeps the window as it ships.
private _savedPalette = [profileNamespace getVariable [QGVAR(palette), []]] call FUNC(paletteRead);

if (_savedPalette isNotEqualTo []) then {
    GVAR(palette) = _savedPalette;
};

#include "initSettings.inc.sqf"

ADDON = true;
