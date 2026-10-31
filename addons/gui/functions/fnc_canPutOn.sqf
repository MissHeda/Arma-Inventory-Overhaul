#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Whether an item from a container may be put on a body's slot - dragged from the ground, a crate or the
 * player's own gear onto the body's paper doll in the loot column (fnc_updateDrag, fnc_doEquip): the same
 * op that puts worn gear on the other unit in a swap (fnc_canSwap), without the player's own item coming
 * off first. What the body wore there comes off and goes back on the cell the new item lay on
 * (fnc_sendMoves).
 *
 * Only the gear one wears (SWAP_SLOTS) and only a body's: a weapon is not handed to a body, and a living
 * person's gear is changed as the server's settings say (fnc_canTouchPerson), which never lets an item be
 * put on them from here. The body's containers are not asked: a locked section has no slot, and a
 * body's gear is never locked (aio_locks).
 *
 * Arguments:
 * 0: Class of the item <STRING>
 * 1: The body <OBJECT>
 * 2: The slot id on the body <STRING>
 *
 * Return Value:
 * "" when it may, else the reason (fnc_flashHint) <STRING>
 *
 * Example:
 * ["V_PlateCarrier1_rgr", cursorObject, "vest"] call aio_gui_fnc_canPutOn;
 *
 * Public: No
 */

params [["_class", "", [""]], ["_unit", objNull, [objNull]], ["_slot", "", [""]]];

if (isNull _unit || {_unit isEqualTo GVAR(unit)} || {alive _unit} || {!(_unit isKindOf "CAManBase")}) exitWith {"NoFit"};
if !(_slot in SWAP_SLOTS) exitWith {"NoFit"};
if !([_unit, _slot, _class] call EFUNC(storage,slotAccepts)) exitWith {"NoFit"};

[_unit, "worn"] call FUNC(checkTouch)
