#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What a setting allows to be used from one of the unit's containers: USE_ALL ("all", everything in it can
 * be used - the default), USE_LIST ("list", only items whitelisted for it, use= / einv_use) or USE_NONE
 * ("none", nothing, whitelisted or not). The settings are einv_storage_useUniform, einv_storage_useVest
 * and einv_storage_useBackpack; any other container (a crate, the ground, a body) is "all": nothing is used
 * from there.
 *
 * Arguments:
 * 0: Container: "uniform", "vest" or "backpack" <STRING>
 *
 * Return Value:
 * "all", "list" or "none" <STRING>
 *
 * Example:
 * ["backpack"] call einv_storage_fnc_useMode;
 *
 * Public: Yes
 */

params [["_kind", "", [""]]];

switch (_kind) do {
    case "uniform": {missionNamespace getVariable [QGVAR(useUniform), USE_ALL]};
    case "vest": {missionNamespace getVariable [QGVAR(useVest), USE_ALL]};
    case "backpack": {missionNamespace getVariable [QGVAR(useBackpack), USE_ALL]};
    default {USE_ALL};
}
