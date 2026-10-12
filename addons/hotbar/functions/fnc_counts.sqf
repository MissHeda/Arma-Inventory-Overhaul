#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The count of every slot (fnc_count), reading what the player carries once for all seven.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Count per slot, 0 for an empty one <ARRAY>
 *
 * Example:
 * call einv_hotbar_fnc_counts;
 *
 * Public: No
 */

private _unit = ACE_player;

if (isNull _unit) exitWith {GVAR(slots) apply {0}};

private _carried = [items _unit, magazines _unit, magazinesAmmoFull _unit];

GVAR(slots) apply {[_x, _carried] call FUNC(count)}
