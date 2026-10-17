#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The condition of AIME's "Inventory" on a vehicle (its action UPSL_aime_inventory_open_action, patched in
 * this addon's config): what AIME asked - its setting "Show vehicle/backpack inventory action" on, the
 * vehicle alive and with a cargo space - and that the window may open on it (einv_gui_fnc_canOpenVehicle:
 * the player on foot within the window's reach, cells to show, not locked to him). The action itself ends in
 * the engine's Gear action, which this mod answers with its window.
 *
 * Not shown at all where the "Inventory" of ACE interaction's own addon (einv_compat_ace_interaction) is
 * loaded: it is the same entry and the same window, once is enough.
 *
 * ACE asks it while its menu is open, for the vehicle looked at.
 *
 * Arguments:
 * 0: Vehicle <OBJECT>
 * 1: Player <OBJECT>
 * 2: Action parameters - not used <ANY>
 *
 * Return Value:
 * Shown <BOOL>
 *
 * Example:
 * [cursorObject, ACE_player, []] call einv_compat_aime_fnc_vehicleCondition;
 *
 * Public: No
 */

params [["_target", objNull, [objNull]], ["_player", objNull, [objNull]]];

(missionNamespace getVariable [AIME_OPEN_SETTING, true])
&& {alive _target}
&& {isNil QEFUNC(compat_ace_interaction,canOpen)}
&& {isNil "UPSL_aime_inventory_fnc_has_inventory" || {_target call UPSL_aime_inventory_fnc_has_inventory}}
&& {[_player, _target] call EFUNC(gui,canOpenVehicle)}
