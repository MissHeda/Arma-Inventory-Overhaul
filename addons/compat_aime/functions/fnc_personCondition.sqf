#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The condition of AIME's "Open backpack" on a living person - the 3D icon on their back
 * (UPSL_aime_inventory_backpack_action_3d) and the entry in the main actions
 * (UPSL_aime_inventory_backpack_action), patched in this addon's config. AIME shows one or the other by its
 * setting "Show 3D icon on backpacks", and only for a person with a backpack that can be opened; added is
 * what this window asks of the engine's own backpack action (einv_gui_fnc_canOpenPerson: the server's
 * "Living persons" setting and the person's state, nothing for a dragging clone or a person a mission closed)
 * and the reach (einv_gui_fnc_personInReach). The action ends in the engine's OpenBag action, which this mod
 * answers with its window and the same two checks, so a person it would refuse is not offered either.
 *
 * Arguments:
 * 0: The condition's own arguments, [person, player, action parameters] <ARRAY>
 * 1: For the 3D icon (true) or the entry in the main actions (false) <BOOL>
 *
 * Return Value:
 * Shown <BOOL>
 *
 * Example:
 * [[cursorObject, ACE_player, []], true] call einv_compat_aime_fnc_personCondition;
 *
 * Public: No
 */

params [["_args", [], [[]]], ["_icon3d", false, [false]]];

_args params [["_target", objNull, [objNull]], ["_player", objNull, [objNull]]];

// AIME's two entries take turns by its setting.
if ((missionNamespace getVariable [AIME_BACKPACK_SETTING, true]) isNotEqualTo _icon3d) exitWith {false};

(missionNamespace getVariable [AIME_OPEN_SETTING, true])
&& {alive _target}
&& {!isNull unitBackpack _target}
&& {isNil "UPSL_aime_inventory_fnc_has_inventory" || {(unitBackpack _target) call UPSL_aime_inventory_fnc_has_inventory}}
&& {([_target] call EFUNC(gui,canOpenPerson)) isNotEqualTo ""}
&& {[_player, _target, true] call EFUNC(gui,personInReach)}
