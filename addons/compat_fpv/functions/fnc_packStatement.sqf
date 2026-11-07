#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Statement of ACE interaction > Pack up drone: as the mod's own UA_fnc_fpv_addUavToInventory - the item goes to the unit,
 * the crew and the drone go - with the item put into the container the grid has a free spot in, which the engine would not
 * have taken (fnc_packCondition). The drone stays where no spot is left by now, so the item is never lost.
 *
 * Arguments:
 * 0: Drone <OBJECT>
 * 1: Unit <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_drone, player] call aio_compat_fpv_fnc_packStatement;
 *
 * Public: No
 */

params [["_uav", objNull, [objNull]], ["_player", objNull, [objNull]]];

if (isNull _uav || {isNull _player} || {!([_uav, _player] call UA_fnc_fpv_canDisassembly)}) exitWith {};

([_uav, _player] call FUNC(packItem)) params ["_class", "_rounds", "_container"];

if (isNull _container) exitWith {};

_container addMagazineAmmoCargo [_class, 1, _rounds];

{deleteVehicle _x} forEach crew _uav;
deleteVehicle _uav;

INFO_2("Packed %1 for %2 by the grid's room, the engine did not take it",_class,name _player);
