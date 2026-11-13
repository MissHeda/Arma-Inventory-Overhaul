#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The handgun KJW's Two Secondary Weapons keeps holstered: of its two variables the one of the handgun not in the
 * hands - KJW_TwoSecondaryWeapons_secondSecondaryInfo while the first is drawn, _primarySecondaryInfo while the second
 * is. That mod works for the player alone (its key, its handlers), so only the player has the slot.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * [has the slot, weapon or []] - as aio_storage_fnc_secondPrimary asks it <ARRAY>
 *
 * Example:
 * [player] call aio_compat_kjw_twosecondary_fnc_get;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

if (isNull _unit || {_unit isNotEqualTo player} || {!alive _unit}) exitWith {[false, []]};

private _equipped = _unit getVariable ["KJW_TwoSecondaryWeapons_secondSecondaryEquipped", false];
private _weapon = _unit getVariable [
    ["KJW_TwoSecondaryWeapons_secondSecondaryInfo", "KJW_TwoSecondaryWeapons_primarySecondaryInfo"] select (_equipped isEqualTo true),
    []
];

if (isNil "_weapon" || {!(_weapon isEqualType [])}) exitWith {[true, []]};

[true, _weapon]
