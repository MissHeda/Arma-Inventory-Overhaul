#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Turns the search off for a single object, or gives it back to the settings: a crate, a vehicle, a body or a
 * living person whose loot shows at once, without the "?" tiles (fnc_isSearched). The mark is the object variable
 * einv_noSearch, set public so a player who joins later has it too - the call may come from any machine, a mission's
 * init, a trigger or a Zeus module alike.
 *
 * It is an override in one direction only: true gives the object back to the settings (Search crates and vehicles,
 * Search bodies and the rest), it does not force a search where a setting says there is none.
 *
 * Arguments:
 * 0: Object <OBJECT>
 * 1: Searched as the settings say (true) or never searched (false) <BOOL> (default: true)
 *
 * Return Value:
 * None
 *
 * Example:
 * [_supplyCrate, false] call einv_gui_fnc_setSearchable;
 *
 * Public: Yes
 */

params [["_object", objNull, [objNull]], ["_searchable", true, [true]]];

if (isNull _object) exitWith {};

// False (not nil) for "as the settings say": it is what a reader gets for an object that never had the variable.
_object setVariable [QGVARMAIN(noSearch), !_searchable, true];
