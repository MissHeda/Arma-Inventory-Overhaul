#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Opens a crate loaded in a vehicle (or in another crate) as a section of the loot column, or closes it
 * again - the Open / Close button of its cargo card. A loaded object keeps its own cargo, so it can be
 * looked into and changed while it hangs in the vehicle: it shows like any crate, under the cargo, and
 * things move in and out of it through the transactions like with any other. It is searched the way its
 * vehicle is (einv_gui_fnc_isSearched follows the chain up), and it sounds like a crate being opened.
 *
 * It is kept in the window's list of what was opened from inside a container, with the vehicle as the
 * container it lies in; the vehicle is also noted on the crate, so the window lets go of it once it is
 * no longer loaded there (fnc_pruneOpened).
 *
 * Arguments:
 * 0: Vehicle or crate it is loaded in <OBJECT>
 * 1: The loaded crate <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_vehicle, _crate] call einv_compat_ace_cargo_fnc_toggleOpen;
 *
 * Public: No
 */

params [["_holder", objNull, [objNull]], ["_item", objNull, [objNull]]];

if (isNull _holder || {isNull _item}) exitWith {};

// Open: close it, with the sound of the crate it is (einv_gui_fnc_closeNested builds the window again).
if (EGVAR(gui,opened) findIf {(_x select 1) isEqualTo _item} >= 0) exitWith {
    [_item] call EFUNC(gui,closeNested);
};

private _state = [_holder, _item, ACE_player] call FUNC(rowState);

if !(_state get "canOpen") exitWith {
    [_state get "openTip"] call EFUNC(gui,flashHint);
};

// Local, like the list it joins: the window of this machine lets go of it when it is unloaded.
_item setVariable [QGVAR(openedFrom), _holder];
EGVAR(gui,opened) pushBack [typeOf _item, _item, _holder];

["open", "", _item] call EFUNC(gui,playSound);

private _display = uiNamespace getVariable [QEGVAR(gui,display), displayNull];

if (!isNull _display) then {
    [_display] call EFUNC(gui,build);
};
