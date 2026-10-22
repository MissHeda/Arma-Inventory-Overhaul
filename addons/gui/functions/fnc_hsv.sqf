#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Converts a colour between RGB and HSV, for the palette (fnc_palette, fnc_openPaletteMenu): a colour is picked there by its
 * hue and its vividness, and the theme wants it as RGB. All numbers are 0 to 1, the hue too (a full turn round the colour
 * wheel: 0 red, 1/3 green, 2/3 blue, 1 red again).
 *
 *   "rgb"  from [hue, saturation, value] to [r, g, b]
 *   "hsv"  from [r, g, b] to [hue, saturation, value]
 *
 * Arguments:
 * 0: Which way, "rgb" or "hsv" <STRING>
 * 1: The colour, three numbers (a fourth, the alpha, is ignored) <ARRAY>
 *
 * Return Value:
 * The colour, three numbers <ARRAY>
 *
 * Example:
 * ["rgb", [0.5, 1, 1]] call einv_gui_fnc_hsv;
 *
 * Public: No
 */

params [["_way", "rgb", [""]], ["_color", [0, 0, 0], [[]]]];

_color params [["_a", 0, [0]], ["_b", 0, [0]], ["_c", 0, [0]]];

if (_way isEqualTo "hsv") exitWith {
    private _top = _a max _b max _c;
    private _bottom = _a min _b min _c;
    private _span = _top - _bottom;
    private _hue = 0;

    if (_span > 0) then {
        // Which sixth of the wheel the colour lies in, and how far along it. Never a negative number into the division by 6.
        private _sixths = if (_top == _a) then {
            (_b - _c) / _span
        } else {
            if (_top == _b) then {(_c - _a) / _span + 2} else {(_a - _b) / _span + 4}
        };

        if (_sixths < 0) then {
            _sixths = _sixths + 6;
        };

        _hue = (_sixths / 6) min 1;
    };

    [_hue, if (_top > 0) then {_span / _top} else {0}, _top]
};

// The hue as a position on the wheel, wrapped (1 is red again, as 0 is).
private _wheel = (_a - floor _a) * 6;
private _sector = floor _wheel;
private _along = _wheel - _sector;

private _low = _c * (1 - _b);
private _fall = _c * (1 - _b * _along);
private _rise = _c * (1 - _b * (1 - _along));

switch (_sector) do {
    case 0: {[_c, _rise, _low]};
    case 1: {[_fall, _c, _low]};
    case 2: {[_low, _c, _rise]};
    case 3: {[_low, _fall, _c]};
    case 4: {[_rise, _low, _c]};
    default {[_c, _low, _fall]};
}
