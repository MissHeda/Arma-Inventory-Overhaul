#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The class index the Items and Containers steps search: every weapon, item, magazine, pair of goggles,
 * backpack, crate and vehicle with a cargo space a player could look at, one row each (ROW_* in
 * defines.hpp). It is read from config in pieces of a few milliseconds (fnc_indexChunk), so the window
 * never stands still, even with tens of thousands of classes; this starts that, or picks it up again, and
 * says whether it is done.
 *
 * Kept in uiNamespace for the whole game session: classes do not change while the game runs, and nothing
 * of it should end up in a save game, which missionNamespace would be. What the rules make of a class is
 * not in it - that changes with every edit - and is asked only for the rows shown
 * (einv_items_fnc_getInfo with the draft).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * The index is complete <BOOL>
 *
 * Example:
 * call einv_setup_fnc_buildIndex;
 *
 * Public: No
 */

private _index = uiNamespace getVariable QGVAR(index);

if (isNil "_index") then {
    private _total = 0;

    {
        _total = _total + count (configFile >> _x);
    } forEach INDEX_ROOTS;

    // rows    - the rows, sorted by name once complete; byClass - the same by lowercase class
    // mods    - a mod's name by its folder, asked once each
    // root, position, read - where the reading stands, and how many config entries it has passed
    // token, tick - which run of pieces is the live one, and when it last ran
    _index = createHashMapFromArray [
        ["done", false],
        ["rows", []],
        ["byClass", createHashMap],
        ["mods", createHashMap],
        ["root", 0],
        ["position", 0],
        ["read", 0],
        ["total", _total max 1],
        ["token", 0],
        ["tick", -1]
    ];

    uiNamespace setVariable [QGVAR(index), _index];
};

if (_index get "done") exitWith {true};

// A run of pieces goes on every frame while it is busy. One that has not run for a second was dropped -
// the window closed, which empties the wizard's queue - and a new run takes over where it stopped; the
// token makes sure only one of them reads.
if (diag_tickTime - (_index get "tick") > 1) then {
    private _token = (_index get "token") + 1;

    _index set ["token", _token];
    _index set ["tick", diag_tickTime];

    [FUNC(indexChunk), [_token]] call FUNC(defer);
};

false
