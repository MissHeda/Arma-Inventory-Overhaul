#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether a unit may handle something - its own gear, a person, a box: ACE's own answer (ace_common_fnc_canInteractWith, with
 * the conditions it is asked to leave out) when ACE is loaded, else the plain one - alive and awake, and not inside a vehicle
 * unless "isNotInside" is left out. ACE is no requirement of the mod.
 *
 * Arguments:
 * 0: The unit <OBJECT>
 * 1: What it handles, objNull for nothing in particular <OBJECT> (default: objNull)
 * 2: ACE's conditions to leave out, as ACE names them ("isNotSwimming", "isNotInside", ...) <ARRAY> (default: [])
 *
 * Return Value:
 * May <BOOL>
 *
 * Example:
 * [player, _box, ["isNotSwimming"]] call aio_main_fnc_canInteract;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_target", objNull, [objNull]], ["_exceptions", [], [[]]]];

if (!isNil QACEFUNC(common,canInteractWith)) exitWith {
    [_unit, _target, _exceptions] call ACEFUNC(common,canInteractWith)
};

[_unit] call FUNC(isAwake) && {isNull objectParent _unit || {"isNotInside" in _exceptions}}
