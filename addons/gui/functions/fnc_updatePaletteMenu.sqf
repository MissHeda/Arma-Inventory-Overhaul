#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Shows what the palette is set to in the popover under the palette button (fnc_openPaletteMenu), in place: the open picker's
 * cursors, the pure hue under its colour square and its fields (red, green, blue and hex), the transparency slider's knob, fill and
 * value, every row's swatch, and the buttons that take a choice away, which show only while there is one. The rows are found by
 * their ids (PALETTE_IDS, and "alpha" for the transparency). Asked whenever a value changes (fnc_paletteSet), so a picker follows
 * the mouse without the popover being made again, and by the popover itself when it is made. Nothing happens while it is not open.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call einv_gui_fnc_updatePaletteMenu;
 *
 * Public: No
 */

disableSerialization;

private _rows = uiNamespace getVariable [QGVAR(paletteRows), createHashMap];

if (count _rows == 0) exitWith {};

private _info = [] call FUNC(paletteInfo);
private _hsvs = _info get "hsv";
private _rgbs = _info get "rgb";
private _alpha = _info get "alpha";

// ----- The open picker, bound to one colour -----
private _tab = _rows getOrDefault ["tab", -1];
private _picker = _rows getOrDefault ["picker", createHashMap];

if (count _picker > 0 && {_tab >= 0} && {_tab < PALETTE_COLOURS}) then {
    (_hsvs select _tab) params ["_hue", "_saturation", "_value"];

    // The square: the pure hue under the white and black fades; a surface's square shows only the values up to its cut.
    (_picker getOrDefault ["base", controlNull]) ctrlSetBackgroundColor ((["rgb", [_hue, 1, 1]] call FUNC(hsv)) + [1]);

    private _valueMax = PALETTE_VALUE_MAX select _tab;

    // The cursors: a ring each (cursor_ring_ca, its dark rim drawn in it), centred on the colour.
    (_picker getOrDefault ["squareGeo", []]) params ["_left", "_top", "_width", "_height", "_knobW", "_knobH"];

    private _squareKnob = _picker getOrDefault ["squareKnob", controlNull];

    _squareKnob ctrlSetPosition [
        _left + _width * _saturation - _knobW / 2, _top + _height * (1 - ((_value / _valueMax) min 1)) - _knobH / 2, _knobW, _knobH
    ];
    _squareKnob ctrlCommit 0;

    // The hue strip's cursor, on its middle.
    (_picker getOrDefault ["hueGeo", []]) params ["_stripLeft", "_stripTop", "_stripWidth", "_stripHeight", "_hueKnobW", "_hueKnobH"];

    private _hueKnob = _picker getOrDefault ["hueKnob", controlNull];

    _hueKnob ctrlSetPosition [_stripLeft + (_stripWidth - _hueKnobW) / 2, _stripTop + _stripHeight * _hue - _hueKnobH / 2, _hueKnobW, _hueKnobH];
    _hueKnob ctrlCommit 0;

    // The fields: red, green, blue, and the hex code.
    private _bytes = (_rgbs select _tab) apply {round (_x * 255)};
    private _digits = "0123456789ABCDEF";
    private _hex = "#" + (_bytes apply {(_digits select [floor (_x / 16), 1]) + (_digits select [_x mod 16, 1])} joinString "");

    (_picker getOrDefault ["fields", []]) params [["_red", controlNull], ["_green", controlNull], ["_blue", controlNull], ["_hexField", controlNull]];

    _red ctrlSetText str (_bytes select 0);
    _green ctrlSetText str (_bytes select 1);
    _blue ctrlSetText str (_bytes select 2);
    _hexField ctrlSetText _hex;
};

// ----- The transparency slider -----
(_rows getOrDefault ["alpha", []]) params [["_thumbs", []], ["_geo", []], ["_valueText", controlNull], ["_fill", controlNull]];

if (_thumbs isNotEqualTo []) then {
    _geo params ["_trackLeft", "_trackTop", "_trackWidth", "_trackHeight", "_thumbW", "_thumbH", "_thumbTop"];

    // How far along its track the knob stands, 0 to 1 (an alpha of 1 is 0).
    private _place = (((1 - _alpha) / (1 - PALETTE_ALPHA_MIN)) max 0) min 1;
    private _thumbX = _trackLeft + _trackWidth * _place - _thumbW / 2;

    // The knob is two circles: the dark ring a little larger than the white one.
    (_thumbs select 0) ctrlSetPosition [_thumbX - pixelW * 2, _thumbTop - pixelH * 2, _thumbW + pixelW * 4, _thumbH + pixelH * 4];
    (_thumbs select 0) ctrlCommit 0;
    (_thumbs select 1) ctrlSetPosition [_thumbX, _thumbTop, _thumbW, _thumbH];
    (_thumbs select 1) ctrlCommit 0;

    _valueText ctrlSetText (str round ((1 - _alpha) * 100) + " %");

    // The fill of the track.
    _fill ctrlSetPosition [_trackLeft, _trackTop, _trackWidth * _place, _trackHeight];
    _fill ctrlCommit 0;
    _fill ctrlShow (_place > 0);
};

// ----- The swatches: each colour as it is set or worn, and the panels as they are with the alpha over a grey -----
private _swatches = _rows getOrDefault ["swatches", createHashMap];
private _worn = _info get "swatch";

{
    [_swatches getOrDefault [_x, []], (_worn select _forEachIndex) + [1]] call FUNC(paintSurface);
} forEach PALETTE_IDS;

[_swatches getOrDefault ["alpha", []], (_worn select 2) + [_alpha]] call FUNC(paintSurface);

// What can be taken away shows its button: the colours by their number, then the transparency ("set" is in that order).
private _chosen = _info get "set";
private _chips = _rows getOrDefault ["chips", createHashMap];

{
    private _on = _chosen select _forEachIndex;

    {_x ctrlShow _on} forEach (_chips getOrDefault [_x, []]);
} forEach (PALETTE_IDS + ["alpha"]);

{_x ctrlShow (_info get "any")} forEach (_rows getOrDefault ["resetAll", []]);
