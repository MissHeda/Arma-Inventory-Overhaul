#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * A mouse button pressed on ACE's list (IDC 15) - the list's own handler, as the display's may not hear a
 * press on one of ACE's controls. A left press on its rows is noted, and nothing else: the click and the
 * row it picks are ACE's. Only should the mouse then leave it sideways with the button held does the frame
 * hook make a drag of that row's item (fnc_onFrame, fnc_listDrag); let go first, the note goes. Not on the
 * scroll bar along its right edge, not on the blank area below the last row of a short or filtered list
 * (a press there picks no row, and the row picked before is not the one pressed), and only while there is
 * a panel beside it to drag to.
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

// The rows are all as high as the list's config says (found once, by its IDC, in ACE's display). A row
// height left to the font (0) cannot be told: the blank area is then not told from a row, but a list
// with no row has none to press.
private _rowH = _list getVariable [QGVAR(rowHeight), -1];

if (_rowH < 0) then {
    private _config = (format ["getNumber (_x >> 'idc') == %1", ARSENAL_IDC_LIST] configClasses (configFile >> "ace_arsenal_display" >> "controls")) param [0, configNull];

    _rowH = getNumber (_config >> "rowHeight");
    _list setVariable [QGVAR(rowHeight), _rowH];
};

// A list that scrolls is full to its bottom edge, so the end of its rows lies at or past it.
private _rows = (lnbSize _list) select 0;
private _blank = _rows < 1 || {_rowH > 0 && {_mouseY >= _listY + _rows * _rowH}};

if (
    !_blank && {_mouseX >= _listX} && {_mouseX < _listX + _listW * LIST_ROWS_SHARE}
    && {_mouseY >= _listY} && {_mouseY < _listY + _listH}
) then {
    GVAR(listPress) = [_mouse, _shift];
};
