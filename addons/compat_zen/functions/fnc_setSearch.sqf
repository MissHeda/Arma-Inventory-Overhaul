#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Turns the search off for the objects the Zeus menu chose - what they hold shows at once - or on again, as the server's
 * settings have it, and tells the game master what was done. The mark is public (aio_gui_fnc_setSearchable), so every
 * player and a later joiner see it.
 *
 * Arguments:
 * 0: Objects <ARRAY of OBJECTs>
 * 1: Searched as the settings say (true) or never searched (false) <BOOL>
 *
 * Return Value:
 * None
 *
 * Example:
 * [[_crate], false] call aio_compat_zen_fnc_setSearch;
 *
 * Public: No
 */

params [["_objects", [], [[]]], ["_searchable", true, [true]]];

if (_objects isEqualTo []) exitWith {};

{
    [_x, _searchable] call EFUNC(gui,setSearchable);
} forEach _objects;

[objNull, [LLSTRING(Feedback_SearchOff), LLSTRING(Feedback_SearchOn)] select _searchable] call BIS_fnc_showCuratorFeedbackMessage;
