#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether the item worn in a slot waits in the hands' queue to be taken off (fnc_queueMoves): a click on
 * the slot then cancels it, and it cannot be lifted or dropped a second time.
 *
 * Arguments:
 * 0: Whose slot <OBJECT>
 * 1: The slot's id ("headgear", "primary_optic", ...) <STRING>
 *
 * Return Value:
 * The queue entry's id, 0 when it does not wait <NUMBER>
 *
 * Example:
 * [player, "headgear"] call einv_gui_fnc_queuedSlot;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_slot", "", [""]]];

private _index = GVAR(handQueue) findIf {(_x getOrDefault ["slot", []]) isEqualTo [_unit, _slot]};

if (_index < 0) exitWith {0};

(GVAR(handQueue) select _index) get "id"
