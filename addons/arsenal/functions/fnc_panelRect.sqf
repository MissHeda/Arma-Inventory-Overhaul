#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Where the panel stands on ACE Arsenal's display: right beside ACE's list (IDC 15), over the 3D middle, as
 * tall as ACE's right side - from the top of the sort bar over the list (IDC 17) down to the bottom of the
 * list, read from those controls themselves, so it follows the player's interface size and whatever ACE
 * changes about them. Without a sort bar it starts where the list does. As wide as the inventory's grid,
 * STORAGE_COLS cells of the engine's size (einv_gui_fnc_getCell) with the column's padding and scroll bar
 * beside them, at most a third of the screen and never past the screen's left edge. A large tile scale
 * (einv_gui_cellScale) that would not fit there is capped for this window (einv_gui_fnc_capCell): the grid
 * keeps all its columns rather than running out of the panel. A painted container (a canvas, grid=aab/acc) is
 * wider than STORAGE_COLS cells where seams open it between two compartments (einv_gui_fnc_flowCompartments):
 * the panel takes that width, and the cap counts it.
 *
 * It ends where the list ends, though ACE's message line (IDC 9) begins a little higher: the panel is as
 * long as the side lists, and a "no room" is said in the panel's own hint line as well.
 *
 * Arguments:
 * 0: ACE Arsenal's display <DISPLAY>
 * 1: The container the panel shows <OBJECT> (default: objNull)
 *
 * Return Value:
 * [x, y, w, h] on the screen, [] when ACE's list is not there <ARRAY>
 *
 * Example:
 * [findDisplay 1127001, _container] call einv_arsenal_fnc_panelRect;
 *
 * Public: No
 */

disableSerialization;

params [["_display", displayNull, [displayNull]], ["_container", objNull, [objNull]]];

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
private _padX = SQUARE(UNIT * PANEL_PAD);
private _padW = ((_padX * 2) max (_padX + SCROLL_W + pixelW * 4)) + pixelW * 2;

// What the grid may take: a third of the screen, and what lies left of ACE's list.
private _room = ((safezoneW * PANEL_MAX_SHARE) min (_listX - SQUARE(UNIT * PANEL_GAP) - safezoneX)) - _padW;

// How wide the grid is for a cell [w, h]: STORAGE_COLS cells, or a canvas's width with its seams. Only a
// container with compartments placed on a canvas is laid out for it.
private _blocks = if (isNull _container) then {[]} else {[_container] call EFUNC(storage,getBlocks)};
private _layout = createHashMapFromArray [["blocks", _blocks]];
private _canvas = _blocks findIf {(_x param [3, []]) isNotEqualTo []} >= 0;

private _fnc_gridW = {
    params ["_cell"];

    private _plain = STORAGE_COLS * (_cell select 0);

    if (!_canvas) exitWith {_plain};

    _plain max (([_layout, _cell] call EFUNC(gui,flowCompartments)) select 2)
};

// So many cells across at the cell the window has now; the cap divides the room by that.
private _cell = call EFUNC(gui,getCell);
private _across = ([_cell] call _fnc_gridW) / (_cell select 0);

([_room / _across / pixelW, "the Arsenal panel beside ACE's list"] call EFUNC(gui,capCell)) params ["_cellW", "_cellH"];

private _width = (([[_cellW, _cellH]] call _fnc_gridW) + _padW) min (safezoneW * PANEL_MAX_SHARE);

private _left = _listX - SQUARE(UNIT * PANEL_GAP) - _width;

[SNAP_X(_left), SNAP_Y(_top), SNAP_W(_width), SNAP_H(_bottom - _top)]
