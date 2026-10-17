#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether the Zeus menu's searching choice has something to do: some of the objects is not in the state it would make.
 * Turning searching off is offered while one of them is still searched as the settings say, turning it on again while
 * one has the mark that leaves it out (einv_gui_fnc_setSearchable).
 *
 * Arguments:
 * 0: Objects <ARRAY of OBJECTs>
 * 1: Searched as the settings say (true) or never searched (false) - the choice <BOOL>
 *
 * Return Value:
 * Something would change <BOOL>
 *
 * Example:
 * [[_crate], false] call einv_compat_zen_fnc_canSetSearch;
 *
 * Public: No
 */

params [["_objects", [], [[]]], ["_searchable", true, [true]]];

_objects findIf {(_x getVariable [QGVARMAIN(noSearch), false]) isEqualTo _searchable} >= 0
