#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Empties a slot of the hotbar. The item is not touched. Saved in the profile at once.
 *
 * Arguments:
 * 0: Slot index, 0 to 6 <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [1] call aio_hotbar_fnc_unbind;
 *
 * Public: Yes
 */

params [["_index", -1, [0]]];

if (_index < 0 || {_index >= SLOT_COUNT} || {(GVAR(slots) select _index) isEqualTo ""}) exitWith {};

GVAR(slots) set [_index, ""];

call FUNC(saveSlots);

GVAR(nextCount) = 0;
call FUNC(hudPing);

if (!isNull (uiNamespace getVariable [QEGVAR(gui,display), displayNull])) then {
    ["", objNull] call EFUNC(gui,afterAction);
};
