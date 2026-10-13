#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The size of one grid cell on the screen. Every grid of every style uses it, so an item's tile is the
 * same size wherever it lies.
 *
 * A whole number of pixels, the same number across and down: the cell is square, and every edge of a
 * grid falls on a pixel. 1.45 rows where the screen is wide enough; on narrower screens the cells
 * shrink so 52 of them still fit across. That is what two storage columns of STORAGE_COLS (10) cells
 * with their boxes (fnc_layoutGlass), the equipment column and still the middle for the soldier take
 * while looting at 16:9: 37 pixels at 1920x1080, where 46 across gave 39 at eight columns - a cell a
 * twentieth smaller rather than a fifth (eight columns' width over ten), and the column 13 cells wide.
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

private _pixels = round (((UNIT * 1.45) min UNSQUARE(safezoneW / 52)) / pixelH);

[_pixels * pixelW, _pixels * pixelH]
