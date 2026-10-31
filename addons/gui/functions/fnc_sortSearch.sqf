#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Puts what is still to be searched in order: one container after the other, each from the top left - its seal
 * first, then the item the player clicked to search first (fnc_searchFirst, the record's "first"), then the rest by
 * compartment, row and column.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call aio_gui_fnc_sortSearch;
 *
 * Public: No
 */

private _containers = [];
private _first = [];

{
    private _box = _x select 0;

    if !(_box in _containers) then {
        _containers pushBack _box;
        _first pushBack (([_box] call FUNC(searchRecord)) getOrDefault ["first", []]);
    };
} forEach GVAR(searchQueue);

GVAR(searchQueue) = [GVAR(searchQueue), [], {
    private _at = _containers find (_x select 0);
    private _place = ((_x param [5, 0]) + 1) * 100000 + (_x select 2) * 100 + (_x select 3);

    // The seal is 0 (compartment -1), the clicked item 1, everything else from 100000 on.
    if ([_x select 1, _x select 2, _x select 3, _x param [5, 0]] isEqualTo (_first select _at)) then {
        _place = 1;
    };

    _at * 1e7 + _place
}, "ASCEND"] call BIS_fnc_sortBy;
