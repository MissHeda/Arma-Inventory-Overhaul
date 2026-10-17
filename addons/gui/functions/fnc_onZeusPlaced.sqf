#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * A crate or a vehicle the game master placed: with "Search crates and vehicles placed by Zeus" off it is left out of
 * the search (fnc_setSearchable), so loot a game master laid out for the players shows at once. Persons are not
 * touched. Runs on whichever machine the curator's event fires on - the mark is public and the same from every one.
 *
 * Arguments:
 * 0: Curator module <OBJECT>
 * 1: The object placed <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_curator, _crate] call einv_gui_fnc_onZeusPlaced;
 *
 * Public: No
 */

params ["", ["_object", objNull, [objNull]]];

if (GVAR(searchZeus) || {isNull _object} || {_object isKindOf "CAManBase"} || {maxLoad _object <= 0}) exitWith {};

[_object, false] call FUNC(setSearchable);
