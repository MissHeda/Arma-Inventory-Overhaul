#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The name of one or several of the unit's containers as a sentence has them: "uniform", "vest", "backpack"
 * in the player's language and lower case, joined with "and".
 *
 * Arguments:
 * 0: Containers, any of "uniform", "vest", "backpack" - or one of them as a string <ARRAY of STRING>
 *
 * Return Value:
 * The words <STRING>
 *
 * Example:
 * [["vest", "backpack"]] call einv_storage_fnc_useKindName;
 * // "vest and backpack"
 *
 * Public: Yes
 */

params [["_kinds", [], ["", []]]];

if (_kinds isEqualType "") then {
    _kinds = [_kinds];
};

(_kinds apply {localize format ["STR_einv_storage_Kind_%1", _x]}) joinString (" " + localize "STR_einv_storage_Kind_And" + " ")
