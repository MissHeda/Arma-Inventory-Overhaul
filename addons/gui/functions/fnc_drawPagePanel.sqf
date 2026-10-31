#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The panel behind the cells of a paged compartment's page (fnc_drawCompartments): the faint card of any compartment,
 * from the first cell to the last of the rows [from, to) and COMPARTMENT_PAD_PX pixels past them - or for a shaped
 * compartment the cells of those rows grown by the pad with its holes left open (fnc_uiShape). A page turned (fnc_showPage)
 * draws it anew. The panel runs down to the page bar (fnc_drawPageBar), which is its bottom part (Mia, 0.5.10): it covers as
 * many rows as the tallest page has, so the last page, which can have fewer rows, leaves no gap above the bar, and ends exactly
 * where the bar starts (PAGE_BAR_TOP), square at the bottom - the bar has the round bottom corners. The top corners are round.
 * A paged compartment is never on a canvas, so its columns lie at the plain pitch.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group to draw in <CONTROL>
 * 2: Top left corner of the page's first cell [x, y] in the group <ARRAY>
 * 3: Columns <NUMBER>
 * 4: First row of the page <NUMBER>
 * 5: The row after its last <NUMBER>
 * 6: The compartment's holes, indices row * cols + col over all its rows <ARRAY>
 * 7: Theme <HASHMAP>
 * 8: Rows the panel covers (the tallest page's) <NUMBER> (default: the page's own)
 *
 * Return Value:
 * The controls <ARRAY>
 *
 * Example:
 * [_display, _group, [0.1, 0.2], 10, 10, 20, [], _theme] call aio_gui_fnc_drawPagePanel;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_parent", "_corner", "_cols", "_from", "_to", ["_holes", []], "_theme", ["_pageRows", 0]];
_corner params ["_x0", "_y0"];

(call FUNC(getCell)) params ["_cellW", "_cellH"];

private _rows = (_to - _from) max _pageRows;

if (_to <= _from || {_cols <= 0}) exitWith {[]};

private _pad = COMPARTMENT_PAD_PX(_cellW);
private _padW = _pad * pixelW;
private _padH = _pad * pixelH;
private _radius = (_theme getOrDefault ["radius", 0]) min (_pad * 3 * pixelH);
private _color = _theme getOrDefault ["card", []];

if (_color isEqualTo []) then {
    _color = _theme getOrDefault ["line", [1, 1, 1, 0.07]];
};

// The holes of the rows of this page, as indices from the page's first cell.
private _pageHoles = (_holes select {_x >= _from * _cols && {_x < _to * _cols}}) apply {_x - _from * _cols};

if (_pageHoles isEqualTo []) exitWith {
    private _right = _x0 + (_cols - 1) * _cellW + _cellW - pixelW;
    private _bottom = _y0 + (_rows - 1) * _cellH + _cellH - pixelH;

    // Round at the top corners only: the bar under it has the bottom ones.
    [
        _display, _parent, [_x0 - _padW, _y0 - _padH, _right - _x0 + _padW * 2, _bottom - _y0 + _padH * 2], _color,
        [_radius / pixelH, [true, true, false, false]]
    ] call FUNC(uiSurface)
};

private _colX = [];
private _rowY = [];

for "_col" from 0 to (_cols - 1) do {_colX pushBack (_col * _cellW)};
for "_row" from 0 to (_rows - 1) do {_rowY pushBack (_row * _cellH)};

[
    _display, _parent, [_x0, _y0], _cellW, _cellH, [_cols, _rows, _pageHoles], _color, "panel", _pad,
    [createHashMapFromArray [["colX", _colX], ["rowY", _rowY]], 0, 0]
] call FUNC(uiShape)
