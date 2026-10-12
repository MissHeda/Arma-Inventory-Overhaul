#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Raises ace_arsenal_cargoChanged for an item added to or taken from the uniform, vest or backpack. ACE's
 * own listener needs data this window never sets, so it is told not to act while the others - Enhanced
 * First Aid Kits and the rest - hear the event as ever.
 *
 * Arguments:
 * 0: Class <STRING>
 * 1: 1 for added, -1 for taken <NUMBER>
 * 2: How many of it <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["ACE_fieldDressing", 1, 3] call einv_arsenal_fnc_aceCargoEvent;
 *
 * Public: No
 */

params [["_class", "", [""]], ["_delta", 1, [0]], ["_count", 1, [0]]];

if (_class isEqualTo "" || {_count < 1}) exitWith {};

private _display = findDisplay IDD_ARSENAL;

// ACE's listener would look for its own lists to redraw: it reads this switch and leaves the event alone.
private _kept = missionNamespace getVariable [QACEGVAR(arsenal,updateActionsOnCargoChange), false];
missionNamespace setVariable [QACEGVAR(arsenal,updateActionsOnCargoChange), false];

// Once for every item, as ACE raises it for every click.
for "_i" from 1 to (_count min 100) do {
    [QACEGVAR(arsenal,cargoChanged), [_display, _class, [-1, 1] select (_delta > 0), false]] call CBA_fnc_localEvent;
};

missionNamespace setVariable [QACEGVAR(arsenal,updateActionsOnCargoChange), _kept];
