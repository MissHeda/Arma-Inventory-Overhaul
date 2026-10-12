#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether a box is a vanilla Virtual Arsenal box: it holds virtual cargo of the vanilla arsenal, kept on it
 * by the vanilla functions (BIS_fnc_addVirtualItemCargo and the others). The inventory never searches one,
 * and offers to open it.
 *
 * Only a variable is read, so this answers on every machine.
 *
 * Arguments:
 * 0: Box <OBJECT>
 *
 * Return Value:
 * A vanilla box <BOOL>
 *
 * Example:
 * [cursorObject] call einv_arsenal_fnc_isBIBox;
 *
 * Public: No
 */

params [["_box", objNull, [objNull]]];

if (isNull _box) exitWith {false};

// [items, weapons, magazines, backpacks]: a box with anything in any of them is one.
private _cargo = _box getVariable ["bis_addVirtualWeaponCargo_cargo", [[], [], [], []]];

_cargo isEqualType [] && {_cargo findIf {_x isEqualType [] && {_x isNotEqualTo []}} >= 0}
