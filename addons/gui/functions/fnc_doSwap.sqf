#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Exchanges worn gear between the player and a body (or a living person, as the settings allow): what one
 * wears in a slot goes onto the other's same slot, and what the other wore there - if anything - comes
 * back onto the first, a uniform, vest or backpack with everything in it (Mia, 0.2.3). Dragged from a
 * slot onto the other's slot (fnc_endDrag), or a body's worn item onto the player's equipment.
 *
 * One transaction (fnc_sendMoves, kind "swap"): taken off where the first is local, put on where the
 * other is local - which hands back what was there -, that put on the first. Whatever does not go where
 * it should is settled by the storage, never lost or doubled: an item that would not go on comes off
 * a slot and has no place of origin, so it goes into the requester's vehicle or onto the ground.
 *
 * Arguments:
 * 0: Where it comes from, [unit, slot id] <ARRAY>
 * 1: The unit it goes onto <OBJECT>
 * 2: The slot id there <STRING>
 *
 * Return Value:
 * Asked for <BOOL>
 *
 * Example:
 * [[player, "backpack"], _body, "backpack"] call aio_gui_fnc_doSwap;
 *
 * Public: No
 */

params [["_source", [], [[]]], ["_toUnit", objNull, [objNull]], ["_toSlot", "", [""]]];
_source params [["_fromUnit", objNull, [objNull]], ["_fromSlot", "", [""]]];

private _why = [_source, _toUnit, _toSlot] call FUNC(canSwap);

if (_why isNotEqualTo "") exitWith {
    [_why] call FUNC(flashHint);
    false
};

[[createHashMapFromArray [
    ["kind", "swap"], ["unit", _fromUnit], ["slot", _fromSlot], ["toUnit", _toUnit], ["toSlot", _toSlot]
]]] call FUNC(sendMoves)
