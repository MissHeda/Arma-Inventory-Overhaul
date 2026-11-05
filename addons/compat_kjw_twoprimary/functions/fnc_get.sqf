#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The weapon the player carries on his back with KJW's Two Primary Weapons: of that mod's two variables the one
 * that is not in the hands - KJW_TwoPrimaryWeapons_secondPrimaryInfo while the first primary is held,
 * _primaryPrimaryInfo while the second is (KJW_TwoPrimaryWeapons_secondPrimaryEquipped). Only the player has the
 * slot: that mod keeps the back weapon of the player alone (its key, its event handlers, its holders all ask
 * "player").
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * [has the slot, weapon or []] - as aio_storage_fnc_secondPrimary asks it <ARRAY>
 *
 * Example:
 * [player] call aio_compat_kjw_twoprimary_fnc_get;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

if (isNull _unit || {_unit isNotEqualTo player} || {!alive _unit}) exitWith {[false, []]};

private _equipped = _unit getVariable ["KJW_TwoPrimaryWeapons_secondPrimaryEquipped", false];
private _weapon = _unit getVariable [
    ["KJW_TwoPrimaryWeapons_secondPrimaryInfo", "KJW_TwoPrimaryWeapons_primaryPrimaryInfo"] select (_equipped isEqualTo true),
    []
];

if (isNil "_weapon" || {!(_weapon isEqualType [])}) exitWith {[true, []]};

[true, _weapon]
