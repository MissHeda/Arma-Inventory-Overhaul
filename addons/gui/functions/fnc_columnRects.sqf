#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Where the window's columns stand, on the screen: for its layout (fnc_layoutGlass), the picture on the settings card
 * (fnc_openSizeMenu) and the edit mode (fnc_openLayoutEditor), so all three show the same.
 *
 * From left to right as the player's order has it (aio_gui_columnOrder), the free middle one of them, which takes what the others
 * leave. Where the loot column goes beside the storage column is the setting aio_gui_lootSide: right swaps the two. The middle
 * gives way first where the screen is too narrow, then the equipment column - nothing overlaps.
 *
 * A column the player placed himself in the edit mode (aio_gui_layoutRects) stands where he put it, as shares of the content area
 * so it holds on another resolution. It is kept on the screen and no smaller than fnc_columnMinimum says; columns placed by hand may
 * overlap. The free middle is then the widest gap they leave.
 *
 * A part of the equipment column - the weight, the weapons, the gear, the hotbar (EQUIPMENT_PARTS) - placed on its own has a rect
 * here too, while it is drawn (fnc_partShown); one that is not stays in the equipment column and has none.
 *
 * A window that keeps the right edge for itself ("rightColumn", fnc_layoutGlass) has no say in any of it: the usual order, its column
 * at that edge, nothing placed by hand.
 *
 * Arguments:
 * 0: A loot column is drawn or kept <BOOL> (default: false)
 * 1: The loot column's width, -1 for the usual <NUMBER> (default: -1)
 * 2: The right edge is kept by the window that attached <BOOL> (default: false)
 *
 * Return Value:
 * "equipment", "storage", "loot", "middle" and the parts placed on their own - each [x, y, w, h] <HASHMAP>
 *
 * Example:
 * private _rects = [true] call aio_gui_fnc_columnRects;
 *
 * Public: No
 */

params [["_reserved", false, [false]], ["_rightW", -1, [0]], ["_keepRight", false, [false]]];

(call FUNC(getCell)) params ["_cellW"];

private _gap = COLUMN_GAP;
private _columnW = COLUMN_W(_cellW);
private _leftW = (safezoneW * 0.3) min SQUARE(UNIT * 22);

if (_rightW < 0) then {
    _rightW = _columnW;
};

private _order = (missionNamespace getVariable [QGVAR(columnOrder), COLUMN_ORDER_DEFAULT]) splitString ",";

if (_keepRight || {count _order != 4}) then {
    _order = COLUMN_ORDER_DEFAULT splitString ",";
};

if (_keepRight || {(missionNamespace getVariable [QGVAR(lootSide), "left"]) isEqualTo "right"}) then {
    private _lootAt = _order find "loot";

    _order set [_order find "storage", "loot"];
    _order set [_lootAt, "storage"];
};

if (!_reserved) then {
    _order = _order - ["loot"];
};

private _freeW = CONTENT_W - _leftW - _columnW - ([0, _rightW] select _reserved) - _gap * (count _order - 1);

if (_freeW < 0) then {
    _leftW = (_leftW + _freeW) max 0;
    _freeW = 0;
};

private _rects = createHashMap;
private _cursorX = CONTENT_X;

// Not looting, the loot column has no place in the order: it still gets one, under the storage column's, for who asks.
_rects set ["loot", [CONTENT_X + CONTENT_W - _rightW, CONTENT_Y, _rightW, CONTENT_H]];

{
    private _width = createHashMapFromArray [["equipment", _leftW], ["loot", _rightW], ["storage", _columnW], ["free", _freeW]] get _x;

    _rects set [["middle", _x] select (_x isNotEqualTo "free"), [_cursorX, CONTENT_Y, _width, CONTENT_H]];
    _cursorX = _cursorX + _width + _gap;
} forEach _order;

if (_keepRight) exitWith {_rects};

// ----- Placed by hand -----

private _placed = false;

{
    private _parts = _x splitString ":";

    if (count _parts == 2) then {
        _parts params ["_id", "_values"];

        private _shares = (_values splitString ",") apply {parseNumber _x};

        if (count _shares == 4 && {_id in ["equipment", "storage", "loot"] || {_id in EQUIPMENT_PARTS && {[_id] call FUNC(partShown)}}}) then {
            _shares params ["_shareX", "_shareY", "_shareW", "_shareH"];

            ([_id, _columnW] call FUNC(columnMinimum)) params ["_leastW", "_leastH"];

            private _w = ((_shareW * CONTENT_W) max _leastW) min CONTENT_W;
            private _h = ((_shareH * CONTENT_H) max _leastH) min CONTENT_H;
            private _x0 = ((CONTENT_X + _shareX * CONTENT_W) max CONTENT_X) min (CONTENT_X + CONTENT_W - _w);
            private _y0 = ((CONTENT_Y + _shareY * CONTENT_H) max CONTENT_Y) min (CONTENT_B - _h);

            _rects set [_id, [_x0, _y0, _w, _h]];
            _placed = true;
        };
    };
} forEach ((missionNamespace getVariable [QGVAR(layoutRects), ""]) splitString ";");

if (!_placed) exitWith {_rects};

// The free middle: the widest gap the columns leave across the content area.
private _spans = ((["equipment", "storage"] + ([[], ["loot"]] select _reserved) + EQUIPMENT_PARTS) select {_x in _rects}) apply {
    (_rects get _x) params ["_x0", "", "_w"];

    [_x0, _x0 + _w]
};

_spans sort true;

private _edge = CONTENT_X;
private _bestX = CONTENT_X;
private _bestW = 0;

{
    _x params ["_from", "_to"];

    if ((_from - _edge) > _bestW) then {
        _bestX = _edge;
        _bestW = _from - _edge;
    };

    _edge = _edge max _to;
} forEach _spans;

if ((CONTENT_X + CONTENT_W - _edge) > _bestW) then {
    _bestX = _edge;
    _bestW = CONTENT_X + CONTENT_W - _edge;
};

_rects set ["middle", [_bestX, CONTENT_Y, _bestW, CONTENT_H]];

_rects
