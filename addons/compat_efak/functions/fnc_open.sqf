#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Opens a kit in a floating window of its own over the inventory's columns, beside the tile it was
 * opened from (einv_gui_fnc_openWindow) - or says in the hint why it may not (fnc_canOpen). Nothing in
 * the columns changes for it: the window is all that is drawn. Open already, its window comes to the
 * top where it is.
 *
 * The kit opens with its own sound - the family "medic" of Arma Inventory Overhaul's sound table, a medic bag
 * ripped open.
 *
 * Kept by its class in GVAR(opened); where it lies is found anew whenever the windows are drawn
 * (fnc_getSections). What it held when the window first touched it is noted for the packing-off rule
 * (fnc_snapshot).
 *
 * Arguments:
 * 0: Kit class <STRING>
 * 1: Container its tile lies in, objNull inside another kit <OBJECT>
 * 2: Kit its tile lies in, "" in a container <STRING>
 * 3: Its tile on the screen [x, y, w, h] (einv_gui_fnc_tileRect), [] for none <ARRAY> (default: [])
 *
 * Return Value:
 * Opened <BOOL>
 *
 * Example:
 * ["efak_IFAK_7", backpackContainer player, ""] call einv_compat_efak_fnc_open;
 *
 * Public: No
 */

params [["_class", "", [""]], ["_container", objNull, [objNull]], ["_parent", "", [""]], ["_anchor", [], [[]]]];

([_class, _container] call FUNC(canOpen)) params ["_ok", "_why"];

if (!_ok) exitWith {
    [_why] call EFUNC(gui,flashHint);
    false
};

if ((GVAR(opened) findIf {_x == _class}) < 0) then {
    GVAR(opened) pushBack _class;
};

GVAR(holders) set [toLowerANSI _class, [_container, _parent]];

[_class] call FUNC(snapshot);
// A kit sounds as the medical item it is: the medic bag ripped open (einv_gui_fnc_playSound).
["open", _class] call EFUNC(gui,playSound);

["kit:" + toLowerANSI _class, _anchor] call EFUNC(gui,openWindow);

true
