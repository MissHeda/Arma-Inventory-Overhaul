#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether the player may change what a slot owner or a container on the window holds, and if not, why -
 * as the reason the hint shows (fnc_flashHint). Only a living person's gear can be refused: by the
 * server's settings (fnc_canTouchPerson), or because the person is out of reach by now. Everything else
 * - the player's own, crates, the ground, bodies - is always allowed here.
 *
 * Arguments:
 * 0: Slot owner or container <OBJECT>
 * 1: Kind - "items" for what lies in a container, "worn" for a slot <STRING>
 *
 * Return Value:
 * "" when allowed, else "LookOnly" or "Failed" <STRING>
 *
 * Example:
 * [backpackContainer cursorObject, "items"] call einv_gui_fnc_checkTouch;
 *
 * Public: No
 */

params [["_object", objNull, [objNull]], ["_kind", "items", [""]]];

([_object] call FUNC(personOf)) params ["_person", "_root"];

if (isNull _person) exitWith {""};
if !([_person, _kind, _root] call FUNC(canTouchPerson)) exitWith {"LookOnly"};
if !([GVAR(unit), _person, true] call FUNC(personInReach)) exitWith {"Failed"};

""
