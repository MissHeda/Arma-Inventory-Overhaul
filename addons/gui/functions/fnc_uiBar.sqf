#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Creates a bar: a track along its whole length and a fill from the left for how full it is. With a
 * radius both have round ends; the fill never gets shorter than its two ends, so a nearly empty bar
 * still shows a dot rather than broken corners. An empty bar shows only its track.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group to create it in, or controlNull for the display <CONTROL>
 * 2: Position [x, y, w, h] <ARRAY>
 * 3: How full, 0 to 1 - more is drawn as full <NUMBER>
 * 4: Track colour, [] for none <ARRAY>
 * 5: Fill colour <ARRAY>
 * 6: Corner radius, as a height <NUMBER> (default: 0)
 *
 * Return Value:
 * The controls, the track's first <ARRAY>
 *
 * Example:
 * [_display, controlNull, [0.1, 0.1, 0.2, 0.005], 0.4, [1, 1, 1, 0.1], [1, 1, 1, 0.8], 0.0025] call aio_gui_fnc_uiBar;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_parent", "_rect", "_fraction", "_track", "_fill", ["_radius", 0], ["_gradient", 0]];
_rect params ["_left", "_top", "_width", "_height"];

private _controls = [_display, _parent, _rect, _track, _radius] call FUNC(uiPanel);

if (_fraction > 0) then {
    // Both round ends of the fill are as wide as they are high - a quarter circle each side.
    private _ends = SQUARE(_radius min (_height / 2)) * 2;
    private _length = (_width * (_fraction min 1)) max _ends max pixelW;

    private _fillParts = [_display, _parent, [_left, _top, _length, _height], _fill, _radius] call FUNC(uiPanel);

    _controls append _fillParts;

    // The fill in the gradient where the colour panel switched the bars on (argument 7, GRADIENT_BARS).
    _controls append ([_display, _parent, [_left, _top, _length, _height], _gradient, _fillParts, _fill param [3, 1], _radius] call FUNC(gradientSurface));
};

_controls
