#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether a unit can take one of a class - the engine's canAdd, canAddItemToBackpack, ToVest or ToUniform - with the
 * grid counted as well (fnc_gridRoom): the Bazaar's question before it puts a purchase into the player's gear rather
 * than beside them (fnc_receiveItems).
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Class <STRING>
 * 2: Where: "" anywhere, "backpack", "vest" or "uniform" <STRING> (default: "")
 *
 * Return Value:
 * It fits <BOOL>
 *
 * Example:
 * [player, "FirstAidKit", "vest"] call aio_compat_antistasi_fnc_canTake;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_class", "", [""]], ["_where", "", [""]]];

if (isNull _unit || {_class isEqualTo ""}) exitWith {false};

private _container = switch (_where) do {
    case "backpack": {backpackContainer _unit};
    case "vest": {vestContainer _unit};
    case "uniform": {uniformContainer _unit};
    default {_unit};
};

private _engine = switch (_where) do {
    case "backpack": {_unit canAddItemToBackpack _class};
    case "vest": {_unit canAddItemToVest _class};
    case "uniform": {_unit canAddItemToUniform _class};
    default {_unit canAdd _class};
};

if (!_engine || {isNull _container}) exitWith {false};

([_container, _class, 1] call FUNC(gridRoom)) != 0
