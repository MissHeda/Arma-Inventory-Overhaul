#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Draws the pool of cards: a scrolling group with just enough cards to fill it and two rows more, each of
 * eight controls (surface, picture, name, size, count pill with its text, star, and the logo of the mod the
 * item comes from, which ACE's setting for mod icons turns on), made once and rebound as the list scrolls
 * (fnc_bindCatalog). Also makes the source grid the mouse finds the cards through, the
 * speck at the foot of the pool that gives it its height, and the line for an empty or still unread list.
 *
 * The cards are as wide as CARD_W_CELLS and CARD_H_CELLS cells say, stretched so that the columns fill the
 * pool exactly. What is kept about them is in the column (uiNamespace GVAR(column)): "pool", "cards" (for
 * each card its eight controls with their place within the card), "cardIdx" (the list place each shows),
 * "grid", "cols", "poolRows", "pitch", "cardSize", "contentH", "poolH".
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call einv_arsenal_fnc_drawCatalog;
 *
 * Public: No
 */

disableSerialization;

private _column = uiNamespace getVariable [QGVAR(column), createHashMap];
private _items = _column getOrDefault ["itemsGroup", controlNull];
private _display = uiNamespace getVariable [QEGVAR(gui,display), displayNull];

if (isNull _items || {isNull _display}) exitWith {};

{
    ctrlDelete (_column getOrDefault [_x, controlNull]);
} forEach ["pool", "emptyCtrl", "loadTrack", "loadFill"];

private _theme = EGVAR(gui,theme);
private _poolRect = _column get "poolRect";
_poolRect params ["_poolLeft", "_poolTop", "_poolWidth", "_poolHeight"];

(call EFUNC(gui,getCell)) params ["_cellW", "_cellH"];

// ----- The pool -----
private _poolX = round (_poolLeft / pixelW) * pixelW;
private _poolY = round (_poolTop / pixelH) * pixelH;
private _poolW = floor (_poolWidth / pixelW) * pixelW;
private _poolH = floor (_poolHeight / pixelH) * pixelH;

private _pool = _display ctrlCreate ["EINV_ScrollGroup", -1, _items];

_pool ctrlSetPosition [_poolX, _poolY, _poolW, _poolH];
_pool ctrlCommit 0;

if !(_pool getVariable [QEGVAR(gui,hooked), false]) then {
    _pool setVariable [QEGVAR(gui,hooked), true];
    _pool ctrlAddEventHandler ["MouseButtonDown", {[true, _this] call EFUNC(gui,onMouseButton)}];
    _pool ctrlAddEventHandler ["MouseButtonUp", {[false, _this] call EFUNC(gui,onMouseButton)}];
    _pool ctrlAddEventHandler ["MouseZChanged", {[_this] call EFUNC(gui,onMouseZ)}];
};

// ----- The cards: as many in a row as fit, stretched to fill the row -----
private _innerW = floor ((_poolW - SCROLL_W - pixelW * 2) / pixelW) * pixelW;
private _gapX = (round (CARD_GAP_CELLS * _cellW / pixelW) max 1) * pixelW;
private _gapY = (round (CARD_GAP_CELLS * _cellH / pixelH) max 1) * pixelH;
private _cols = (floor ((_innerW + _gapX) / (CARD_W_CELLS * _cellW + _gapX))) max 1;
private _cardW = floor (((_innerW - (_cols - 1) * _gapX) / _cols) / pixelW) * pixelW;
private _cardH = round (CARD_H_CELLS * _cellH / pixelH) * pixelH;
private _pitchX = _cardW + _gapX;
private _pitchY = _cardH + _gapY;
private _visibleRows = (floor (_poolH / _pitchY)) max 1;
private _poolRows = _visibleRows + 2;

private _padY = round (_cardH * 0.07 / pixelH) * pixelH;
private _padX = round (SQUARE(_padY) / pixelW) * pixelW;
private _lineH = UNIT * 0.55;
private _nameSize = UNIT * 0.44;
private _pillH = UNIT * 0.6;
private _pillW = SQUARE(_pillH) * 1.6;
private _starH = UNIT * 0.5;
private _logoH = UNIT * 0.55;
private _nameW = _cardW * 0.62 - _padX;
private _lineY = _cardH - _lineH - _padY * 0.5;

private _font = _theme getOrDefault ["font", "RobotoCondensed"];
private _fontBold = _theme getOrDefault ["fontBold", "RobotoCondensedBold"];
private _text2 = _theme getOrDefault ["text2", [0.639, 0.675, 0.725, 1]];
private _muted = _theme getOrDefault ["muted", [0.412, 0.443, 0.494, 1]];
private _accent = _theme getOrDefault ["accent", [0.961, 0.647, 0.141, 1]];
private _star = ICON(icon_star_ca,icon_check_ca);
private _favorite = (missionNamespace getVariable [QACEGVAR(arsenal,favoritesColor), [1, 0.8, 0]]) + [1];

private _cards = [];

for "_i" from 0 to (_cols * _poolRows - 1) do {
    private _originX = (_i mod _cols) * _pitchX;
    private _originY = floor (_i / _cols) * _pitchY;

    private _surface = [_display, "EINV_PanelRect", _pool, [_originX, _originY, _cardW, _cardH]] call EFUNC(gui,uiCreate);

    private _picture = [
        _display, _pool, [_originX + _padX, _originY + _padY, _cardW - _padX * 2, _cardH - _lineH - _padY * 2.2], ""
    ] call EFUNC(gui,uiPicture);

    private _name = [
        _display, _pool, [_originX + _padX, _originY + _lineY, _nameW, _lineH], "", _nameSize, _text2, _font, 0
    ] call EFUNC(gui,uiLabel);

    private _size = [
        _display, _pool, [_originX + _cardW * 0.62, _originY + _lineY, _cardW * 0.38 - _padX, _lineH], "", _nameSize, _muted, _font, 1
    ] call EFUNC(gui,uiLabel);

    private _pillBg = [
        _display, "EINV_PanelRect", _pool, [_originX + _cardW - _padX - _pillW, _originY + _padY * 0.6, _pillW, _pillH]
    ] call EFUNC(gui,uiCreate);

    _pillBg ctrlSetBackgroundColor _accent;

    private _pillText = [
        _display, _pool, [_originX + _cardW - _padX - _pillW, _originY + _padY * 0.6, _pillW, _pillH], "", UNIT * 0.42,
        _theme getOrDefault ["onAccent", [0.086, 0.094, 0.114, 1]], _fontBold, 2
    ] call EFUNC(gui,uiLabel);

    private _starCtrl = [
        _display, _pool, [_originX + _padX * 0.7, _originY + _padY * 0.6, SQUARE(_starH), _starH], _star, _favorite
    ] call EFUNC(gui,uiIcon);

    // The mod's logo sits at the foot of the picture, left, above the name.
    private _logoCtrl = [
        _display, _pool, [_originX + _padX * 0.7, _originY + _lineY - _logoH - _padY * 0.4, SQUARE(_logoH), _logoH], ""
    ] call EFUNC(gui,uiPicture);

    // Each with its place within the card, so the card can be moved by its corner.
    private _parts = [_surface, _picture, _name, _size, _pillBg, _pillText, _starCtrl, _logoCtrl] apply {
        (ctrlPosition _x) params ["_partX", "_partY", "_partW", "_partH"];

        _x ctrlShow false;

        [_x, _partX - _originX, _partY - _originY, _partW, _partH]
    };

    _cards pushBack _parts;
};

// The pool is as high as its rows; a speck at the very foot makes the engine scroll exactly that far.
private _speck = [_display, "EINV_PanelRect", _pool, [0, _poolH - pixelH, pixelW, pixelH]] call EFUNC(gui,uiCreate);

_speck ctrlSetBackgroundColor [0, 0, 0, 0];
_pool setVariable [QEGVAR(gui,contentH), _poolH];

// ----- What the mouse finds the cards through: a grid that things come from -----
private _grid = createHashMapFromArray [
    ["parent", _pool], ["rel", [0, 0]], ["cols", _cols], ["rows", _poolRows], ["cellW", _pitchX], ["cellH", _pitchY],
    ["cells", []], ["tiles", []], ["section", "catalog"], ["source", "catalog"], ["virtual", true], ["container", objNull]
];

// ----- A line for a list with nothing in it or not read yet, with a thin bar under it -----
private _emptyY = _poolY + _poolH * 0.3;
private _emptyCtrl = [_display, _items, [_poolX, _emptyY, _poolW, UNIT * 1.2], "", UNIT * 0.6, _muted, _font, 2] call EFUNC(gui,uiLabel);
private _barW = _poolW * 0.5;
private _loadRect = [_poolX + (_poolW - _barW) / 2, _emptyY + UNIT * 1.5, _barW, pixelH * 3];

private _loadTrack = [_display, "EINV_PanelRect", _items, _loadRect] call EFUNC(gui,uiCreate);
private _loadFill = [_display, "EINV_PanelRect", _items, _loadRect] call EFUNC(gui,uiCreate);

_loadTrack ctrlSetBackgroundColor (_theme getOrDefault ["barTrack", [1, 1, 1, 0.08]]);
_loadFill ctrlSetBackgroundColor _accent;

{
    _x ctrlShow false;
} forEach [_emptyCtrl, _loadTrack, _loadFill];

_column set ["pool", _pool];
_column set ["speck", _speck];
_column set ["cards", _cards];
_column set ["cardIdx", _cards apply {-1}];
_column set ["grid", _grid];
_column set ["cols", _cols];
_column set ["poolRows", _poolRows];
_column set ["visibleRows", _visibleRows];
_column set ["pitch", [_pitchX, _pitchY]];
_column set ["cardSize", [_cardW, _cardH]];
_column set ["pillW", _pillW];
_column set ["poolH", _poolH];
_column set ["contentH", _poolH];
_column set ["firstRow", 0];
_column set ["scrollPx", 0];
_column set ["wheel", 0];
_column set ["snapUntil", -1];
_column set ["emptyCtrl", _emptyCtrl];
_column set ["emptyState", ""];
_column set ["loadTrack", _loadTrack];
_column set ["loadFill", _loadFill];
_column set ["loadRect", _loadRect];
_column set ["names", createHashMap];
_column set ["stamp", GVAR(availableStamp)];
_column set ["dirty", true];
_column set ["restoreRow", GVAR(scrollRows) getOrDefault [GVAR(category), 0]];
_column set ["restoreFrame", -1];

[false] call FUNC(bindCatalog);
