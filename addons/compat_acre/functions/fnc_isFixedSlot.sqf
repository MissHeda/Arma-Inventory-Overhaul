#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether a slot of a unit is one ACRE2 keeps for itself. ACRE2 puts a dummy radio into the radio slot so
 * that the game's text chat keeps working, and hides that slot in the vanilla inventory; drop it, and ACRE2
 * would make a new one every frame - litter on the ground. In the window the slot cannot be lifted,
 * emptied or filled (einv_storage_fnc_slotAccepts, einv_gui_fnc_startDrag, einv_gui_fnc_doUnequip), and the
 * guard on every op says the same where a transaction runs (fnc_guard).
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Slot id <STRING>
 *
 * Return Value:
 * Fixed <BOOL>
 *
 * Example:
 * [player, "radio"] call einv_compat_acre_fnc_isFixedSlot;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_slot", "", [""]]];

if (_slot isNotEqualTo "radio" || {isNull _unit}) exitWith {false};

((([_unit] call EFUNC(storage,getEquipment)) getOrDefault ["radio", ""]) == "ItemRadioAcreFlagged")
