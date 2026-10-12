#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * What the window shows beyond the inventory's context (the "context" hook, changed in place): the storage
 * column holds the soldier's uniform, vest and backpack - a placeholder for each he lacks - then the
 * containers opened inside them, and the camera is this addon's own, not the inventory's.
 *
 * There is no loot column: the place the layout keeps for it is the catalog's, which grows on a wide screen
 * (the context's rightColumn, rightGrow and rightKeep, which fnc_layoutGlass reads). What the window
 * computed as loot - here only the containers opened inside the soldier's own, since nothing is looted and
 * nothing lies around (the inventory's nearby reading is for the inventory only) - moves into the storage
 * column after his own sections. A kit of Enhanced First Aid Kits opens in a window of its own.
 *
 * A placeholder is a section with no container and no grid: its box is the soldier's slot, so a click
 * browses the catalog for it and a drop puts one on.
 *
 * Arguments:
 * 0: The context, see einv_gui_fnc_build <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_context] call einv_arsenal_fnc_context;
 *
 * Public: No
 */

params [["_context", createHashMap, [createHashMap]]];

private _unit = _context getOrDefault ["unit", objNull];
private _own = _context getOrDefault ["ownSections", []];
private _loot = _context getOrDefault ["lootSections", []];

// Uniform, vest, backpack in that order, the real one or its empty box.
private _sections = [];

{
    private _id = _x;
    private _found = _own findIf {(_x getOrDefault ["id", ""]) isEqualTo _id};

    if (_found >= 0) then {
        _sections pushBack (_own select _found);
    } else {
        _sections pushBack createHashMapFromArray [
            ["id", _id],
            ["title", ""],
            ["class", ""],
            ["placeholder", true],
            ["owner", _unit],
            ["side", "own"]
        ];
    };
} forEach ["uniform", "vest", "backpack"];

_sections append _loot;

_context set ["storageSections", _sections];

// The loot went into the storage column; the layout keeps its right column for the catalog.
_context set ["looting", false];
_context set ["rightColumn", true];
_context set ["rightGrow", RIGHT_GROW];
_context set ["rightKeep", RIGHT_KEEP];

// The camera is the window's own (fnc_cameraStart), not the inventory's.
_context set ["cameraOn", false];
