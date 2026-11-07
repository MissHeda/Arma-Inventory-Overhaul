#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Condition of ACE interaction > Pack up drone on a drone of Ukraine FPV Drone: the mod's own check
 * (UA_fnc_fpv_canDisassembly), and only where the mod's own entry would say there is no room - the engine's canAdd says no
 * while the grid has a free spot for the item (fnc_packItem). Where the engine says yes, the mod's own entry does it.
 *
 * Arguments:
 * 0: Drone <OBJECT>
 * 1: Unit <OBJECT>
 *
 * Return Value:
 * Offered <BOOL>
 *
 * Example:
 * [_drone, player] call aio_compat_fpv_fnc_packCondition;
 *
 * Public: No
 */

params [["_uav", objNull, [objNull]], ["_player", objNull, [objNull]]];

if (isNil "UA_fnc_fpv_canDisassembly" || {!([_uav, _player] call UA_fnc_fpv_canDisassembly)}) exitWith {false};
if !([_player, _uav, []] call ACEFUNC(common,canInteractWith)) exitWith {false};

([_uav, _player] call FUNC(packItem)) params ["_class", "", "_container"];

!(_player canAdd _class) && {!isNull _container}
