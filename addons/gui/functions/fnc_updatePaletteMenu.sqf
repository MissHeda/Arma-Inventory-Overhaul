#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Shows what the palette is set to in the popover under the palette button (fnc_openPaletteMenu), in place: the open picker's
 * cursors, the pure hue under its colour square and its fields (red, green, blue and hex), the transparency slider's knob, fill and
 * value, the swatches, and the buttons that take a choice away, which show only while there is one. Asked whenever a value
 * changes (fnc_paletteSet), so a picker follows the mouse without the popover being made again, and by the popover itself when it
 * is made. Nothing happens while it is not open.
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

(_info get "hsv") params ["_accentHsv", "_secondaryHsv", "_panelHsv"];

private _hsvs = [_accentHsv, _secondaryHsv, _panelHsv];
private _rgbs = _info get "rgb";
private _alpha = _info get "alpha";

// ----- The open colour's picker -----
private _tab = _rows get "tab";
private _picker = _rows get "picker";

if (count _picker > 0 && {_tab >= 0} && {_tab <= 2}) then {
    (_hsvs select _tab) params ["_hue", "_saturation", "_value"];

    // The square: the pure hue under the white and black fades; the panels' square shows only the value up to PALETTE_PANEL_VALUE_MAX.
    (_picker get "base") ctrlSetBackgroundColor ((["rgb", [_hue, 1, 1]] call FUNC(hsv)) + [1]);

    private _valueMax = [1, 1, PALETTE_PANEL_VALUE_MAX] select _tab;

    (_picker get "squareGeo") params ["_left", "_top", "_width", "_height", "_knobW", "_knobH"];
    (_picker get "squareKnob") params ["_ring", "_knob"];

    private _knobX = _left + _width * _saturation - _knobW / 2;
    private _knobY = _top + _height * (1 - ((_value / _valueMax) min 1)) - _knobH / 2;

    // The knob is two circles: the dark ring a little larger than the white one.
    _ring ctrlSetPosition [_knobX - pixelW * 2, _knobY - pixelH * 2, _knobW + pixelW * 4, _knobH + pixelH * 4];
    _ring ctrlCommit 0;
    _knob ctrlSetPosition [_knobX, _knobY, _knobW, _knobH];
    _knob ctrlCommit 0;

    // The hue strip's knob, on its middle.
    (_picker get "hueGeo") params ["_stripLeft", "_stripTop", "_stripWidth", "_stripHeight", "_hueKnobW", "_hueKnobH"];
    (_picker get "hueKnob") params ["_hueRing", "_hueDot"];

    private _dotX = _stripLeft + (_stripWidth - _hueKnobW) / 2;
    private _dotY = _stripTop + _stripHeight * _hue - _hueKnobH / 2;

    _hueRing ctrlSetPosition [_dotX - pixelW * 2, _dotY - pixelH * 2, _hueKnobW + pixelW * 4, _hueKnobH + pixelH * 4];
    _hueRing ctrlCommit 0;
    _hueDot ctrlSetPosition [_dotX, _dotY, _hueKnobW, _hueKnobH];
    _hueDot ctrlCommit 0;

    // The fields: red, green, blue, and the hex code.
    private _bytes = (_rgbs select _tab) apply {round (_x * 255)};
    private _digits = "0123456789ABCDEF";
    private _hex = "#" + (_bytes apply {(_digits select [floor (_x / 16), 1]) + (_digits select [_x mod 16, 1])} joinString "");

    (_picker get "fields") params ["_red", "_green", "_blue", "_hexField"];

    _red ctrlSetText str (_bytes select 0);
    _green ctrlSetText str (_bytes select 1);
    _blue ctrlSetText str (_bytes select 2);
    _hexField ctrlSetText _hex;
};

// ----- The transparency slider -----
(_rows get "alpha") params ["_thumbs", "_geo", "_valueText", "_fill"];
_geo params ["_trackLeft", "_trackTop", "_trackWidth", "_trackHeight", "_thumbW", "_thumbH", "_thumbTop"];

// How far along its track the knob stands, 0 to 1 (an alpha of 1 is 0).
private _place = (((1 - _alpha) / (1 - PALETTE_ALPHA_MIN)) max 0) min 1;
private _thumbX = _trackLeft + _trackWidth * _place - _thumbW / 2;

(_thumbs select 0) ctrlSetPosition [_thumbX - pixelW * 2, _thumbTop - pixelH * 2, _thumbW + pixelW * 4, _thumbH + pixelH * 4];
(_thumbs select 0) ctrlCommit 0;
(_thumbs select 1) ctrlSetPosition [_thumbX, _thumbTop, _thumbW, _thumbH];
(_thumbs select 1) ctrlCommit 0;

_valueText ctrlSetText (str round ((1 - _alpha) * 100) + " %");

// The fill of the track.
_fill ctrlSetPosition [_trackLeft, _trackTop, _trackWidth * _place, _trackHeight];
_fill ctrlCommit 0;
_fill ctrlShow (_place > 0);

// ----- The swatches: the accent, the secondary colour and the panels' colour, and the panels as they are with the alpha over a grey -----
private _swatches = _rows get "swatches";
private _worn = _info get "swatch";

{
    [_swatches select _forEachIndex, _x + [1]] call FUNC(paintSurface);
} forEach _worn;

[_swatches select 3, (_worn select 2) + [_alpha]] call FUNC(paintSurface);

// What can be taken away shows its button.
private _chosen = _info get "set";

{
    private _on = _chosen select _forEachIndex;

    {_x ctrlShow _on} forEach _x;
} forEach (_rows get "chips");

{_x ctrlShow (_info get "any")} forEach (_rows get "resetAll");
