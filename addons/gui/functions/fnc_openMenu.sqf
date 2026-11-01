#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Opens a context menu at the mouse: a card with a row per choice. A click on a row closes the menu and
 * runs its code; a left click anywhere else only closes it (a hit area over the whole screen, under the
 * menu). A right click beside the menu closes it as well, but is then worked out as a right click of its
 * own (fnc_onMouseButton), so that the next tile's menu opens in the same go. Kept on the screen whatever
 * corner the mouse is in.
 *
 * The menu is a layer of its own: one controls group over the screen, made last, with the focus taken into
 * it (a button of a pixel on its card, as the setup wizard's popovers do). The engine draws the focused
 * control over every other, and a column whose button kept the focus after its click (Sort) drew
 * its tiles over the menu - "the menu hides behind items, sometimes". The layer is the display's last
 * control as well: should anything be made on the display while it is open (fnc_redrawTiles, a slot's
 * hover ring), fnc_raiseMenu makes it again on top - the same choices at the same place, the row under the
 * mouse lit. Closed (fnc_closeMenu), the focus goes back to a field that had it, else to the search
 * field's sink.
 *
 * A choice may bring options as a fourth element, a HashMap - the options of other mods' context menus
 * (fnc_cbaOptions) use them:
 *   "icon"      - a picture before the text; every row's text moves over for it when any row has one
 *   "color"     - the text's colour, [] for the usual
 *   "tooltip"   - shown while the mouse rests on the row
 *   "enabled"   - false: greyed out, and a click on it does nothing - the menu stays open
 *   "separator" - true: a line above the row, setting it apart from the rows before
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Choices [[text, arguments, code, options (optional)], ...] <ARRAY>
 * 2: Where to open it [x, y], [] for the mouse <ARRAY> (default: [])
 * 3: Tiles across instead of rows, 0 for rows - the modding view's parts (fnc_partChoices), as Tarkov's weapon builds list them:
 *    a square tile per choice, its picture (the "icon" option) and its short text in the top left corner, the whole text as its
 *    tip <NUMBER> (default: 0)
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, [["Drop", [0, 3], {_this call aio_gui_fnc_dropToGround}]]] call aio_gui_fnc_openMenu;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_choices", ["_at", [], [[]]], ["_across", 0, [0]]];

// A field that had the cursor before the menu took the focus, to have it back when the menu goes - the
// first menu's, when this one replaces another or is the same made again on top (fnc_raiseMenu). Nothing
// else is given the focus back: a button in a column that kept it is what drew the column over the menu.
private _back = if ((uiNamespace getVariable [QGVAR(menu), []]) isEqualTo []) then {
    private _focused = focusedCtrl _display;

    [controlNull, _focused] select (!isNull _focused && {ctrlType _focused == 2})
} else {
    uiNamespace getVariable [QGVAR(menuFocusBack), controlNull]
};

call FUNC(closeMenu);

// The name at the mouse would sit under it - and so would the comparison card (fnc_drawCompare).
(uiNamespace getVariable [QGVAR(tooltip), controlNull]) ctrlShow false;
ctrlDelete (uiNamespace getVariable [QGVAR(compare), controlNull]);
uiNamespace setVariable [QGVAR(compare), controlNull];
uiNamespace setVariable [QGVAR(tipShown), controlNull];

if (_choices isEqualTo []) exitWith {};

private _theme = GVAR(theme);
private _font = _theme getOrDefault ["font", "PuristaMedium"];
// Its rows and words grow with the tiles (TEXT_UNIT, fnc_textScale).
private _textUnit = TEXT_UNIT;
private _size = _textUnit * 0.66;
private _rowH = _textUnit * 1.15;
private _padY = _textUnit * 0.2;
private _padX = SQUARE(_textUnit * 0.45);
private _width = SQUARE(_textUnit * 6);
private _iconH = _rowH * 0.6;

private _fnc_options = {
    private _options = _this param [3, createHashMap];

    [createHashMap, _options] select (_options isEqualType createHashMap)
};

// Room for a picture before every row's text once one row has one, so the texts stay in line.
private _hasIcons = _choices findIf {((_x call _fnc_options) getOrDefault ["icon", ""]) isNotEqualTo ""} >= 0;
private _textX = [0, SQUARE(_iconH) + SQUARE(_textUnit * 0.3)] select _hasIcons;

{
    _width = _width max (((_x select 0) getTextWidth [_font, _size]) * TEXT_SLACK + _padX * 2 + _textX);
} forEach _choices;

private _height = count _choices * _rowH + _padY * 2;

// Tiles: as many across as asked, square, the card as large as they make it.
private _tileH = _textUnit * 2.3;
private _tileW = SQUARE(_tileH);
private _tileGap = _textUnit * 0.15;
private _columns = (count _choices) min _across;

if (_across > 0) then {
    _width = _columns * _tileW + (_columns - 1) * SQUARE(_tileGap) + _padX * 0.6;
    _height = (ceil (count _choices / _columns)) * (_tileH + _tileGap) - _tileGap + _padY * 2;
};

([_at, getMousePosition] select (_at isEqualTo [])) params ["_mouseX", "_mouseY"];

private _left = _mouseX min (safezoneX + safezoneW - _width);
private _top = _mouseY min (safezoneY + safezoneH - _height);
private _mouse = getMousePosition;

// The layer over the screen; everything of the menu in it, at its place relative to the screen's corner.
private _layer = [_display, "AIO_Group", controlNull, [safezoneX, safezoneY, safezoneW, safezoneH]] call FUNC(uiCreate);
private _cardX = _left - safezoneX;
private _cardY = _top - safezoneY;

// A group keeps the mouse's buttons from the display's own handlers: it reports them as the columns do
// (fnc_build), and so does the hit area over the screen in it, so a right press beside the card still
// closes the menu and opens the next one in the same go (fnc_onMouseButton takes each press once). They
// never answer "taken": the hit area's own click closes the menu.
_layer setVariable [QGVAR(hooked), true];
_layer ctrlAddEventHandler ["MouseButtonDown", {[true, _this] call FUNC(onMouseButton); false}];
_layer ctrlAddEventHandler ["MouseButtonUp", {[false, _this] call FUNC(onMouseButton); false}];

// Under the card, over everything else: a click beside the menu closes it.
private _catcher = [_display, "AIO_Hitbox", _layer, [0, 0, safezoneW, safezoneH]] call FUNC(uiCreate);
_catcher ctrlAddEventHandler ["MouseButtonDown", {[true, _this] call FUNC(onMouseButton); false}];
_catcher ctrlAddEventHandler ["MouseButtonUp", {[false, _this] call FUNC(onMouseButton); false}];
_catcher ctrlAddEventHandler ["ButtonClick", {[{call FUNC(closeMenu)}] call FUNC(later)}];

// Round as the window's panels are: the border is the card's size in the border's colour, the card one pixel in from it (a panel's
// own border is square only).
private _radius = (_theme getOrDefault ["radius", 0]) * 0.7;

[_display, _layer, [_cardX, _cardY, _width, _height], [1, 1, 1, 0.14], _radius] call FUNC(uiPanel);
[
    _display, _layer, [_cardX + pixelW, _cardY + pixelH, _width - pixelW * 2, _height - pixelH * 2],
    _theme getOrDefault ["inspectBg", [0.06, 0.06, 0.06, 0.98]], (_radius - pixelH) max 0
] call FUNC(uiPanel);

// The row under the mouse lights in the secondary colour's film, round and in from the card's edge as the slots' are.
private _hover = _theme getOrDefault ["buttonHover", [1, 1, 1, 0.16]];
private _rowInset = _padX * 0.3;
private _rowRadius = (_radius * 0.6) min (_rowH / 2);

{
    _x params ["_text", "_arguments", "_code"];

    private _options = _x call _fnc_options;
    private _enabled = _options getOrDefault ["enabled", true];
    private _rowTop = _cardY + _padY + _forEachIndex * _rowH;

    // A tile: its glass, its picture, its short text, and over it the hit area that lights it and runs it.
    if (_across > 0) then {
        private _tileX = _cardX + _padX * 0.3 + (_forEachIndex mod _columns) * (_tileW + SQUARE(_tileGap));
        private _tileY = _cardY + _padY + (floor (_forEachIndex / _columns)) * (_tileH + _tileGap);
        private _tileRadius = _rowRadius min (_tileH / 5);

        [_display, _layer, [_tileX, _tileY, _tileW, _tileH], _theme getOrDefault ["slot", [1, 1, 1, 0.05]], _tileRadius] call FUNC(uiPanel);

        _rowTop = _tileY;

        private _surfaceTile = [_display, _layer, [_tileX, _tileY, _tileW, _tileH], [0, 0, 0, 0], _tileRadius] call FUNC(uiPanel);
        private _icon = _options getOrDefault ["icon", ""];
        private _faceH = _tileH * 0.6;

        if (_icon isNotEqualTo "") then {
            [
                _display, _layer, [_tileX + (_tileW - SQUARE(_faceH)) / 2, _tileY + _tileH - _faceH - _tileH * 0.06, SQUARE(_faceH), _faceH],
                _icon, [[1, 1, 1, 0.4], [1, 1, 1, 1]] select _enabled
            ] call FUNC(uiPicture);
        };

        private _nameSize = _textUnit * 0.42;
        private _nameW = _tileW - SQUARE(_tileH * 0.08) * 2;

        [
            _display, _layer, [_tileX + SQUARE(_tileH * 0.08), _tileY + _tileH * 0.04, _nameW, _nameSize * 1.3],
            [_text, _nameW, _font, _nameSize] call FUNC(fitText), _nameSize,
            [_theme getOrDefault ["muted", [0.56, 0.56, 0.56, 1]], _theme getOrDefault ["text", [1, 1, 1, 1]]] select _enabled, _font, 0, "menu"
        ] call FUNC(uiLabel);

        private _hit = [_display, "AIO_Hitbox", _layer, [_tileX, _tileY, _tileW, _tileH]] call FUNC(uiCreate);
        private _tip = _options getOrDefault ["tooltip", _text];

        [_hit, _tip] call FUNC(setTooltip);

        if (_enabled) then {
            _hit setVariable [QGVAR(surface), [_surfaceTile, _hover]];
            _hit setVariable [QGVAR(choice), [_arguments, _code]];
            _hit ctrlAddEventHandler ["MouseEnter", {((_this select 0) getVariable [QGVAR(surface), [[], []]]) call FUNC(paintSurface)}];
            _hit ctrlAddEventHandler ["MouseExit", {[((_this select 0) getVariable [QGVAR(surface), [[]]]) select 0, [0, 0, 0, 0]] call FUNC(paintSurface)}];
            _hit ctrlAddEventHandler ["ButtonClick", {
                [{
                    call FUNC(closeMenu);
                    (_this select 0) call (_this select 1);
                }, (_this select 0) getVariable [QGVAR(choice), [[], {}]]] call FUNC(later);
            }];
        };

        continue;
    };

    if (_options getOrDefault ["separator", false]) then {
        [
            _display, _layer, [_cardX + _padX * 0.3, _rowTop, _width - _padX * 0.6, pixelH],
            _theme getOrDefault ["line", [1, 1, 1, 0.07]]
        ] call FUNC(uiPanel);
    };

    private _surface = [_display, _layer, [_cardX + _rowInset, _rowTop, _width - _rowInset * 2, _rowH], [0, 0, 0, 0], _rowRadius] call FUNC(uiPanel);

    // The row under the mouse is lit from the start: a menu made again on top (fnc_raiseMenu) hears of no
    // mouse entering until it moves.
    private _lit = _enabled && {(_mouse select 0) >= _left} && {(_mouse select 0) < _left + _width}
        && {(_mouse select 1) >= _rowTop + safezoneY} && {(_mouse select 1) < _rowTop + safezoneY + _rowH};

    [_surface, [[0, 0, 0, 0], _hover] select _lit] call FUNC(paintSurface);

    private _icon = _options getOrDefault ["icon", ""];

    if (_icon isNotEqualTo "") then {
        [
            _display, _layer, [_cardX + _padX, _rowTop + (_rowH - _iconH) / 2, SQUARE(_iconH), _iconH], _icon,
            [[1, 1, 1, 0.4], [1, 1, 1, 1]] select _enabled
        ] call FUNC(uiPicture);
    };

    private _color = _options getOrDefault ["color", []];

    if !(_color isEqualType [] && {count _color >= 3}) then {
        _color = _theme getOrDefault ["text", [1, 1, 1, 1]];
    };

    if (!_enabled) then {
        _color = _theme getOrDefault ["muted", [0.56, 0.56, 0.56, 1]];
    };

    [_display, _layer, [_cardX + _padX + _textX, _rowTop, _width - _padX * 2 - _textX, _rowH], _text, _size, _color, _font, 0, "menu"] call FUNC(uiLabel);

    // A greyed-out row takes the click, so it closes nothing and runs nothing.
    private _hit = [_display, "AIO_Hitbox", _layer, [_cardX, _rowTop, _width, _rowH]] call FUNC(uiCreate);
    private _tooltip = _options getOrDefault ["tooltip", ""];

    if (_tooltip isEqualType "" && {_tooltip isNotEqualTo ""}) then {
        [_hit, _tooltip] call FUNC(setTooltip);
    };

    if (_enabled) then {
        _hit setVariable [QGVAR(surface), [_surface, _hover]];
        _hit setVariable [QGVAR(choice), [_arguments, _code]];
        _hit ctrlAddEventHandler ["MouseEnter", {((_this select 0) getVariable [QGVAR(surface), [[], []]]) call FUNC(paintSurface)}];
        _hit ctrlAddEventHandler ["MouseExit", {[((_this select 0) getVariable [QGVAR(surface), [[]]]) select 0, [0, 0, 0, 0]] call FUNC(paintSurface)}];
        _hit ctrlAddEventHandler ["ButtonClick", {
            private _choice = (_this select 0) getVariable [QGVAR(choice), [[], {}]];

            // A frame later: the menu goes first, and a control must not be deleted inside its own event.
            // Through fnc_later, which also runs in the Eden editor.
            [{
                call FUNC(closeMenu);
                (_this select 0) call (_this select 1);
            }, _choice] call FUNC(later);
        }];
    };
} forEach _choices;

// The focus into the layer, so it is drawn over everything: a button no one sees, one pixel in the card's
// padding - the engine may refuse the focus to a control of no size. Return and Space press nothing on it.
private _focus = [_display, "AIO_Hitbox", _layer, [_cardX + _padX / 2, _cardY + _padY / 2, pixelW, pixelH]] call FUNC(uiCreate);
ctrlSetFocus _focus;

uiNamespace setVariable [QGVAR(menu), [_layer]];
uiNamespace setVariable [QGVAR(menuFocusBack), _back];

// Where it lies, so that a right click on it is told from one beside it (fnc_onMouseButton).
uiNamespace setVariable [QGVAR(menuRect), [_left, _top, _width, _height]];

// What it shows, to make it again on top (fnc_raiseMenu).
GVAR(menuState) = [_choices, [_left, _top], _across];
