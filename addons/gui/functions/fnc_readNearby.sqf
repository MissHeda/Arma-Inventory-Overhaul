#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Reads what lies around the unit anew (einv_storage_fnc_getNearby) into GVAR(nearby): when the window
 * opens, at each contents check (fnc_onFrame) and before the window is built again for a move's answer,
 * so a pile the move made shows at once. Left empty with the player's switch off, and in any window but
 * the plain inventory (fnc_isInventoryMode) - the Arsenal's storage column is not a place to loot.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call einv_gui_fnc_readNearby;
 *
 * Public: No
 */

if (!(missionNamespace getVariable [QGVAR(showNearby), false]) || {!(call FUNC(isInventoryMode))} || {isNull GVAR(unit)}) exitWith {
    GVAR(nearby) = [];
};

GVAR(nearby) = [GVAR(unit), missionNamespace getVariable [QEGVAR(storage,nearbyRange), 3], NEARBY_MAX] call EFUNC(storage,getNearby);
