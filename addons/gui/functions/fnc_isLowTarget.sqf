#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Whether the soldier kneels to loot what the window was opened on - a standing soldier at something low:
 *   - a body, or a uniform, vest or backpack of one: when it is dead, out cold or lying down; a living,
 *     awake person who stands or kneels is looted standing
 *   - a pile on the ground: when the player aims at it (the cursor object as the window opened) or when
 *     it holds something not searched yet
 *   - a vehicle: never
 *   - anything else, a crate: when its top is less than LOW_TARGET metres above the player's feet
 *
 * Arguments:
 * 0: The unit <OBJECT>
 * 1: What the window was opened on <OBJECT>
 *
 * Return Value:
 * Kneel <BOOL>
 *
 * Example:
 * [player, cursorObject] call einv_gui_fnc_isLowTarget;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_target", objNull, [objNull]]];

if (isNull _target) exitWith {false};

// A body or a living person, or the gear of one.
private _man = if (_target isKindOf "CAManBase") then {
    _target
} else {
    ([_target] call EFUNC(storage,getOwner)) select 0
};

if (!isNull _man && {_man isKindOf "CAManBase"}) exitWith {
    !alive _man || {!([_man] call ACEFUNC(common,isAwake))} || {stance _man isEqualTo "PRONE"}
};

if ([_target] call EFUNC(storage,isGroundHolder)) exitWith {
    cursorObject isEqualTo _target || {(GVAR(searchQueue) findIf {(_x select 0) isEqualTo _target}) >= 0}
};

if (_target isKindOf "AllVehicles") exitWith {false};

// A crate: how high its top lies above the player's feet.
private _top = _target modelToWorldWorld [0, 0, ((boundingBoxReal _target) select 1) select 2];

(_top select 2) - ((getPosASL _unit) select 2) < LOW_TARGET
