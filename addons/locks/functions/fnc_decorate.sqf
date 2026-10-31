#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Turns what the player may not open into locked sections, in the loot column's list as the window
 * builds it: a section whose container is locked to the player (fnc_canReach, also for a backpack
 * opened from inside a locked crate, and for other mods' locks) keeps its caption data and gets
 * "locked", "notice" (why) and "lockedObject" - and loses "container", "holder", "root" and "entries",
 * so there is no grid to draw: nothing behind the lock can be seen, lifted, dropped onto, sorted,
 * searched or taken from. A lock the player passes adds "lockTip" to the section (open padlock).
 *
 * Only crates, vehicles, piles and what is opened from inside them can be locked, not anyone's gear:
 * sections that are not "container" or "ground" pass as they are. A container opened from inside one
 * that is locked now has no section of its own any more; the top one stays, as the locked section.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Sections of the loot column (aio_storage_fnc_getLootSections) <ARRAY of HASHMAPs>
 * 2: What the window opened from inside containers, [[class, object, parent], ...] <ARRAY> (default: [])
 *
 * Return Value:
 * The sections, locked ones changed <ARRAY of HASHMAPs>
 *
 * Example:
 * [player, _lootSections, aio_gui_opened] call aio_locks_fnc_decorate;
 *
 * Public: No
 */

params [
    ["_unit", objNull, [objNull]],
    ["_sections", [], [[]]],
    ["_opened", [], [[]]]
];

private _result = [];

{
    private _section = _x;
    private _container = _section getOrDefault ["container", objNull];

    // Only crates, vehicles, piles and what is opened from inside them can be locked - not anyone's gear.
    if (isNull _container || {!((_section getOrDefault ["id", ""]) in ["container", "ground"])}) then {
        _result pushBack _section;
        continue
    };

    // The top of a chain opened from inside a container (the window's opened list: [class, object, parent]).
    private _root = _container;

    for "_i" from 1 to 8 do {
        private _index = _opened findIf {(_x select 1) isEqualTo _root};

        if (_index < 0) exitWith {};

        _root = (_opened select _index) param [2, objNull];

        if (isNull _root) exitWith {};
    };

    if (_root isEqualTo _container) then {
        _root = objNull;
    };

    ([_unit, _container, _root] call FUNC(canReach)) params ["_ok", "_reason", "_tip"];

    if (_ok) then {
        if (_tip isNotEqualTo "") then {
            _section set ["lockTip", _tip];
        };

        _result pushBack _section;
        continue
    };

    // Opened from inside a container that is locked now: it goes. The top one stays, as a locked section.
    if (_opened findIf {(_x select 1) isEqualTo _container} >= 0) then {continue};

    _section set ["locked", true];
    _section set ["notice", _reason];
    _section set ["lockedObject", _container];
    _section set ["container", objNull];
    _section set ["holder", objNull];
    _section set ["root", objNull];
    _section deleteAt "entries";
    _result pushBack _section;
} forEach _sections;

_result
