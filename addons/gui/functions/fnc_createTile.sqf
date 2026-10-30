#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Puts an entry on a grid as a tile: a surface in its category's colour over the cells it covers, its
 * picture, and - as the style wants them - its short name in the top right corner (only while the player has
 * einv_gui_tileNames on, off by default; the setup wizard's preview always), what stacks its count
 * of the stack ("3/10") and a magazine its rounds. An entry not searched yet is a plain surface with a "?"
 * and a faint outline, hatched in Tarkov's look.
 *
 * A window that attached (fnc_attach) may mark a tile in its top left corner (the "tileBadge" hook).
 *
 * An item that cannot be used from the container it lies in - the player's own uniform, vest or backpack,
 * which the settings "Use items from ..." close to it, unless it is whitelisted there - wears a small padlock
 * in the top left corner (beside the window's badge, if it has one). Never in the setup wizard's preview.
 *
 * A magazine gets its fill bar only while it is not full and the player has the bar on
 * (einv_gui_magazineFillBar); a full one shows its rounds alone. The rounds as words ("17/30") show
 * while the player has them on (einv_gui_magazineText).
 *
 * The picture is fitted into the tile with its own shape kept. On a tile that lies turned ("rotated",
 * fnc_getLayout) it turns along, a quarter clockwise (issue #24): the upright picture is drawn as the
 * fallback and a turned one is laid over it on the display (fnc_turnPicture, fnc_syncTurned), shown wherever
 * the tile shows whole; what is on a weapon shows only on an upright tile. An item whose rules say so (icon=, the
 * "icon" of einv_items_fnc_getInfo) has it drawn larger, smaller or moved and
 * never out of the tile: a picture that would reach out is cut at the tile's edge by a controls group of
 * the tile's size (fnc_uiItemPicture), the one control the picture is then.
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
 *   "strict" (optional) - kept in the unit's hidden holder (Strict mode): a crossed eye on the tile <BOOL>
 *   "icon" (optional) - [scale, across, down] to draw the picture by instead of the item's own; "picture"
 *   (optional) - the texture to draw instead of the item's own (the wizard's preview of a picture being
 *   picked); "preview" (optional) - drawn outside the inventory window (the setup wizard), so nothing
 *   reports the mouse <BOOL>
 * 3: Theme <HASHMAP>
 *
 * Return Value:
 * None - the entry gets "controls", "background" and "color", "backgrounds" (every surface: a shaped
 * one has several, "background" is the first, and a corner that follows its panel's round corner adds pieces, fnc_uiSurface),
 * "rect" (its box) and "corners" (the corners of its panel it touches, fnc_cornerRadii; [] for none and for a shaped tile);
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

// An entry that still holds the controls of an earlier drawing would lose them here and leave them on the window for
// good, under the new ones: they go first.
{ctrlDelete _x} forEach (_entry getOrDefault ["controls", []]);

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

// The cells under the tile make way for it - not those under its holes; a cell at the corner of its panel has pieces too.
private _cellParts = _grid getOrDefault ["cellParts", createHashMap];

for "_r" from _row to (_row + _h - 1) do {
    for "_c" from _col to (_col + _w - 1) do {
        if (_r < _rows && {_c < _cols} && {!(((_r - _row) * _w + _c - _col) in _holes)}) then {
            private _cellIndex = _r * _cols + _c;

            (_cells select _cellIndex) ctrlShow false;

            if (count _cellParts > 0) then {
                {_x ctrlShow false} forEach (_cellParts getOrDefault [_cellIndex, []]);
            };
        };
    };
};

// As a cell ends a pixel before the next one, so does the tile (fnc_spanRect) - where the grid's columns and
// rows lie, over a seam of a canvas inside its compartment as one piece; a shaped one's surface and border
// follow them too (fnc_uiShape with [grid, column, row]).
([_grid, [_gridX, _gridY], _col, _row, _w, _h] call FUNC(spanRect)) params ["_left", "_top", "_width", "_height"];

// A tile that reaches a corner of its compartment's panel is round at that corner (fnc_cornerRadii): its surface and its outline.
// A shaped one rounds the runs of its surface that touch it (fnc_uiShape).
private _corners = if (_shaped) then {[]} else {[_grid, [_left, _top, _width, _height]] call FUNC(cornerRadii)};
private _padY = _cellH * 0.07;
private _padX = SQUARE(_padY);
private _innerW = _width - _padX * 2;
private _textH = _cellH * 0.28;
private _font = _theme getOrDefault ["font", "PuristaMedium"];
private _fontBold = _theme getOrDefault ["fontBold", "PuristaSemibold"];
private _controls = [];

private _color = if (_hidden) then {
    // Nothing about an unsearched item shows, not even its category: a step above an empty cell - a little more of the cell's film,
    // or, for a solid cell (the palette's, fnc_theme), its colour a little towards white, which is what that film would add.
    private _cell = +(_theme getOrDefault ["cell", [1, 1, 1, 0.045]]);

    switch (true) do {
        case (_cell isEqualTo []): {[1, 1, 1, 0.06]};
        case ((_cell param [3, 1]) >= 1): {((_cell select [0, 3]) apply {_x + (1 - _x) * 0.03}) + [1]};
        default {_cell set [3, (_cell select 3) + 0.03]; _cell};
    }
} else {
    [_theme, _info] call FUNC(tileColour)
};

private _backgrounds = if (_shaped) then {
    [
        _display, _parent, [_left, _top], _cellW, _cellH, [_w, _h, _holes], _color, "surface", 0, [_grid, _col, _row], !_hidden
    ] call FUNC(uiShape)
} else {
    // The corners it touches round (a plain rectangle where it touches none).
    [_display, _parent, [_left, _top, _width, _height], _color, _corners] call FUNC(uiSurface)
};
private _background = _backgrounds select 0;

_controls append _backgrounds;

if (_hidden) then {
    // Diagonal stripes over the whole footprint, a little stronger than the empty slots' (fnc_uiHatch: pieces of about a
    // cell, so a wide tile keeps the angle). A shaped one is hatched run by run - the bridges between its rows are too thin
    // for it. A tile at a round corner of its panel is hatched a little in from that corner (a third of its radius on the
    // two sides that meet there): a square piece of stripes would stick out over the round edge.
    private _stripe = +(_theme getOrDefault ["line", [1, 1, 1, 0.07]]);

    _stripe set [3, ((_stripe select 3) * 1.8) min 0.2];

    private _hatched = if (_shaped) then {
        (_backgrounds apply {ctrlPosition _x}) select {(_x select 3) > pixelH * 2}
    } else {
        private _box = [_left, _top, _width, _height];

        if (_corners isNotEqualTo []) then {
            _corners params ["_radius", "_mask"];
            _mask params ["_topLeft", "_topRight", "_bottomLeft", "_bottomRight"];

            private _inX = ceil (_radius * 0.3) * pixelW;
            private _inY = ceil (_radius * 0.3) * pixelH;
            private _x0 = _left + ([0, _inX] select (_topLeft || {_bottomLeft}));
            private _y0 = _top + ([0, _inY] select (_topLeft || {_topRight}));
            private _x1 = _left + _width - ([0, _inX] select (_topRight || {_bottomRight}));
            private _y1 = _top + _height - ([0, _inY] select (_bottomLeft || {_bottomRight}));

            _box = [_x0, _y0, (_x1 - _x0) max pixelW, (_y1 - _y0) max pixelH];
        };

        [_box]
    };

    {
        _controls append ([_display, _parent, _x, _stripe] call FUNC(uiHatch));
    } forEach _hatched;
} else {
    // The picture as its rules draw it (icon=): larger, smaller or moved, and cut to the tile where it would
    // reach out - one control as long as it does not. An entry may carry an icon of its own (the setup
    // wizard's preview shows the one being edited, "preview": it has no inventory window to report to).
    private _pictureBox = [_left + _padX, _top + _padY, _innerW, _height - _padY * 2];
    private _texture = _entry getOrDefault ["picture", _info getOrDefault ["picture", ""]];
    private _icon = _entry getOrDefault ["icon", _info getOrDefault ["icon", ICON_PLAIN]];
    private _preview = _entry getOrDefault ["preview", false];
    private _picture = [
        _display, _parent, _pictureBox, _texture, _icon, [1, 1, 1, 1], [_left, _top, _width, _height], !_preview
    ] call FUNC(uiItemPicture);

    _controls pushBack _picture;

    // A tile that lies turned turns its picture along (issue #24): a turned one laid over this upright one, which
    // stays as the fallback (fnc_turnPicture, fnc_syncTurned). Not in the wizard's preview.
    if (_entry getOrDefault ["rotated", false] && {!_preview}) then {
        [_display, _grid, _pictureBox, _texture, _icon, [_left, _top, _width, _height], _picture] call FUNC(turnPicture);
    };

    // A weapon shows what is on it (fnc_drawAttachments).
    private _attachments = _entry getOrDefault ["attachments", []];

    if (_attachments isNotEqualTo [] && {!(_entry getOrDefault ["rotated", false])}) then {
        _controls append ([_display, _parent, [_left + _padX, _top + _padY, _innerW, _height - _padY * 2], _attachments] call FUNC(drawAttachments));
    };

    // The name in the top corner: when the look has it and the player wants it (einv_gui_tileNames, off by
    // default; a setting read from the mission namespace, as the magazine ones below) - the preview of the
    // setup wizard always shows it, being a picture of what the rules make of the item.
    if (
        (_theme getOrDefault ["tileName", true])
        && {missionNamespace getVariable [QGVAR(tileNames), false] || {_entry getOrDefault ["preview", false]}}
    ) then {
        // A kit by the name its player gave it (fnc_itemName). A one-cell tile has room for a few letters
        // only: a name that does not fit is set a fifth smaller before it is cut, so more of it shows.
        private _name = [_entry get "class", true] call FUNC(itemName);
        private _nameH = _textH * ([1, 0.8] select (((_name getTextWidth [_font, _textH]) * TEXT_SLACK) > _innerW));
        private _short = [_name, _innerW, _font, _nameH] call FUNC(fitText);

        _controls pushBack ([
            _display, _parent, [_left + _padX, _top + _padY * 0.4, _innerW, _nameH * 1.15], _short, _nameH,
            _theme getOrDefault ["text2", [0.78, 0.78, 0.78, 1]], _font, 1, "name"
        ] call FUNC(uiLabel));
    };

    // A mark in the top left corner the window that attached asks for ("tileBadge": a texture, "" for none).
    private _badge = ["tileBadge", [_entry get "class"], ""] call FUNC(hook);

    if (_badge isEqualType "" && {_badge isNotEqualTo ""}) then {
        _controls pushBack ([
            _display, _parent, [_left + _padX * 0.5, _top + _padY * 0.5, SQUARE(TEXT_UNIT * 0.42), TEXT_UNIT * 0.42], _badge,
            _theme getOrDefault ["text2", [0.78, 0.78, 0.78, 1]]
        ] call FUNC(uiIcon));
    };

    // The marks of the settings "Use items from ...", in a row after the badge: the padlock of an item that
    // cannot be used from here (einv_storage_fnc_useState) - only the player's own gear is ever used from, and
    // only while a setting limits something (one variable read) -, and the crossed eye of one that Strict mode
    // keeps out of the container, in the unit's hidden holder (the entry's "hidden", einv_storage_fnc_opStrict).
    private _markSize = TEXT_UNIT * 0.4;
    private _markX = _left + _padX * 0.5 + ([0, SQUARE(TEXT_UNIT * 0.42) + _padX * 0.5] select (_badge isEqualType "" && {_badge isNotEqualTo ""}));
    private _markColor = _theme getOrDefault ["text2", [0.78, 0.78, 0.78, 1]];

    if (
        missionNamespace getVariable [QEGVAR(storage,useActive), false]
        && {!(_entry getOrDefault ["preview", false])} && {!(_grid getOrDefault ["virtual", true])}
    ) then {
        private _useKind = [_grid getOrDefault ["container", objNull]] call EFUNC(storage,useKind);

        if (([_entry get "class", _useKind] call EFUNC(storage,useState)) isEqualTo "blocked") then {
            _controls pushBack ([
                _display, _parent, [_markX, _top + _padY * 0.5, SQUARE(_markSize), _markSize], UI_TEX(icon_lock_ca), _markColor
            ] call FUNC(uiIcon));

            _markX = _markX + SQUARE(_markSize) + _padX * 0.5;
        };
    };

    // Kept in the unit's hidden holder (Strict mode, "strict"), which is not the same as not searched yet
    // ("hidden", the "?" tile): the eye is for the first, and a tile of the second never gets here.
    if (_entry getOrDefault ["strict", false] && {!(_entry getOrDefault ["preview", false])}) then {
        _controls pushBack ([
            _display, _parent, [_markX, _top + _padY * 0.5, SQUARE(_markSize), _markSize], UI_TEX(icon_eye_off_ca), _markColor
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
            _theme getOrDefault ["barTrack", [1, 1, 1, 0.06]], _theme getOrDefault ["barFill", [0.84, 0.54, 0.1, 1]], 0, GRADIENT_BARS
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

    // A tile at a round corner of its panel (fnc_cornerRadii) keeps what lies in its bottom corners in from that corner:
    // a box's square corner would stick out over the arc. A corner point inside the arc is at least 0.3 of the radius in
    // from both edges, so the box ends there, less what its own padding gives already. Only with nothing under the box
    // (the ammo bar lifts it).
    private _roundBL = false;
    private _roundBR = false;
    private _cornerX = 0;
    private _cornerY = 0;

    if (_corners isNotEqualTo [] && {_bottom == _top + _height}) then {
        _corners params ["_cornerRadius", "_cornerMask"];

        _roundBL = _cornerMask select 2;
        _roundBR = _cornerMask select 3;
        _cornerX = ((ceil (_cornerRadius * 0.3)) * pixelW - _padX) max 0;
        _cornerY = ((ceil (_cornerRadius * 0.3)) * pixelH - _padY * 0.3) max 0;
    };

    private _stackX = [0, _cornerX] select _roundBR;
    private _stackY = [0, _cornerY] select _roundBR;

    // What stacks says how many lie here of how many one tile takes, "3/10", on a small flat box in the
    // bottom right corner - Arma's way, as Wardogs and Hotzone show it: one sees at once that it stacks,
    // also with one alone. What does not stack has nothing in that corner. The same box as a hotbar slot's
    // count (fnc_drawSlot, fnc_drawCountBackdrop).
    private _stack = [_grid getOrDefault ["container", objNull], _entry get "class", _info getOrDefault ["stack", 1]] call EFUNC(storage,stackFor);
    private _stackW = 0;

    if (_stack > 1) then {
        private _stackText = format ["%1/%2", _count, _stack];
        private _stackColor = _theme getOrDefault ["tileCountColor", [1, 1, 1, 1]];

        // Only measured: the label lies on exactly the box and draws it as its own background - one control
        // for the box and its words instead of two, on every stack of the window.
        ([
            _display, _parent, _stackText, _fontBold, _textH, _left + _width - _padX - _stackX, _countBottom - _stackY, _innerW, _theme, true, false, true
        ] call FUNC(drawCountBackdrop)) params ["_boxControls", "_boxRect", ["_boxColor", []]];

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

        private _stackLabel = [
            _display, _parent, _boxRect, _stackText, _textH, _stackColor, _fontBold, [2, 1] select _noBox, "stack"
        ] call FUNC(uiLabel);

        if (_boxControls isEqualTo [] && {_boxColor isNotEqualTo []}) then {
            _stackLabel ctrlSetBackgroundColor _boxColor;
        };

        _controls pushBack _stackLabel;
    };

    // A magazine's rounds where they always were, in the bottom right corner - unless the stack's box has
    // that corner: then in the bottom left one, in what the box leaves. Not when the player keeps them off
    // the tiles (einv_gui_magazineText): the fill bar alone tells how full it is, and a repack has no
    // label to write into (einv_magazines_fnc_drawJob takes none).
    if (_capacity <= 1 || {!(missionNamespace getVariable [QGVAR(magazineText), true])}) exitWith {};

    private _amount = format ["%1/%2", _ammo, _capacity];
    private _leftSide = _stackW > 0;

    // The same for the rounds' box, in the corner it stands in.
    private _roundX = [[0, _cornerX] select _roundBR, [0, _cornerX] select _roundBL] select _leftSide;
    private _roundY = [[0, _cornerY] select _roundBR, [0, _cornerY] select _roundBL] select _leftSide;
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
            private _pillX = [_left + _width - _padX - _pillW - _roundX, _left + _padX + _roundX] select _leftSide;
            private _pill = [_pillX, _bottom - _padY * 0.5 - _boxH - _roundY, _pillW, _boxH];

            // A square look keeps its count box square, as it keeps everything else.
            private _pillRadius = [0, _boxH / 2] select ((_theme getOrDefault ["radius", 0]) > 0);

            _controls append ([_display, _parent, _pill, _theme getOrDefault ["tileCountBg", [1, 1, 1, 0.15]], _pillRadius] call FUNC(uiPanel));

            private _label = [
                _display, _parent, _pill, _amount, _textH,
                _theme getOrDefault ["tileCountColor", [1, 1, 1, 1]], _amountFont, 2, "ammo"
            ] call FUNC(uiLabel);

            _controls pushBack _label;
            _entry set ["amount", _label];
        };
        case "badge": {
            // Flush with the tile's corner, or sitting on the ammo bar - the left one already.
            private _badgeW = _amountW + SQUARE(_boxH * 0.4);
            private _badge = [_left + _roundX, ([_bottom - _boxH, _bottom - _padY * 0.5 - _boxH] select (_bottom < _top + _height)) - _roundY, _badgeW, _boxH];

            _controls append ([_display, _parent, _badge, _theme getOrDefault ["tileCountBg", [0.84, 0.54, 0.1, 1]], 0] call FUNC(uiPanel));

            private _label = [
                _display, _parent, _badge, _amount, _textH,
                _theme getOrDefault ["tileCountColor", [0.05, 0.05, 0.05, 1]], _amountFont, 2, "ammo"
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
                _display, _parent, _widest, _amountFont, _textH, [_left + _width - _padX - _roundX, _left + _padX + _roundX] select _leftSide,
                _countBottom - _roundY, _room, _theme, false, _leftSide
            ] call FUNC(drawCountBackdrop);

            _backdrop params ["_backdropControls", "_backdropRect"];

            _controls append _backdropControls;

            private _label = if (_backdropRect isEqualTo []) then {
                [
                    _display, _parent, [_left + _padX, _countBottom - _textH * 1.15, _innerW, _textH * 1.15], _amount, _textH,
                    _theme getOrDefault ["text", [1, 1, 1, 1]], _amountFont, parseNumber !_leftSide, "ammo"
                ] call FUNC(uiLabel)
            } else {
                [
                    _display, _parent, _backdropRect, _amount, _textH,
                    _theme getOrDefault ["tileCountColor", [1, 1, 1, 1]], _amountFont, 2, "ammo"
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
        _controls append ([_display, _parent, [_left, _top], _cellW, _cellH, [_w, _h, _holes], _border, "frame", 0, [_grid, _col, _row]] call FUNC(uiShape));
    } else {
        _controls append ([_display, _parent, [_left, _top, _width, _height], _border, _corners, 1] call FUNC(uiOutline));
    };
};

_entry set ["controls", _controls];

// A paged compartment keeps a list of every control its tiles made (fnc_showPage clears the window with it, whatever
// the tiles say they hold).
if ((_grid getOrDefault ["pageRanges", []]) isNotEqualTo []) then {
    private _made = _grid getOrDefault ["tileControls", []];

    _grid set ["tileControls", _made];
    _made append _controls;
};

_entry set ["background", _background];
_entry set ["backgrounds", _backgrounds];
_entry set ["corners", _corners];
_entry set ["rect", [_left, _top, _width, _height]];
_entry set ["color", _color];

(_grid get "tiles") pushBack _entry;
