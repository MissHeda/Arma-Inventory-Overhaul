#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Where a kit's window opens: next to the tile it was opened from, never over it, and where it covers
 * as little as it can of the columns and of the windows already open. The free middle comes first - a
 * kit in the vest or the backpack opens beside the storage column at the tile's height, a kit in a crate
 * likewise rather than over the column it would be unpacked into, a second kit beside the first (the
 * middle lies against whichever column is the left one of the two while looting - the loot column
 * by default, einv_gui_lootSide - so a kit from the storage column then opens one column away). A
 * window wider than the middle (16:9 and 16:10 while looting) still stands at its right edge and reaches
 * into the equipment column: it hides less of the cards there than it would of a column's grids. Then
 * left of the tile, right of it, below and above it - where the screen has no free middle (4:3 while
 * looting). Each place is kept whole inside the content band.
 *
 * Of the places that leave the tile free the one sharing the least with the panels (GVAR(panels)) and
 * the open windows wins; between two as good, the one nearer the tile. None leaves it free: left of it.
 * Opened with no tile to go by: at the free middle's right edge, else in the middle of the screen.
 *
 * Arguments:
 * 0: Size of the window [w, h] <ARRAY>
 * 1: The tile it was opened from [x, y, w, h] on the screen, [] for none <ARRAY>
 *
 * Return Value:
 * Its top left corner [x, y], on the screen's pixels <ARRAY>
 *
 * Example:
 * [[0.3, 0.2], [0.6, 0.4, 0.05, 0.05]] call einv_gui_fnc_placeWindow;
 *
 * Public: No
 */

params ["_size", ["_anchor", [], [[]]]];
_size params ["_w", "_h"];

private _gapX = SQUARE(UNIT * 0.4);
private _gapY = UNIT * 0.4;

private _fnc_clamp = {
    params ["_x0", "_y0"];

    [
        (_x0 min (CONTENT_X + CONTENT_W - _w)) max CONTENT_X,
        (_y0 min (CONTENT_B - _h)) max CONTENT_Y
    ]
};

private _fnc_snap = {
    params ["_x0", "_y0"];

    [SNAP_X(_x0), SNAP_Y(_y0)]
};

GVAR(middle) params [["_middleX", 0], "", ["_middleW", 0]];

private _hasMiddle = GVAR(middle) isNotEqualTo [];

if (_anchor isEqualTo []) exitWith {
    if (_hasMiddle) exitWith {
        ([_middleX + _middleW - _w, CONTENT_Y] call _fnc_clamp) call _fnc_snap
    };

    ([safezoneX + (safezoneW - _w) / 2, CONTENT_Y + (CONTENT_H - _h) / 2] call _fnc_clamp) call _fnc_snap
};

_anchor params ["_tileX", "_tileY", "_tileW", "_tileH"];

// How much two rectangles share.
private _fnc_shared = {
    params ["_a", "_b"];
    _a params ["_ax", "_ay", "_aw", "_ah"];
    _b params ["_bx", "_by", "_bw", "_bh"];

    private _across = ((_ax + _aw) min (_bx + _bw)) - (_ax max _bx);
    private _down = ((_ay + _ah) min (_by + _bh)) - (_ay max _by);

    (_across max 0) * (_down max 0)
};

private _candidates = [];

// The free middle: at its right edge, beside the column on its right, then a window's width further left
// each time, as long as it starts inside the middle. The first is taken even for a window wider than the
// middle: it then reaches into the equipment column rather than over a storage or loot column.
if (_hasMiddle) then {
    private _candidateX = _middleX + _middleW - _w;

    _candidates pushBack [_candidateX, _tileY];
    _candidateX = _candidateX - _w - _gapX;

    while {_candidateX >= _middleX - 0.0001} do {
        _candidates pushBack [_candidateX, _tileY];
        _candidateX = _candidateX - _w - _gapX;
    };
};

private _left = [_tileX - _gapX - _w, _tileY] call _fnc_clamp;

_candidates append [
    _left,
    [_tileX + _tileW + _gapX, _tileY],
    [_tileX, _tileY + _tileH + _gapY],
    [_tileX, _tileY - _gapY - _h]
];

// What it should not cover: the columns and the windows open already.
private _covered = +GVAR(panels);

{
    _covered pushBack (_x getOrDefault ["rect", [0, 0, 0, 0]]);
} forEach (uiNamespace getVariable [QGVAR(windows), []]);

private _tileMiddle = [_tileX + _tileW / 2, _tileY + _tileH / 2];
private _onePixel = pixelW * pixelH;
private _best = [];
private _bestScore = 1e9;
private _bestDistance = 1e9;

{
    private _corner = _x call _fnc_clamp;
    private _rect = _corner + [_w, _h];

    // Never over the tile it was opened from.
    if ([_rect, _anchor] call _fnc_shared > _onePixel) then {continue};

    private _score = 0;

    {
        _score = _score + ([_rect, _x] call _fnc_shared);
    } forEach _covered;

    // Across in screen height, so both ways count alike whatever the screen's shape.
    private _across = UNSQUARE((_corner select 0) + _w / 2 - (_tileMiddle select 0));
    private _down = (_corner select 1) + _h / 2 - (_tileMiddle select 1);
    private _distance = sqrt (_across * _across + _down * _down);

    if (_score < _bestScore - _onePixel || {abs (_score - _bestScore) <= _onePixel && {_distance < _bestDistance}}) then {
        _best = _corner;
        _bestScore = _score;
        _bestDistance = _distance;
    };
} forEach _candidates;

if (_best isEqualTo []) then {
    _best = _left;
};

_best call _fnc_snap
