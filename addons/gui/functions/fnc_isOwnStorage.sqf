#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether a holder is part of what the window's unit carries: its uniform, vest or backpack, or anything
 * lying in them, however deep - the holder's root (einv_storage_fnc_rootOf) is the unit itself. Taking
 * something from anywhere else puts weight on the soldier; moving it around in his own gear does not.
 * Not einv_gui_fnc_isShared, which says nothing about whose it is in single player.
 *
 * Arguments:
 * 0: Holder - a container, or a kit's key <OBJECT or STRING>
 *
 * Return Value:
 * It is carried by the unit <BOOL>
 *
 * Example:
 * [backpackContainer player] call einv_gui_fnc_isOwnStorage;
 *
 * Public: No
 */

params [["_holder", objNull, [objNull, ""]]];

if (_holder isEqualType objNull && {isNull _holder}) exitWith {false};
if (isNull GVAR(unit)) exitWith {false};

([_holder] call EFUNC(storage,rootOf)) isEqualTo GVAR(unit)
