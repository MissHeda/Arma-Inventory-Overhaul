#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What a setting allows to be used from one of the unit's containers: USE_ALL ("all", everything in it can
 * be used - the default), USE_LIST ("list", only items whitelisted for it, use= / aio_use), USE_NONE
 * ("none", nothing, whitelisted or not) or USE_STRICT ("strict", as "list" - and what is blocked is kept out
 * of the container's cargo altogether, in the unit's hidden holder, fnc_opStrict). The settings are
 * aio_storage_useUniform, aio_storage_useVest and aio_storage_useBackpack; any other container (a crate,
 * the ground, a body) is "all": nothing is used from there.
 *
 * Arguments:
 * 0: Container: "uniform", "vest" or "backpack" <STRING>
 *
 * Return Value:
 * "all", "list", "none" or "strict" <STRING>
 *
 * Example:
 * ["backpack"] call aio_storage_fnc_useMode;
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
