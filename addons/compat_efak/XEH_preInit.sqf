#include "script_component.hpp"

ADDON = false;

#include "XEH_PREP.hpp"

// Kits open in windows of their own inside the inventory (einv_gui_fnc_drawWindows), by class, in the
// order they were opened (fnc_open). Emptied whenever the window opens anew (fnc_onWindowOpen).
GVAR(opened) = [];

// Where each open kit was found when the kit windows were last drawn, lowercase class -> [container,
// kit it is packed in] (fnc_getSections). A kit found nowhere any more is closed there.
GVAR(holders) = createHashMap;

// Each kit as it was when this window first touched it, lowercase class -> [contents, opened
// magazines]: with packing switched off, only what came out since may go back in (fnc_repackable) -
// Enhanced First Aid Kits' own rule for its kit window.
GVAR(kitStart) = createHashMap;

// Counts changes to the kits the window shows, so its signature changes with them (fnc_signature).
GVAR(stamp) = 0;

// The compartments of each kit's grid, [rules revision they were worked out for, lowercase class ->
// compartments] (fnc_kitBlocks): [] for a kit whose room is that mod's capacity. A new revision of the
// rules starts it anew.
GVAR(blocksCache) = [-1, createHashMap];

// Every change to a kit through the window is an op of the storage's transactions, run where the kit's
// root is local - the kit's authority - so every write of one kit happens on one machine, one after the
// other: the second of two players reaching for the same item finds it gone. Enhanced First Aid Kits
// sends the whole of a kit with every write, and whoever writes last wins.
EGVAR(storage,ops) set ["kitTake", QFUNC(opKitTake)];
EGVAR(storage,ops) set ["kitPut", QFUNC(opKitPut)];
EGVAR(storage,ops) set ["kitPlace", QFUNC(opKitPlace)];
EGVAR(storage,ops) set ["kitMove", QFUNC(opKitMove)];
EGVAR(storage,ops) set ["kitRemoveIfEmpty", QFUNC(opKitRemoveIfEmpty)];

// A kit as a holder of the storage, "kit:" + its lowercase class: what it holds, the compartments of its
// grid (none - an open grid that grows - while that mod's capacity is its room, fnc_kitBlocks), its root
// and whether it still lies under that root, and which of its ops take, put, place and move - settlement
// puts a payload back into a kit with its "put" op (einv_storage_fnc_settle), and the window builds a
// kit's phases from them (einv_gui_fnc_sendMoves) without naming an op of this addon. fnc_getEntries
// takes the class: that mod keeps its tables by the lowercase class, so the one in the key reads the same
// kit.
EGVAR(storage,holderTypes) set ["kit", createHashMapFromArray [
    ["entries", {
        params [["_holder", "", [""]]];

        [_holder select [4]] call FUNC(getEntries)
    }],
    ["blocks", {
        params [["_holder", "", [""]]];

        [_holder select [4]] call FUNC(kitBlocks)
    }],
    ["root", {_this call FUNC(holderRoot)}],
    ["verify", {_this call FUNC(holderVerify)}],
    ["take", "kitTake"],
    ["put", "kitPut"],
    ["place", "kitPlace"],
    ["move", "kitMove"]
]];

ADDON = true;
