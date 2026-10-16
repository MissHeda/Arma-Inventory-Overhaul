#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Draws a shaped item's tile (size=xx/x-, einv_items_fnc_footprintAs) on its cells only: its surface, or
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
 *
 * Return Value:
 * The controls; for a surface the first is the top row's first run <ARRAY>
 *
 * Example:
 * [_display, _group, [_left, _top], _cellW, _cellH, [2, 2, [3]], _color] call einv_gui_fnc_uiShape;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_parent", "_origin", "_cellW", "_cellH", "_footprint", "_color", ["_part", "surface"], ["_inset", 0], ["_on", []]];

([_origin, _cellW, _cellH, _footprint, _part, _inset, _on] call FUNC(shapeRects)) apply {
    private _ctrl = [_display, "EINV_PanelRect", _parent, _x] call FUNC(uiCreate);

    _ctrl ctrlSetBackgroundColor _color;
    _ctrl
}
