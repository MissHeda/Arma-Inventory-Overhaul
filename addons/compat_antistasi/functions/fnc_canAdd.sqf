#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The engine's "container canAdd [class, count]" with the grid counted as well (fnc_gridRoom) - what the trader's
 * window asks before it lights its Buy button (fnc_storeMain). Nothing to add is always true, as the engine says.
 *
 * Arguments:
 * 0: A unit or a container <OBJECT>
 * 1: Class <STRING>
 * 2: How many <NUMBER>
 *
 * Return Value:
 * They can be added <BOOL>
 *
 * Example:
 * [player, "FirstAidKit", 2] call aio_compat_antistasi_fnc_canAdd;
 *
 * Public: No
 */

params [["_target", objNull, [objNull]], ["_class", "", [""]], ["_count", 1, [0]]];

if (isNull _target) exitWith {false};
if (_count <= 0) exitWith {_target canAdd [_class, 0 max _count]};
if !(_target canAdd [_class, _count]) exitWith {false};

private _room = [_target, _class, _count] call FUNC(gridRoom);

_room < 0 || {_count <= _room}
