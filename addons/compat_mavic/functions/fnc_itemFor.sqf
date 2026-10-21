#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The item a deployed Mavic 3 (Improved) drone is packed into, as the mod's own function
 * (Mavic_fnc_addUavToInventory) picks it.
 *
 * Arguments:
 * 0: Drone <OBJECT>
 *
 * Return Value:
 * Item class <STRING>
 *
 * Example:
 * [_drone] call einv_compat_mavic_fnc_itemFor;
 *
 * Public: No
 */

params [["_uav", objNull, [objNull]]];

private _type = typeOf _uav;

switch (true) do {
    case (_type isKindOf "Mavic3_drone_base_F"): {"Item_Mavic3"};
    case (_type isKindOf "Mavic3T_drone_base_F"): {"Item_Mavic3T"};
    case (_type isKindOf "Mavic3N_drone_base_F"): {"Item_Mavic3N"};
    case (_type isKindOf "Mavic3X_drone_base_F"): {"Item_Mavic3X"};
    default {"Item_Mavic3"};
}
