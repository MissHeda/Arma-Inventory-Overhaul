#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether an object is an arsenal box: an ACE one, which carries the arsenal's virtual items - that is the
 * very question ACE's own ace_arsenal_fnc_openBox asks, so it also finds boxes a mission made with
 * ace_arsenal_fnc_addVirtualItems alone, and none that ace_arsenal_fnc_removeBox took away again - or a
 * box of the vanilla Virtual Arsenal (fnc_isBIBox), which the inventory then never searches and offers to
 * open.
 *
 * Only variables are read, so this answers on every machine without waiting for an event of ACE's.
 *
 * Arguments:
 * 0: Object <OBJECT>
 *
 * Return Value:
 * An arsenal box <BOOL>
 *
 * Example:
 * [cursorObject] call aio_arsenal_fnc_isArsenalBox;
 *
 * Public: No
 */

params [["_object", objNull, [objNull]]];

if (isNull _object) exitWith {false};

!isNil {_object getVariable QACEGVAR(arsenal,virtualItems)} || {[_object] call FUNC(isBIBox)}
