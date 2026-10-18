#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What really changed on ACE's unit (ace_arsenal_itemsChanged): an add or a removal in a list, "Remove
 * all", another container put on, a loadout loaded or imported. In the open uniform, vest or backpack,
 * what was just added and has no free cells comes back out at once, before ACE greys its list
 * (fnc_reconcile); everything else only has the list and the panel looked at again a frame later
 * (fnc_settle), where what the containers hold now is noted as it is.
 *
 * Arguments:
 * 0: ACE Arsenal's display <DISPLAY>
 * 1: ACE's tab the change came from, -1 for a whole loadout <NUMBER>
 * 2: Classes gained -> how many <HASHMAP>
 * 3: Classes lost -> how many <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, 2012, _gained, _lost] call einv_arsenal_fnc_onItemsChanged;
 *
 * Public: No
 */

disableSerialization;

params [["_display", displayNull, [displayNull]], ["_panel", -1, [0]]];

if (!GVAR(attached)) exitWith {};

// A container picked in ACE's list made all three new: the old arrangement goes back before anything reads them.
[] call FUNC(keepPlaces);

GVAR(itemsSeen) = true;

(call FUNC(selected)) params ["_id", "", "_open"];

if (_id isNotEqualTo "" && {_panel == _open}) then {
    [_display] call FUNC(reconcile);
};

[] call FUNC(settle);
