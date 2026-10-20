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
 * Then the player's tile scale (einv_gui_cellScale, 0.8 to 1.3): small pictures are hard to make out on
 * some screens. Larger cells widen both columns, so the scale goes only as far as both of them, their gaps
 * and CELL_FIT_LEFT UNITs of the equipment column still fit across - the largest that fits, said once in the
 * RPT, never less than the cell at scale 1 (a 4:3 screen keeps the layout it had). ACE Arsenal's panel, which
 * has less room, caps it further for its window (fnc_capCell).
 * The window's words grow with the cell this gives (fnc_textScale, TEXT_UNIT).
 *
 * Worked out at the first ask after a window attached (fnc_attach) and kept until it closes
 * (uiNamespace einv_gui_cell): a changed setting takes effect at the next opening, and nothing drawn
 * meanwhile - a tile drawn again, the dragged ghost - can differ by a pixel from the grid it lies on.
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

private _kept = uiNamespace getVariable [QGVAR(cell), []];

if (_kept isNotEqualTo []) exitWith {+_kept};

private _base = CELL_BASE_PX;

// Read from the mission namespace: grids are drawn in Eden as well, where CBA runs no settings.
private _scale = missionNamespace getVariable [QGVAR(cellScale), 1];

if !(_scale isEqualType 0) then {
    _scale = 1;
};

_scale = (_scale max CELL_SCALE_MIN) min CELL_SCALE_MAX;

private _pixels = round (_base * _scale);

// The most a cell may have: what is left across for the cells of two columns once their fixed parts, the
// three gaps and the equipment column's least width are taken.
private _room = CONTENT_W - COLUMN_GAP * 3 - (SQUARE(UNIT * CELL_FIT_LEFT) min (safezoneW * 0.3)) - COLUMN_W(0) * 2;
private _most = (floor (_room / ((STORAGE_COLS + 3) * 2) / pixelW)) max _base;

if (_pixels > _most) then {
    private _note = format ["%1 %2 %3", _scale, _pixels, _most];

    if ((missionNamespace getVariable [QGVAR(cellNote), ""]) isNotEqualTo _note) then {
        GVAR(cellNote) = _note;
        INFO_3("Tile scale %1 does not fit this resolution and interface size: cells of %2 px instead of %3 px.",_scale,_most,_pixels);
    };

    _pixels = _most;
};

private _cell = [_pixels * pixelW, _pixels * pixelH];

if (!isNull (uiNamespace getVariable [QGVAR(display), displayNull])) then {
    uiNamespace setVariable [QGVAR(cell), +_cell];
};

_cell
