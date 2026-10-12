#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether the unit may do something with its hands right now - the same question ACE asks before its own
 * self-interaction: alive and awake, not captive, not escorting, dragging or carrying, not on a ladder.
 * The exceptions are what the use itself may do in spite of that: ACE lets a soldier treat himself and
 * drink in a seat, and a reload or a throw is checked on its own.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Exceptions, as ace_common_fnc_canInteractWith takes them <ARRAY> (default: [])
 *
 * Return Value:
 * May act <BOOL>
 *
 * Example:
 * [player, ["isNotInside", "isNotSitting"]] call einv_hotbar_fnc_canAct;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_exceptions", [], [[]]]];

[_unit, objNull, _exceptions] call ace_common_fnc_canInteractWith
