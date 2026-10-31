#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Shows what the palette is set to in the popover under the palette button (fnc_openPaletteMenu), in place: the open picker's
 * cursors, the pure hue under its colour square and its fields (red, green, blue and hex), the knob, fill and value of each of the two
 * transparency sliders (the panels' and the item tiles'), every row's swatch, and the buttons that take a choice away, which show only
 * while there is one. The rows are found by their ids (PALETTE_IDS, and "alpha" and "tileAlpha" for the transparencies). Asked whenever a value changes (fnc_paletteSet), so a picker follows
 * the mouse without the popover being made again, and by the popover itself when it is made. Nothing happens while it is not open.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call aio_gui_fnc_updatePaletteMenu;
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
private _tileAlpha = _info get "tileAlpha";
private _cellAlpha = _info get "cellAlpha";
private _secondaryAlpha = _info get "secondaryAlpha";
private _linesAlpha = _info get "linesAlpha";

// ----- The open picker, bound to one colour -----
private _tab = _rows getOrDefault ["tab", -1];
private _picker = _rows getOrDefault ["picker", createHashMap];

if (count _picker > 0 && {_tab >= 0} && {_tab < PALETTE_COLOURS + GRADIENT_PART_COLOURS}) then {
    (_hsvs select _tab) params ["_hue", "_saturation", "_value"];

    // The square: the pure hue under the white and black fades; a surface's square shows only the values up to its cut.
    (_picker getOrDefault ["base", controlNull]) ctrlSetBackgroundColor ((["rgb", [_hue, 1, 1]] call FUNC(hsv)) + [1]);

    private _valueMax = PALETTE_VALUE_MAX param [_tab, 1];

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

// ----- The transparency sliders -----
private _sliders = _rows getOrDefault ["sliders", createHashMap];

{
    _x params ["_id", "_shown"];

    (_sliders getOrDefault [_id, []]) params [["_thumbs", []], ["_geo", []], ["_valueText", controlNull], ["_fill", controlNull]];

    if (_thumbs isNotEqualTo []) then {
        _geo params ["_trackLeft", "_trackTop", "_trackWidth", "_trackHeight", "_thumbW", "_thumbH", "_thumbTop"];

        // How far along its track the knob stands, 0 to 1 (an alpha of 1 is 0, an alpha of PALETTE_ALPHA_MIN - fully see-through - 1).
        private _place = (((1 - _shown) / (1 - PALETTE_ALPHA_MIN)) max 0) min 1;
        private _thumbX = _trackLeft + _trackWidth * _place - _thumbW / 2;

        // The knob is two circles: the dark ring a little larger than the white one.
        (_thumbs select 0) ctrlSetPosition [_thumbX - pixelW * 2, _thumbTop - pixelH * 2, _thumbW + pixelW * 4, _thumbH + pixelH * 4];
        (_thumbs select 0) ctrlCommit 0;
        (_thumbs select 1) ctrlSetPosition [_thumbX, _thumbTop, _thumbW, _thumbH];
        (_thumbs select 1) ctrlCommit 0;

        _valueText ctrlSetText (str round ((1 - _shown) * 100) + " %");

        // The fill of the track.
        _fill ctrlSetPosition [_trackLeft, _trackTop, _trackWidth * _place, _trackHeight];
        _fill ctrlCommit 0;
        _fill ctrlShow (_place > 0);
    };
} forEach [
    ["alpha", _alpha], ["cellAlpha", _cellAlpha], ["tileAlpha", _tileAlpha], ["secondaryAlpha", _secondaryAlpha], ["linesAlpha", _linesAlpha]
];

// ----- The swatches: each colour as it is set or worn; the panels, the cells and the tiles with their alpha over a grey -----
private _swatches = _rows getOrDefault ["swatches", createHashMap];
private _worn = _info get "swatch";

// The open row's Start and End boxes: the colours of the row the picker belongs to.
private _openPair = (createHashMapFromArray [["titles", [8, 7]], ["panel", [2, 9]]]) getOrDefault [uiNamespace getVariable [QGVAR(paletteOpen), ""], [8, 7]];

{
    _x params ["_id", "_which", "_shownAlpha"];

    [_swatches getOrDefault [_id, []], (_worn select _which) + [_shownAlpha]] call FUNC(paintSurface);
} forEach [
    ["accent", 0, 1], ["titles", 8, 1], ["titlesEnd", 7, 1], ["secondary", 1, _secondaryAlpha], ["panel", 2, _alpha],
    ["panelEnd", 9, _alpha], ["cells", 3, _cellAlpha], ["items", 4, _tileAlpha], ["text", 5, 1], ["lines", 6, _linesAlpha],
    ["gradStart", _openPair select 0, 1], ["gradEnd", _openPair select 1, 1]
];

// The parts' pills in the titles' checkboxes, and the Start and End of the part picked for colours of its own (fnc_openPaletteMenu).
for "_part" from 0 to (GRADIENT_PART_COUNT - 1) do {
    [_swatches getOrDefault [format ["part%1", _part], []], (_worn select (PALETTE_COLOURS + _part * 2)) + [1]] call FUNC(paintSurface);
    [_swatches getOrDefault [format ["part%1End", _part], []], (_worn select (PALETTE_COLOURS + _part * 2 + 1)) + [1]] call FUNC(paintSurface);
};

private _partPick = uiNamespace getVariable [QGVAR(palettePart), -1];

if (_partPick isEqualType 0 && {_partPick >= 0} && {_partPick < GRADIENT_PART_COUNT}) then {
    [_swatches getOrDefault ["partStart", []], (_worn select (PALETTE_COLOURS + _partPick * 2)) + [1]] call FUNC(paintSurface);
    [_swatches getOrDefault ["partEnd", []], (_worn select (PALETTE_COLOURS + _partPick * 2 + 1)) + [1]] call FUNC(paintSurface);
};

// What can be taken away shows its button, by row: what each row's button takes back ("set" holds the colours by their number,
// 0 to 9, then the transparencies of the panels, the tiles, the cells, the secondary films and the lines, 10 to 14).
private _chosen = _info get "set";
private _chips = _rows getOrDefault ["chips", createHashMap];

{
    _x params ["_id", "_places"];

    private _on = (_places findIf {_chosen select _x}) >= 0;

    {_x ctrlShow _on} forEach (_chips getOrDefault [_id, []]);
} forEach [
    ["accent", [0]], ["titles", [8, 7]], ["secondary", [1, 13]], ["panel", [2, 9, 10]], ["cells", [3, 12]], ["items", [11]],
    ["text", [5]], ["lines", [6, 14]]
];

// Reset all only where there is something to take back to the window as it ships.
{_x ctrlShow (GVAR(palette) isNotEqualTo PALETTE_DEFAULT)} forEach (_rows getOrDefault ["resetAll", []]);
