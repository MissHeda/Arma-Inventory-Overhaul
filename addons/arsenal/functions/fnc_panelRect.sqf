#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Where the panel stands on ACE Arsenal's display: right beside ACE's list (IDC 15), over the 3D middle, as
 * tall as ACE's right side - from the top of the sort bar over the list (IDC 17) down to the bottom of the
 * list, read from those controls themselves, so it follows the player's interface size and whatever ACE
 * changes about them. Without a sort bar it starts where the list does. As wide as the inventory's grid,
 * STORAGE_COLS cells of the engine's size (einv_gui_fnc_getCell) with the column's padding and scroll bar
 * beside them - and the room for the most seams a canvas can have, (STORAGE_COLS - 1) gaps, so a canvas
 * with seams (einv_gui_fnc_canvasSeams) is not clipped or pushed into the scroll strip - at most a third
 * of the screen.
 *
 * It ends where the list ends, though ACE's message line (IDC 9) begins a little higher: the panel is as
 * long as the side lists, and a "no room" is said in the panel's own hint line as well.
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

private _top = _listY;
private _bottom = _listY + _listH;
private _sort = _display displayCtrl ARSENAL_IDC_SORT;

if (!isNull _sort && {ctrlShown _sort}) then {
    _top = _top min ((ctrlPosition _sort) select 1);
};

// The column's own padding on both sides, or on one side and its scroll bar on the other, whichever is
// wider (einv_gui_fnc_drawColumn), so the grid gets its full width and no box beside it.
(call EFUNC(gui,getCell)) params ["_cellW"];

private _padX = SQUARE(UNIT * 0.4);
// A seam's gap is rounded to whole pixels, as fnc_canvasSeams rounds it, so the room is exactly what the
// widest canvas takes. The panel grows to the left only: its right edge stays beside ACE's list.
private _seamW = round (_cellW * COMPARTMENT_GAP / pixelW) * pixelW;
private _width = STORAGE_COLS * _cellW + (STORAGE_COLS - 1) * _seamW + ((_padX * 2) max (_padX + SCROLL_W + pixelW * 4)) + pixelW * 2;

_width = _width min (safezoneW * PANEL_MAX_SHARE);

private _left = _listX - SQUARE(UNIT * PANEL_GAP) - _width;

[SNAP_X(_left), SNAP_Y(_top), SNAP_W(_width), SNAP_H(_bottom - _top)]
