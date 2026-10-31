#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What CBA's item context menu is told about one of the player's equipment slots: CBA's name for it
 * (GVAR(cbaSlots)) and, as its hooks into the vanilla inventory pass it, the unit as the container.
 * A body's slots have nothing to tell - the vanilla inventory offers no menu on them either.
 *
 * Arguments:
 * 0: Whose slot it is <OBJECT>
 * 1: Slot id, see aio_storage_fnc_getSlot <STRING>
 *
 * Return Value:
 * [CBA slot, container], ["", objNull] for none <ARRAY>
 *
 * Example:
 * [player, "primary_optic"] call aio_gui_fnc_cbaSlotTarget;
 *
 * Public: No
 */

params [["_owner", objNull, [objNull]], ["_slot", "", [""]]];

if (isNull _owner || {_owner isNotEqualTo GVAR(unit)}) exitWith {["", objNull]};

[GVAR(cbaSlots) getOrDefault [_slot, ""], _owner]
