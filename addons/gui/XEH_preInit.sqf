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

// Until this time the vanilla inventory is let through instead of taken over - set by fnc_openVanilla,
// which asks the engine for it.
GVAR(bypassUntil) = -1;

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
//   slots    - hover areas of the dedicated slots, [[x, y, w, h] on the screen, class, caption] and,
//              optionally, its place in a scrolling group and its weapon array (see fnc_drawSlot)
//   hover    - what the mouse is on: ["tile", grid index, tile index], ["slot", slot index] or []
//   hint     - the footer's hint, which names what the mouse is on
//   theme    - the theme it was drawn with; context - what it showed (see fnc_build)
// The ones holding controls live in uiNamespace: the mission namespace is saved with the game and
// cannot hold controls - "does not support serialization" (seen in the ACE Arsenal, 2026-10-07).
uiNamespace setVariable [QGVAR(created), []];
uiNamespace setVariable [QGVAR(grids), []];
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
// kit's tile (einv_compat_efak), ["ground", -1, 0, 0, true, ""] or, while several tiles are dragged
// together, ["group", grid index, mode, kit tile index or -1, fits, why not] with the mode "keep",
// "pack", "kit" or "none" (fnc_groupMode), its plan kept in dragRoom. Its ghost and footprint are
// controls, so they live in uiNamespace (dragGhost, dragFootprint).
GVAR(press) = [];
GVAR(dragging) = false;
GVAR(dragTarget) = [];
GVAR(dragRoom) = createHashMap;
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

// A frame dragged out from an empty cell (fnc_startBand): the press, [column group, mouse, how far the
// column was scrolled in pixels, Ctrl held, side] or [], whether the frame is out, and the tiles it
// touches now - drawn as selected before it is let go. Its controls are in uiNamespace (bandFrame).
GVAR(bandPress) = [];
GVAR(band) = false;
GVAR(bandTiles) = [];
uiNamespace setVariable [QGVAR(bandFrame), []];

// The tiles dragged together while several are selected, [grid index, tile index] each, or [] for a single
// item (fnc_startDrag, fnc_updateDrag). The footprints and the pictures at the mouse are controls, so they
// live in uiNamespace (dragFootprints, dragGhosts).
GVAR(dragGroup) = [];
uiNamespace setVariable [QGVAR(dragFootprints), []];
uiNamespace setVariable [QGVAR(dragGhosts), []];

// What each section of the columns drew that a later redraw needs (fnc_drawSection): its container, the
// weight text and the button on its caption line - controls, so in uiNamespace.
uiNamespace setVariable [QGVAR(sectionInfo), []];

// How many times the window was built: a button that finds its section by its place in sectionInfo
// carries the build it was drawn in, so its click a frame later never lands on another build's section.
GVAR(buildCount) = 0;

// Loot still to be searched, [container, class, row, col, cells] in the order it is revealed, and when
// the item being searched now was started (fnc_markHidden, fnc_onFrame).
GVAR(searchQueue) = [];

// Where the window's panels are, [x, y, w, h] on the screen: a dragged item let go outside all of them
// goes on the ground (fnc_updateDrag).
GVAR(panels) = [];

// The player's equipment column of the last build, [x, y, w, h] - [] for none: anything let go over it
// goes into the slot that takes it (fnc_updateDrag).
GVAR(equipmentRect) = [];

GVAR(searchStarted) = -1;

// The item being searched as it stood in the queue, and when the next rustle plays (fnc_animateSearch).
GVAR(searchHead) = [];
GVAR(searchSoundAt) = 0;
GVAR(searchLast) = 0;

// The sounds: each item class's family, each family's actions as read from CfgEinvSounds, when each sound last
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

// The looting pose: what the window was opened on, the stance, vehicle and place the soldier had then, the pose
// itself ([unit, stance at opening, pose state, started, token, reached, re-entries] or []), a counter that tells
// one window's pose from the next, whether the pose was tried at all in this window, why the window closed
// ("move", "taken" or ""), and where the camera frames the soldier (fnc_poseStart, fnc_poseCheck, fnc_poseEnd).
GVAR(openedOn) = objNull;
GVAR(openStance) = "";
GVAR(openParent) = objNull;
GVAR(openPos) = [];
GVAR(pose) = [];
GVAR(poseToken) = 0;
GVAR(poseTried) = false;
GVAR(closeReason) = "";
GVAR(cameraRect) = [];

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

// Where the mouse was when the name beside it was last placed (fnc_onFrame).
GVAR(tooltipAt) = [];

// The inspect card: [class, count, rounds, attachments] or [], where it was last put [x, y] or [], and
// while its title is held, where the mouse holds it [dx, dy] (fnc_inspect, fnc_drawInspect, fnc_onFrame).
GVAR(inspect) = [];
GVAR(inspectPos) = [];
GVAR(inspectMove) = [];

// The kits and pouches open in floating windows of their own (einv_compat_efak, fnc_drawWindows), each
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

// The rustle while searching, muted with the speaker in the header (fnc_toggleSearchSound). Each
// player's own, kept in the profile.
GVAR(searchMuted) = profileNamespace getVariable [QGVAR(searchMuted), false];

if !(GVAR(searchMuted) isEqualType true) then {
    GVAR(searchMuted) = false;
};

// The window's moves under way, request id (einv_storage_fnc_request) -> [sources, targets, time, feels,
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
// keeps that on itself (einv_gui_normalizedAt), at most every DRIFT_REPEAT seconds.
GVAR(drift) = [];
GVAR(driftKits) = createHashMap;

// The outlines fnc_drawPending made on the cells moves are heading for - controls, so in uiNamespace.
uiNamespace setVariable [QGVAR(pendingFrames), []];

// A hint fnc_open shows once the window is up, "" for none - and whether the one saying that shared
// containers always open here in multiplayer was shown this mission (fnc_onInventoryOpened).
GVAR(openHint) = "";
GVAR(sharedHintShown) = false;

// A living person's gear changes only as the server's settings for persons allow, checked on the
// machine that runs each change (einv_storage_fnc_execute). Called by name, so a function compiled again
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
// open (fnc_cbaRun).
GVAR(menuAt) = [];

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

// The live camera on the player's soldier and its light at night (fnc_cameraStart).
GVAR(camera) = objNull;
GVAR(cameraLight) = objNull;

// What the containers held when the window was last built, in the three parts fnc_getSignature gives:
// the unit's own gear, the list of sections shown, and per loot section what it holds and where it lies.
// fnc_onFrame compares them part by part: an own or list change builds the window anew, a change in some
// loot sections only draws those again (fnc_redrawTiles).
GVAR(signatureParts) = [];

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

// The player's own choice of camera, kept in the profile across missions.

GVAR(cameraOn) = profileNamespace getVariable [QGVAR(cameraOn), true];

if !(GVAR(cameraOn) isEqualType true) then {
    GVAR(cameraOn) = true;
};

#include "initSettings.inc.sqf"

ADDON = true;
