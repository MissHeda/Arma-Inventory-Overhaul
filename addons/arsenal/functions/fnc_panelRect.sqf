#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Where the panel stands on ACE Arsenal's display: right beside ACE's list (IDC 15), over the 3D middle, as
 * high as that list - read from the list itself, so it follows the player's interface size and whatever ACE
 * changes about it. As wide as the inventory's grid, STORAGE_COLS cells of the engine's size
 * (einv_gui_fnc_getCell) with the column's padding and scroll bar beside them, at most a third of the screen.
 *
 * It ends above ACE's message line, which runs across the middle near the bottom: ACE's own messages and
 * this panel's "no room" stay readable.
 *
 * Arguments:
 * 0: ACE Arsenal's display <DISPLAY>
 *
 * Return Value:
 * [x, y, w, h] on the screen, [] when ACE's list is not there <ARRAY>
 *
 * Example:
 * [findDisplay 1127001] call einv_arsenal_fnc_panelRect;
 *
 * Public: No
 */

disableSerialization;

params [["_display", displayNull, [displayNull]]];

private _list = _display displayCtrl ARSENAL_IDC_LIST;

if (isNull _list) exitWith {[]};

(ctrlPosition _list) params ["_listX", "_listY", "", "_listH"];

private _bottom = _listY + _listH;
private _message = _display displayCtrl ARSENAL_IDC_MESSAGE;

if (!isNull _message) then {
    _bottom = _bottom min (((ctrlPosition _message) select 1) - UNIT * PANEL_GAP);
};

// The column's own padding on both sides, or on one side and its scroll bar on the other, whichever is
// wider (einv_gui_fnc_drawColumn), so the grid gets its full width and no box beside it.
(call EFUNC(gui,getCell)) params ["_cellW"];

private _padX = SQUARE(UNIT * 0.4);
private _width = STORAGE_COLS * _cellW + ((_padX * 2) max (_padX + SCROLL_W + pixelW * 4)) + pixelW * 2;

_width = _width min (safezoneW * PANEL_MAX_SHARE);

private _left = _listX - SQUARE(UNIT * PANEL_GAP) - _width;

[SNAP_X(_left), SNAP_Y(_listY), SNAP_W(_width), SNAP_H(_bottom - _listY)]
