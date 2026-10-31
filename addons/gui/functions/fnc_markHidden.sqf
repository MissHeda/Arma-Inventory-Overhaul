#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Marks the loot this player has not searched yet as hidden (hatched tiles, fnc_createTile) and queues it
 * for searching as [container, class, row, col, cells, compartment] - fnc_animateSearch reveals it,
 * one item after another, compartment after compartment, top left first, each box with its own clock.
 *
 * What a player knows is counted per container and class (fnc_searchRecord "known"), not broadcast - every
 * player searches for themselves: the n-th entry of a class is known while n is below the count.
 * Searching raises the count, and so does putting something in (fnc_afterAction) - what you put in you
 * know; taking something out lowers it again.
 *
 * The n-th is counted in the arrangement's order - compartment, row, column -, not in the order the
 * engine lists the cargo: every machine lays the same places out the same way, so the ones a player has
 * revealed are the same top-left ones in everyone's view of that container.
 *
 * A sealed box (fnc_isSealed) queues its seal alone, [container, "", 0, 0, SEAL_CELLS, SEAL_BLOCK]: nothing of what it
 * holds is shown or timed until the seal is done and the window is built with its real grid, which queues the items.
 *
 * Never for the player's own uniform, vest and backpack, nor where the settings or the mission
 * (aio_noSearch on the object) say not to.
 *
 * Arguments:
 * 0: Container <OBJECT>
 * 1: Entries, as fnc_getLayout placed them <ARRAY>
 * 2: Queue the hidden ones for searching - off to only learn which are hidden <BOOL> (default: true)
 * 3: Sealed (fnc_isSealed): with the queue, the seal instead of the items - also for a container that holds nothing <BOOL>
 *    (default: false)
 *
 * Return Value:
 * None
 *
 * Example:
 * [_box, _entries] call aio_gui_fnc_markHidden;
 *
 * Public: No
 */

params ["_container", "_entries", ["_queue", true, [true]], ["_seal", false, [true]]];

if !([_container] call FUNC(isSearched)) exitWith {};

// A box the window meets for the first time waits for the click on its Search button (fnc_stopStatus).
private _fnc_wait = {
    if (GVAR(searchOnClick) && {!(_container in GVAR(searchSeen))}) then {
        GVAR(searchSeen) pushBack _container;
        GVAR(searchIdle) pushBack _container;
        GVAR(searchPaused) pushBackUnique _container;
    };

    // The boxes that search are matched with the queue again in the next frame (fnc_animateSearch).
    GVAR(searchDirty) = true;
};

private _known = ([_container] call FUNC(searchRecord)) getOrDefault ["known", createHashMap];
private _seen = createHashMap;

// [compartment, row, column, index]: sorted by where it lies, then back to the entry by its index.
private _order = [];

{
    _order pushBack [_x getOrDefault ["block", 0], _x getOrDefault ["row", 0], _x getOrDefault ["col", 0], _forEachIndex];
} forEach _entries;

_order sort true;

{
    private _entry = _entries select (_x select 3);
    private _key = toLowerANSI (_entry getOrDefault ["class", ""]);
    private _index = _seen getOrDefault [_key, 0];

    _seen set [_key, _index + 1];

    if (_index >= (_known getOrDefault [_key, 0])) then {
        _entry set ["hidden", true];

        if (_queue && {!_seal}) then {
            call _fnc_wait;

            GVAR(searchQueue) pushBack [
                _container, _key, _entry getOrDefault ["row", 0], _entry getOrDefault ["col", 0],
                (_entry getOrDefault ["w", 1]) * (_entry getOrDefault ["h", 1]), _entry getOrDefault ["block", 0]
            ];
        };
    };
} forEach _order;

// Sealed: the seal is all that is queued - the container shows what it holds only once it is open.
if (_queue && {_seal}) then {
    call _fnc_wait;

    GVAR(searchQueue) pushBack [_container, "", 0, 0, SEAL_CELLS, SEAL_BLOCK];
};
