#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Moves what lies on one slot to another; what lay there goes to the first. Saved in the profile at
 * once.
 *
 * Arguments:
 * 0: Slot index it comes from, 0 to 6 <NUMBER>
 * 1: Slot index it goes to, 0 to 6 <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [1, 4] call aio_hotbar_fnc_moveSlot;
 *
 * Public: No
 */

params [["_from", -1, [0]], ["_to", -1, [0]]];

if (_from < 0 || {_from >= SLOT_COUNT} || {_to < 0} || {_to >= SLOT_COUNT} || {_from == _to}) exitWith {};

private _moved = GVAR(slots) select _from;

GVAR(slots) set [_from, GVAR(slots) select _to];
GVAR(slots) set [_to, _moved];

call FUNC(saveSlots);

GVAR(nextCount) = 0;
call FUNC(hudPing);

if (!isNull (uiNamespace getVariable [QEGVAR(gui,display), displayNull])) then {
    ["", objNull] call EFUNC(gui,afterAction);
};
