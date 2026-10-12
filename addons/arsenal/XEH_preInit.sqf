#include "script_component.hpp"
#include "defines.hpp"

ADDON = false;

#include "XEH_PREP.hpp"

// ----- ACE's own window (the box action, the inventory's menu with the setting on "ACE Arsenal") -----

// What the uniform, vest or backpack open in the arsenal held at the last look, [0 uniform / 1 vest /
// 2 backpack, container, items] (fnc_rememberCargo) - so an add can tell how many really arrived, and
// a new container in the same panel shows that one was swapped. Empty while no arsenal is open or
// another panel is.
GVAR(snapshot) = [];

// ----- The Enhanced Arsenal's session -----

// The ACE functions and data this addon relies on exist (fnc_compatCheck) - false until that has looked,
// and then ACE's own window opens every time. Our window is open. The box, the unit it dresses (the copy in
// the Eden editor), whether the box's list is ignored, and where the items come from: "ace", "bi" or "eden".
GVAR(ready) = false;
GVAR(isOpen) = false;
GVAR(box) = objNull;
GVAR(center) = objNull;
GVAR(full) = false;
GVAR(source) = "ace";

// The next ACE display stays ACE's: a diag_frameNo stamp set right before openBox is called, honoured while
// diag_frameNo is at most the stamp and FORCE_ACE_FRAMES more (openBox makes its display a frame later), so
// it expires when openBox exits early instead of sending some later box to ACE's window; -1 for none. The
// panels are hidden (Backspace). Closing for the button that opens ACE's window keeps a Zeus's remote
// control.
GVAR(forceAce) = -1;
GVAR(hidden) = false;
GVAR(keepRemote) = false;

// An inventory window was closed to make room and the opening runs again a frame later (fnc_openWindow):
// set for that second run only, so a window that stays open cannot make it wait for ever.
GVAR(reopening) = false;

// What fnc_openWindow hands to fnc_onLoad: [box, unit, full, items, source].
uiNamespace setVariable [QGVAR(openArgs), []];

// The Eden editor: the entity being edited, the light under the copy, and the editor's vision mode to give
// back.
GVAR(edenOrigin) = objNull;
GVAR(edenLight) = objNull;
GVAR(edenVision) = -1;

// What the session offers, read after every handler of ace_arsenal_displayOpened ran (fnc_readSupply): the
// lowercase classes that are offered, a counter raised whenever they change, and the category lists the
// catalog reads - ACE Arsenal Extended's full copy when it is loaded, else ACE's own.
GVAR(availableLc) = createHashMap;
GVAR(availableStamp) = 0;
GVAR(catalogItems) = [];

// The camera round the soldier (fnc_cameraStart): [distance, direction, pitch, target [x, y, z]], kept for the
// mission like ACE's; the camera, its light, the rectangle the soldier is to stand in, whether the mouse
// turns it (the mouse where the last frame saw it, [] for no), how close it may come, the curator's camera
// it replaced, the player's own view to give back, and the last click in the free middle for the double
// click that resets the view ([time, mouse]). The left button moves the target point (the mouse where the
// last frame saw it, [] for no), and the vision the view shows through: 0 normal, 1 night vision, 2 thermal
// (fnc_cycleVision).
GVAR(cameraPosition) = [3, 0, 5, [0, 0, 0.9]];
GVAR(camera) = objNull;
GVAR(cameraLight) = objNull;
GVAR(cameraRect) = [];
GVAR(cameraDrag) = [];
GVAR(cameraPan) = [];
GVAR(visionMode) = 0;
GVAR(cameraMinDistance) = 0;
GVAR(curatorCameraData) = [];
GVAR(cameraView) = "";
GVAR(cameraClick) = [-1, [0, 0]];

// The catalog (fnc_catalogList): "items" or "loadouts"; the group and category shown and the category
// last shown in each group; what the parts and magazines have to fit; the sort, [id, ascending]; the row each
// category was scrolled to. Kept for the mission, as ACE keeps its tabs.
GVAR(view) = "items";
GVAR(group) = "";
GVAR(category) = "";
GVAR(lastCategory) = createHashMap;
GVAR(fits) = "";
GVAR(sort) = ["name", true];
GVAR(scrollRows) = createHashMap;

// The catalog's column, kept across builds - a control, so in uiNamespace: a HashMap with its group, its
// rectangle, the pool and its cards, the source grid, the list shown, the columns, the rows, the first row
// and the scroll it was set to.
uiNamespace setVariable [QGVAR(column), createHashMap];

// The rows of the items (fnc_catalogRow, class -> row, emptied when the rules change), the lists of the
// categories (category id -> [supply stamp, classes]) and what the soldier carries by layout key, after every
// build.
GVAR(rows) = createHashMap;
GVAR(lists) = createHashMap;
GVAR(carried) = createHashMap;

// Where double clicks and quick adds go first: the slot, the container; the first click of a two-click
// confirmation, [key, until]; the three weapons at the last build, for the parts that changed; whether a
// class is not offered here (emptied with the supply); where the last thing added landed, flashed after the
// build; the uniform and backpack at the last build, for ACE Arsenal Extended's textures.
GVAR(targetSlot) = "";
GVAR(targetContainer) = objNull;
GVAR(armed) = ["", -1];
GVAR(lastWeapons) = [];
GVAR(uniqueCache) = createHashMap;
GVAR(pendingFlash) = [];
GVAR(lastGear) = [];

// ACRE's notifications show over this window once its display is registered with ACRE (fnc_acreDisplay).
GVAR(acreRegistered) = false;

// The loadouts view: the tab, the one selected, the name typed, what has been checked (and the queue still
// to check), and whether a shared or default loadout changed since the list was drawn.
GVAR(loadoutsTab) = "mine";
GVAR(loadoutSelected) = "";
GVAR(loadoutName) = "";
GVAR(verified) = createHashMap;
GVAR(verifyQueue) = [];
GVAR(loadoutsDirty) = false;

// The vanilla Virtual Arsenal: this open goes to the vanilla window (a mission hooks it, the unit is not the
// player's); the player left it alone this time; the catalog as BI built it, to tell what a mission changed;
// and how many handlers mods had on its events when the game started (fnc_biCountHandlers), [arsenalOpened,
// arsenalPreOpen].
GVAR(biLetThrough) = false;
GVAR(biLeave) = [];
GVAR(biCatalogBase) = [];
GVAR(biModHandlers) = [0, 0];

// Checked once: ACE's pieces this addon relies on, and that BIS_fnc_arsenal is the one with our file.
call FUNC(compatCheck);
call FUNC(biInit);

// ACE's own window gets a button for the way over to this one (fnc_aceButton picks ACE's display out of the
// ones that raise the event). Registered here, not in postInit, so ACE's window in the Eden editor has it too.
[QACEGVAR(arsenal,displayOpened), {
    _this call FUNC(aceButton);
}] call CBA_fnc_addEventHandler;

#include "initSettings.inc.sqf"

ADDON = true;
