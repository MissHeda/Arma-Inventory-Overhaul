#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Puts an entry on a grid as a tile: a surface in its category's colour over the cells it covers, its
 * picture, and - as the style wants them - its short name in the top right corner, what stacks its count
 * of the stack ("3/10") and a magazine its rounds. An entry not searched yet is a plain surface with a "?"
 * and a faint outline, hatched in Tarkov's look.
 *
 * A window that attached (fnc_attach) may mark a tile in its top left corner (the "tileBadge" hook).
 *
 * A magazine gets its fill bar only while it is not full and the player has the bar on
 * (einv_gui_magazineFillBar); a full one shows its rounds alone. The rounds as words ("17/30") show
 * while the player has them on (einv_gui_magazineText).
 *
 * The picture is fitted into the tile with its own shape kept. On a tile that lies turned ("rotated",
 * fnc_getLayout) it turns along, a quarter clockwise round the box's middle and fitted into the turned box
 * (fnc_uiPictureTurned); what is on a weapon shows only upright.
 *
 * A shaped item (size=xx/x-, its "holes" as it lies, einv_storage_fnc_getLayout) covers only its own
 * cells: its surface, border and the outline of a hidden one are drawn on those (fnc_uiShape), and the
 * cells under its holes stay as they are - something else may lie there. Its picture, name and count
 * keep to its box, as a rectangle's do.
 *
 * A class that stacks (einv_items_fnc_getInfo "stack" over 1) shows its count of the stack, "3/10", on a
 * small flat box in the bottom right corner in the theme's raised colour (fnc_drawCountBackdrop) - also
 * one alone, so one sees at once that it stacks; one that does not stack shows nothing there.
 * How a magazine's rounds show (theme "tileCount") - in the bottom left corner instead of the right one
 * when the stack's box is there:
 *   "text"  - words in the bottom right corner, on a dark pill of their own so that they read on a white
 *             picture too (tileCountBg, fnc_drawCountBackdrop); plain words where the theme has none
 *   "pill"  - on a box in the bottom right corner, with round ends where the theme has round corners
 *             and square in a square look
 *   "badge" - on a square badge in the bottom left corner, flush with the tile's edges
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Grid, see fnc_createGrid <HASHMAP>
 * 2: Entry, see einv_storage_fnc_getContents - placed by einv_storage_fnc_getLayout <HASHMAP>
 *   "class", "col", "row", "w", "h" - the item, its top left cell and its size in cells
 *   "holes" (optional) - the cells of its box a shaped item does not take, as it lies
 *   "count", "ammo", "capacity" (optional) - how many, a magazine's rounds and how many it holds
 *   "hidden" (optional) - not searched yet <BOOL>
 * 3: Theme <HASHMAP>
 *
 * Return Value:
 * None - the entry gets "controls", "background" and "color", "backgrounds" (every surface: a shaped
 * one has several, "background" is the first) and "rect" (its box) - and "mark", the "?" of a hidden one;
 * a magazine's "bar" (its fill bar's controls) and "barRect", and "amount" (the label of its rounds) with
 * "amountShort" (written without the capacity), which a repack in progress draws over
 * (einv_magazines_fnc_drawJob) - and joins the grid's "tiles"
 *
 * Example:
 * [_display, _grid, _entry, _theme] call einv_gui_fnc_createTile;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_grid", "_entry", "_theme"];

private _parent = _grid get "parent";
private _cellW = _grid get "cellW";
private _cellH = _grid get "cellH";
private _cols = _grid get "cols";
private _rows = _grid get "rows";
private _cells = _grid get "cells";
(_grid get "rel") params ["_gridX", "_gridY"];

private _info = [_entry get "class"] call EFUNC(items,getInfo);
private _hidden = _entry getOrDefault ["hidden", false];
(_info getOrDefault ["size", [1, 1]]) params ["_sizeW", "_sizeH"];

private _col = _entry getOrDefault ["col", 0];
private _row = _entry getOrDefault ["row", 0];

// An entry wider than the grid (its "overflow") is cut at the grid's edge rather than drawn past it.
private _w = ((_entry getOrDefault ["w", _sizeW]) min (_cols - _col)) max 1;
private _h = (_entry getOrDefault ["h", _sizeH]) max 1;

// A shaped item's holes, as it lies. Cut at the grid's edge, its cells would no longer match them: the
// box is drawn then.
private _holes = _entry getOrDefault ["holes", []];

if (_w != (_entry getOrDefault ["w", _sizeW])) then {
    _holes = [];
};

private _shaped = _holes isNotEqualTo [];

// The cells under the tile make way for it - not those under its holes.
for "_r" from _row to (_row + _h - 1) do {
    for "_c" from _col to (_col + _w - 1) do {
        if (_r < _rows && {_c < _cols} && {!(((_r - _row) * _w + _c - _col) in _holes)}) then {
            (_cells select (_r * _cols + _c)) ctrlShow false;
        };
    };
};

// As a cell ends a pixel before the next one, so does the tile - and on a canvas's compartment it is
// drawn in where its cells border another compartment, as they are (fnc_spanRect, fnc_spanInsets).
([_grid, [_gridX, _gridY], _col, _row, _w, _h] call FUNC(spanRect)) params ["_left", "_top", "_width", "_height"];
private _insets = [_grid, _col, _row, _w, _h] call FUNC(spanInsets);
private _padY = _cellH * 0.07;
private _padX = SQUARE(_padY);
private _innerW = _width - _padX * 2;
private _textH = _cellH * 0.28;
private _font = _theme getOrDefault ["font", "PuristaMedium"];
private _fontBold = _theme getOrDefault ["fontBold", "PuristaSemibold"];
private _controls = [];

private _color = if (_hidden) then {
    // Nothing about an unsearched item shows, not even its category: a step above an empty cell.
    private _cell = +(_theme getOrDefault ["cell", [1, 1, 1, 0.045]]);

    if (_cell isEqualTo []) then {[1, 1, 1, 0.06]} else {_cell set [3, (_cell select 3) + 0.03]; _cell}
} else {
    (_theme getOrDefault ["tileBg", []]) param [_info getOrDefault ["category", 0], [1, 1, 1, 0.075]]
};

private _backgrounds = if (_shaped) then {
    [_display, _parent, [_left, _top], _cellW, _cellH, [_w, _h, _holes], _color, "surface", 0, _insets] call FUNC(uiShape)
} else {
    private _ctrl = [_display, "EINV_PanelRect", _parent, [_left, _top, _width, _height]] call FUNC(uiCreate);

    _ctrl ctrlSetBackgroundColor _color;
    [_ctrl]
};
private _background = _backgrounds select 0;

_controls append _backgrounds;

if (_hidden) then {
    if (_theme getOrDefault ["hatch", false]) then {
        // A shaped one hatched run by run - the bridges between its rows are too thin for it.
        private _hatched = if (_shaped) then {
            (_backgrounds apply {ctrlPosition _x}) select {(_x select 3) > pixelH * 2}
        } else {
            [[_left, _top, _width, _height]]
        };

        {
            _controls append ([_display, _parent, _x, _theme getOrDefault ["line", [1, 1, 1, 0.07]]] call FUNC(uiHatch));
        } forEach _hatched;
    };

    // Its outline, a little lighter than the lines between the cells: a step above an empty cell alone,
    // tiles of different sizes side by side read as one field with "?"s strewn over it (Mia, 0.2.3 - a
    // vehicle being searched). A look with tile borders draws its own below.
    if ((_theme getOrDefault ["tileBorder", []]) isEqualTo []) then {
        private _edge = +(_theme getOrDefault ["line", [1, 1, 1, 0.09]]);
        _edge set [3, ((_edge select 3) * 1.8) min 1];

        if (_shaped) then {
            _controls append ([_display, _parent, [_left, _top], _cellW, _cellH, [_w, _h, _holes], _edge, "frame", 0, _insets] call FUNC(uiShape));
        } else {
            _controls pushBack ([_display, _parent, [_left, _top, _width, _height], _edge] call FUNC(uiFrame));
        };
    };

    // The "?" - it gives way to the glass while the item is searched (fnc_showSearch).
    private _mark = [
        _display, _parent, [_left, _top, _width, _height], "?", _cellH * 0.55,
        _theme getOrDefault ["muted", [0.412, 0.443, 0.494, 1]], _fontBold, 2
    ] call FUNC(uiLabel);

    _controls pushBack _mark;
    _entry set ["mark", _mark];
} else {
    private _turned = _entry getOrDefault ["rotated", false];

    if (_turned) then {
        _controls pushBack ([
            _display, _parent, [_left + _padX, _top + _padY, _innerW, _height - _padY * 2], _info getOrDefault ["picture", ""],
            [1, 1, 1, 1], _sizeW / (_sizeH max 1)
        ] call FUNC(uiPictureTurned));
    } else {
        _controls pushBack ([_display, _parent, [_left + _padX, _top + _padY, _innerW, _height - _padY * 2], _info getOrDefault ["picture", ""]] call FUNC(uiPicture));
    };

    // A weapon shows what is on it (fnc_drawAttachments).
    private _attachments = _entry getOrDefault ["attachments", []];

    if (_attachments isNotEqualTo [] && {!_turned}) then {
        _controls append ([_display, _parent, [_left + _padX, _top + _padY, _innerW, _height - _padY * 2], _attachments] call FUNC(drawAttachments));
    };

    if (_theme getOrDefault ["tileName", true]) then {
        // A kit by the name its player gave it (fnc_itemName).
        private _short = [[_entry get "class", true] call FUNC(itemName), _innerW, _font, _textH] call FUNC(fitText);

        _controls pushBack ([
            _display, _parent, [_left + _padX, _top + _padY * 0.4, _innerW, _textH * 1.15], _short, _textH,
            _theme getOrDefault ["text2", [0.639, 0.675, 0.725, 1]], _font, 1
        ] call FUNC(uiLabel));
    };

    // A mark in the top left corner the window that attached asks for ("tileBadge": a texture, "" for none).
    private _badge = ["tileBadge", [_entry get "class"], ""] call FUNC(hook);

    if (_badge isEqualType "" && {_badge isNotEqualTo ""}) then {
        _controls pushBack ([
            _display, _parent, [_left + _padX * 0.5, _top + _padY * 0.5, SQUARE(UNIT * 0.42), UNIT * 0.42], _badge,
            _theme getOrDefault ["text2", [0.639, 0.675, 0.725, 1]]
        ] call FUNC(uiIcon));
    };

    private _count = _entry getOrDefault ["count", 1];
    private _ammo = _entry getOrDefault ["ammo", 0];
    private _capacity = _entry getOrDefault ["capacity", _info getOrDefault ["capacity", 0]];
    private _bottom = _top + _height;

    // A magazine that is not full: how full it is, as a thin bar along the bottom edge - unless the player
    // switched it off (einv_gui_magazineFillBar). A full one needs none: its rounds say it. A setting read
    // from the mission namespace, not GVAR: tiles are drawn in Eden as well, where CBA runs no settings.
    if (
        _capacity > 1 && {_ammo < _capacity}
        && {missionNamespace getVariable [QGVAR(magazineFillBar), true]}
        && {_theme getOrDefault ["tileAmmoBar", true]}
    ) then {
        private _barH = (2 max round (_cellH * 0.06 / pixelH)) * pixelH;
        private _barY = _bottom - _padY - _barH;
        private _barRect = [_left + _padX, _barY, _innerW, _barH];
        private _bar = [
            _display, _parent, _barRect, _ammo / _capacity,
            _theme getOrDefault ["barTrack", [1, 1, 1, 0.06]], _theme getOrDefault ["barFill", [0.84, 0.54, 0.1, 1]], 0
        ] call FUNC(uiBar);

        _controls append _bar;

        // Kept for a repack in progress, which draws its own bar over it (einv_magazines_fnc_drawJob).
        _entry set ["bar", _bar];
        _entry set ["barRect", _barRect];

        _bottom = _barY;
    };

    private _style = _theme getOrDefault ["tileCount", "text"];
    private _amountFont = [_fontBold, _font] select (_style isEqualTo "text");
    private _countBottom = _bottom - _padY * 0.3;

    // What stacks says how many lie here of how many one tile takes, "3/10", on a small flat box in the
    // bottom right corner - Arma's way, as Wardogs and Hotzone show it: one sees at once that it stacks,
    // also with one alone. What does not stack has nothing in that corner. The same box as a hotbar slot's
    // count (fnc_drawSlot, fnc_drawCountBackdrop).
    private _stack = _info getOrDefault ["stack", 1];
    private _stackW = 0;

    if (_stack > 1) then {
        private _stackText = format ["%1/%2", _count, _stack];
        private _stackColor = _theme getOrDefault ["tileCountColor", [0.925, 0.933, 0.949, 1]];

        ([
            _display, _parent, _stackText, _fontBold, _textH, _left + _width - _padX, _countBottom, _innerW, _theme, true
        ] call FUNC(drawCountBackdrop)) params ["_boxControls", "_boxRect"];

        _controls append _boxControls;

        // A theme without the box: the words alone, in the same corner. Asked before _boxRect is reassigned
        // to the full-width rect below - or the label would always be centred over the tile.
        private _noBox = _boxRect isEqualTo [];

        if (_noBox) then {
            _boxRect = [_left + _padX, _countBottom - _textH * 1.15, _innerW, _textH * 1.15];
            _stackW = (_stackText getTextWidth [_fontBold, _textH]) * TEXT_SLACK;
        } else {
            _stackW = _boxRect select 2;
        };

        _controls pushBack ([
            _display, _parent, _boxRect, _stackText, _textH, _stackColor, _fontBold, [2, 1] select _noBox
        ] call FUNC(uiLabel));
    };

    // A magazine's rounds where they always were, in the bottom right corner - unless the stack's box has
    // that corner: then in the bottom left one, in what the box leaves. Not when the player keeps them off
    // the tiles (einv_gui_magazineText): the fill bar alone tells how full it is, and a repack has no
    // label to write into (einv_magazines_fnc_drawJob takes none).
    if (_capacity <= 1 || {!(missionNamespace getVariable [QGVAR(magazineText), true])}) exitWith {};

    private _amount = format ["%1/%2", _ammo, _capacity];
    private _leftSide = _stackW > 0;
    private _room = [_innerW, (_innerW - _stackW - _padX) max (_innerW * 0.25)] select _leftSide;

    // Rounds that do not fit with the capacity show on their own.
    private _shortened = false;

    if ((_amount getTextWidth [_amountFont, _textH]) > ([_innerW * 0.75, _room] select _leftSide)) then {
        _amount = str _ammo;
        _shortened = true;
    };

    private _amountW = (_amount getTextWidth [_amountFont, _textH]) * TEXT_SLACK;
    private _boxH = _textH * 1.3;

    switch (_style) do {
        case "pill": {
            private _pillW = (_amountW + SQUARE(_boxH * 0.5)) max SQUARE(_boxH);
            private _pillX = [_left + _width - _padX - _pillW, _left + _padX] select _leftSide;
            private _pill = [_pillX, _bottom - _padY * 0.5 - _boxH, _pillW, _boxH];

            // A square look keeps its count box square, as it keeps everything else.
            private _pillRadius = [0, _boxH / 2] select ((_theme getOrDefault ["radius", 0]) > 0);

            _controls append ([_display, _parent, _pill, _theme getOrDefault ["tileCountBg", [1, 1, 1, 0.15]], _pillRadius] call FUNC(uiPanel));

            private _label = [
                _display, _parent, _pill, _amount, _textH,
                _theme getOrDefault ["tileCountColor", [0.925, 0.933, 0.949, 1]], _amountFont, 2
            ] call FUNC(uiLabel);

            _controls pushBack _label;
            _entry set ["amount", _label];
        };
        case "badge": {
            // Flush with the tile's corner, or sitting on the ammo bar - the left one already.
            private _badgeW = _amountW + SQUARE(_boxH * 0.4);
            private _badge = [_left, ([_bottom - _boxH, _bottom - _padY * 0.5 - _boxH] select (_bottom < _top + _height)), _badgeW, _boxH];

            _controls append ([_display, _parent, _badge, _theme getOrDefault ["tileCountBg", [0.84, 0.54, 0.1, 1]], 0] call FUNC(uiPanel));

            private _label = [
                _display, _parent, _badge, _amount, _textH,
                _theme getOrDefault ["tileCountColor", [0.086, 0.094, 0.114, 1]], _amountFont, 2
            ] call FUNC(uiLabel);

            _controls pushBack _label;
            _entry set ["amount", _label];
        };
        default {
            // The words stand on a dark pill of their own (fnc_drawCountBackdrop): on a white picture - a vial,
            // a bandage - white text vanishes. It ends where the text did, in its corner, and is sized for the
            // widest the text gets: a repack of magazines writes the rounds live into the same label
            // (einv_magazines_fnc_drawJob), up to the capacity.
            private _widest = [format ["%1/%1", _capacity], str _capacity] select _shortened;

            if ((_widest getTextWidth [_amountFont, _textH]) < (_amount getTextWidth [_amountFont, _textH])) then {
                _widest = _amount;
            };

            private _backdrop = [
                _display, _parent, _widest, _amountFont, _textH, [_left + _width - _padX, _left + _padX] select _leftSide,
                _countBottom, _room, _theme, false, _leftSide
            ] call FUNC(drawCountBackdrop);

            _backdrop params ["_backdropControls", "_backdropRect"];

            _controls append _backdropControls;

            private _label = if (_backdropRect isEqualTo []) then {
                [
                    _display, _parent, [_left + _padX, _countBottom - _textH * 1.15, _innerW, _textH * 1.15], _amount, _textH,
                    _theme getOrDefault ["text", [0.925, 0.933, 0.949, 1]], _amountFont, parseNumber !_leftSide
                ] call FUNC(uiLabel)
            } else {
                [
                    _display, _parent, _backdropRect, _amount, _textH,
                    _theme getOrDefault ["tileCountColor", [0.925, 0.933, 0.949, 1]], _amountFont, 2
                ] call FUNC(uiLabel)
            };

            _controls pushBack _label;
            _entry set ["amount", _label];
        };
    };

    // Whether the rounds show without the capacity, for a repack that counts them live.
    _entry set ["amountShort", _shortened];
};

private _border = _theme getOrDefault ["tileBorder", []];

if (_border isNotEqualTo []) then {
    if (_shaped) then {
        _controls append ([_display, _parent, [_left, _top], _cellW, _cellH, [_w, _h, _holes], _border, "frame", 0, _insets] call FUNC(uiShape));
    } else {
        _controls pushBack ([_display, _parent, [_left, _top, _width, _height], _border] call FUNC(uiFrame));
    };
};

_entry set ["controls", _controls];
_entry set ["background", _background];
_entry set ["backgrounds", _backgrounds];
_entry set ["rect", [_left, _top, _width, _height]];
_entry set ["color", _color];

(_grid get "tiles") pushBack _entry;
