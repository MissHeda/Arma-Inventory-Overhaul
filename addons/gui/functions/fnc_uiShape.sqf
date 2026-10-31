#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Draws a shaped item's tile (size=xx/x-, aio_items_fnc_footprintAs) on its cells only: its surface, or
 * the one-pixel border around it, in the same look a rectangle has - or a shaped compartment's panel,
 * its cells grown by some pixels with its holes left open (fnc_drawCompartments). fnc_shapeRects says
 * where, on a grid where its columns and rows start (a canvas's seams).
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group to create it in <CONTROL>
 * 2: Top left corner of its box [x, y] <ARRAY>
 * 3: A cell's width, the gap to the next one included <NUMBER>
 * 4: A cell's height, the same way <NUMBER>
 * 5: Footprint as it lies, [w, h, holes] - holes the indices row * w + col <ARRAY>
 * 6: Colour <ARRAY>
 * 7: What to draw: "surface", "frame" or "panel" <STRING> (default: "surface")
 * 8: A frame set in by this many pixels; how far a panel reaches past the cells <NUMBER> (default: 0)
 * 9: On a grid: [grid, column, row] of its top left cell, see fnc_shapeRects; [] for none <ARRAY> (default: [])
 * 10: Round the runs of a surface that reach a corner of the grid's panel (fnc_cornerRadii) - only with a grid in argument 9 and
 *     only where the box is given in the grid's own group (a tile, a selection) <BOOL> (default: false)
 *
 * Return Value:
 * The controls; for a surface the first is the top row's first run (its middle piece, where that run is round) <ARRAY>
 *
 * Example:
 * [_display, _group, [_left, _top], _cellW, _cellH, [2, 2, [3]], _color] call aio_gui_fnc_uiShape;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_parent", "_origin", "_cellW", "_cellH", "_footprint", "_color", ["_part", "surface"], ["_inset", 0], ["_on", []], ["_round", false]];

private _rects = [_origin, _cellW, _cellH, _footprint, _part, _inset, _on] call FUNC(shapeRects);
private _grid = _on param [0, createHashMap];

// A run of a surface that touches a corner of the panel is round there (fnc_uiSurface); a frame stays square.
if (_round && {_part isEqualTo "surface"} && {_grid isEqualType createHashMap} && {(_grid getOrDefault ["corner", 0]) >= 2}) exitWith {
    private _controls = [];

    {
        _controls append ([_display, _parent, _x, _color, [_grid, _x] call FUNC(cornerRadii)] call FUNC(uiSurface));
    } forEach _rects;

    _controls
};

_rects apply {
    private _ctrl = [_display, "AIO_PanelRect", _parent, _x] call FUNC(uiCreate);

    _ctrl ctrlSetBackgroundColor _color;
    _ctrl
}
