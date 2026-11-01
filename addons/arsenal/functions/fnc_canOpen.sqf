#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether a unit can open the arsenal of a box from the inventory window: the box is an arsenal box
 * (fnc_isArsenalBox), and the unit may use it. For an ACE box that is the way ACE's own interaction asks -
 * a soldier on foot, free to interact with the box (ace_common_fnc_canInteractWith) - with no arsenal open
 * already (ACE's camera is there while one is). For a box of the vanilla Virtual
 * Arsenal it is what the vanilla scroll action asks (fnc_canOpenBI).
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Box <OBJECT>
 *
 * Return Value:
 * Can open it <BOOL>
 *
 * Example:
 * [player, cursorObject] call aio_arsenal_fnc_canOpen;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_box", objNull, [objNull]]];

if (isNull _unit || {!([_box] call FUNC(isArsenalBox))}) exitWith {false};

// Neither openBox nor the vanilla arsenal says anything for anyone else.
if (!(_unit isKindOf "CAManBase") || {!isNull objectParent _unit}) exitWith {false};

if (!isNil QACEGVAR(arsenal,camera)) exitWith {false};

// A box that is only a vanilla one.
if (isNil {_box getVariable QACEGVAR(arsenal,virtualItems)}) exitWith {
    [_box, _unit] call FUNC(canOpenBI)
};

[_unit, _box] call EFUNC(main,canInteract)
