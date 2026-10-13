#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Draws a shaped item's tile (size=xx/x-, einv_items_fnc_footprintAs) on its cells only: its surface, or
 * the one-pixel border around it, in the same look a rectangle has (fnc_shapeRects says where).
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group to create it in <CONTROL>
 * 2: Top left corner of its box [x, y] <ARRAY>
 * 3: A cell's width, the gap to the next one included <NUMBER>
 * 4: A cell's height, the same way <NUMBER>
 * 5: Footprint as it lies, [w, h, holes] - holes the indices row * w + col <ARRAY>
 * 6: Colour <ARRAY>
 * 7: What to draw: "surface" or "frame" <STRING> (default: "surface")
 * 8: A frame set in by this many pixels <NUMBER> (default: 0)
 * 9: Seams under it - [colX, rowY] from fnc_spanSeams, [] for the plain pitch <ARRAY> (default: [])
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

params ["_display", "_parent", "_origin", "_cellW", "_cellH", "_footprint", "_color", ["_part", "surface"], ["_inset", 0], ["_seams", []]];

([_origin, _cellW, _cellH, _footprint, _part, _inset, _seams] call FUNC(shapeRects)) apply {
    private _ctrl = [_display, "EINV_PanelRect", _parent, _x] call FUNC(uiCreate);

    _ctrl ctrlSetBackgroundColor _color;
    _ctrl
}
