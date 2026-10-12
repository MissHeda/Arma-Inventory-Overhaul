#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The size of one grid cell on the screen. Every grid of every style uses it, so an item's tile is the
 * same size wherever it lies.
 *
 * A whole number of pixels, the same number across and down: the cell is square, and every edge of a
 * grid falls on a pixel. 1.45 rows where the screen is wide enough; on narrow screens the cells shrink
 * so 46 of them still fit across.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * [width, height] in screen units <ARRAY>
 *
 * Example:
 * (call einv_gui_fnc_getCell) params ["_cellW", "_cellH"];
 *
 * Public: No
 */

private _pixels = round (((UNIT * 1.45) min UNSQUARE(safezoneW / 46)) / pixelH);

[_pixels * pixelW, _pixels * pixelH]
