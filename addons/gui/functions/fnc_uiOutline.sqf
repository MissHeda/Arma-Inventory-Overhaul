#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Creates the outline of a tile, a free cell or a selection: nested frames, each a pixel thick and one inside the other,
 * square - or, where the box touches a corner of its compartment's panel (fnc_cornerRadii), round at that corner only
 * (fnc_uiRing with a mask), the rings as many as the thickness takes. The one place that draws it, so the hover, the
 * selection and the marks of the hands' queue look the same on a corner as elsewhere.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group to create it in, or controlNull for the display <CONTROL>
 * 2: Position [x, y, w, h] <ARRAY>
 * 3: Colour <ARRAY>
 * 4: The corners to round, as fnc_cornerRadii answers - [radius in pixels, [top left, top right, bottom left, bottom right]],
 *    [] for none <ARRAY> (default: [])
 * 5: How many pixels thick <NUMBER> (default: 2)
 *
 * Return Value:
 * The controls <ARRAY>
 *
 * Example:
 * [_display, _group, _rect, _color, [_grid, _rect] call einv_gui_fnc_cornerRadii, 2] call einv_gui_fnc_uiOutline;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_parent", "_rect", "_color", ["_corners", []], ["_thick", 2]];
_rect params ["_left", "_top", "_width", "_height"];

private _controls = [];

// Square: a frame, and another inside it.
if (_corners isEqualTo []) exitWith {
    for "_layer" from 0 to ((_thick max 1) - 1) do {
        _controls pushBack ([
            _display, _parent,
            [_left + _layer * pixelW, _top + _layer * pixelH, _width - _layer * 2 * pixelW, _height - _layer * 2 * pixelH], _color
        ] call FUNC(uiFrame));
    };

    _controls
};

_corners params ["_radius", "_mask"];

// A ring is as thick as RING_SHARE of its corner (fnc_uiRing): one thick enough does it alone, a thin one is drawn again
// inside itself, a ring nearer to the middle every time.
private _ring = (round (_radius * RING_SHARE)) max 1;

for "_layer" from 0 to ((ceil ((_thick max 1) / _ring)) max 1) - 1 do {
    private _inset = _layer * _ring;
    private _layerRadius = (_radius - _inset) max 2;

    _controls append ([
        _display, _parent,
        [_left + _inset * pixelW, _top + _inset * pixelH, _width - _inset * 2 * pixelW, _height - _inset * 2 * pixelH],
        _color, _layerRadius * pixelH, _mask
    ] call FUNC(uiRing));
};

_controls
