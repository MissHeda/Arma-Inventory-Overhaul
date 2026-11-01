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
 * call aio_hotbar_fnc_counts;
 *
 * Public: No
 */

private _unit = PLAYER_UNIT;

if (isNull _unit) exitWith {GVAR(slots) apply {0}};

private _carried = [items _unit, magazines _unit, magazinesAmmoFull _unit];

// Less what lies in a container the settings "Use items from ..." close - the same for all seven.
private _usable = [_unit, _carried] call EFUNC(storage,useCarried);

GVAR(slots) apply {[_x, _carried, _usable] call FUNC(count)}
