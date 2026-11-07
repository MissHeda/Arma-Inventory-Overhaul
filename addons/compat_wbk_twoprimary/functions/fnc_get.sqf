#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The weapon a unit carries on its back with WebKnight's Two Primary Weapons - the second element of its
 * variable WBK_SecondWeapon, [box, weapon], nil while the back is empty. Every living soldier has the slot: that
 * mod's scripted functions put weapons on the backs of AI as well. A body has none - that mod drops the weapon
 * on the ground when its owner dies.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * [has the slot, weapon or []] - as aio_storage_fnc_secondPrimary asks it <ARRAY>
 *
 * Example:
 * [player] call aio_compat_wbk_twoprimary_fnc_get;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

if (isNull _unit || {!alive _unit} || {!(_unit isKindOf "CAManBase")}) exitWith {[false, []]};

private _second = _unit getVariable "WBK_SecondWeapon";

if (isNil "_second" || {!(_second isEqualType [])}) exitWith {[true, []]};

private _weapon = _second param [1, [], [[]]];

[true, _weapon]
