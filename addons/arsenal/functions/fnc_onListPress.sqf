#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * A mouse button pressed on ACE's list (IDC 15) - the list's own handler, as the display's may not hear a
 * press on one of ACE's controls. A left press on its rows is noted, and nothing else: the click and the
 * row it picks are ACE's. Only should the mouse then leave it sideways with the button held does the frame
 * hook make a drag of that row's item (fnc_onFrame, fnc_listDrag); let go first, the note goes. Not on the
 * scroll bar along its right edge, and only while there is a panel beside it to drag to.
 *
 * Arguments:
 * 0: ACE's list <CONTROL>
 * 1: Button, 0 left, 1 right <NUMBER>
 * 2: Shift - a drag starts with a whole stack <BOOL> (default: false)
 *
 * Return Value:
 * None
 *
 * Example:
 * [_list, 0, false] call einv_arsenal_fnc_onListPress;
 *
 * Public: No
 */

disableSerialization;

params [["_list", controlNull, [controlNull]], ["_button", 0, [0]], ["_shift", false, [false]]];

GVAR(listPress) = [];

if (_button != 0 || {isNull _list} || {!GVAR(attached)} || {GVAR(panelRect) isEqualTo []} || {EGVAR(gui,dragging)}) exitWith {};

private _mouse = getMousePosition;

(ctrlPosition _list) params ["_listX", "_listY", "_listW", "_listH"];
_mouse params ["_mouseX", "_mouseY"];

if (
    _mouseX >= _listX && {_mouseX < _listX + _listW * LIST_ROWS_SHARE}
    && {_mouseY >= _listY} && {_mouseY < _listY + _listH}
) then {
    GVAR(listPress) = [_mouse, _shift];
};
