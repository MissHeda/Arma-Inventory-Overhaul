#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Opens a popover over the wizard - a card in the style of Enhanced First Aid Kits' menus, below what
 * opened it (above when there is no room below), or in the middle of the screen over a dimmed wizard for
 * a question that has to be answered. A click anywhere beside it closes it (a hit area over the whole
 * screen, under the card), as does Escape. Only one at a time: opening one closes the last.
 *
 * Everything of it is made in the wizard's top layer (fnc_topLayer), made after the pane, and the focus
 * goes into it: the engine draws the control that holds the focus over all others, and a pane that kept
 * it - a click on a dropdown in it gives it the focus - lay over a popover made on the display (Mia,
 * 0.4.0: the list and the closing question behind the wizard, not to be clicked). Its content is drawn by
 * the caller, into the group this returns.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Screen rectangle [x, y, w, h] of what opened it, [] for the middle of the screen <ARRAY>
 * 2: Size of the content, [w, h] <ARRAY>
 * 3: Title, "" for none <STRING>
 * 4: Code drawing the content, called with [display, content group, theme, arguments] <CODE>
 * 5: Arguments <ANY> (default: [])
 * 6: For the middle of the screen: the point to centre the card on, [x, y] - the wizard's middle, say; the
 *    screen's own middle when left out <ARRAY> (default: [])
 *
 * Return Value:
 * The content group <CONTROL>
 *
 * Example:
 * [_display, [], [0.3, 0.1], "Import", {params ["_display", "_inner", "_theme"]}] call einv_setup_fnc_popover;
 *
 * Public: No
 */

disableSerialization;

params ["_display", ["_anchor", [], [[]]], ["_size", [0.3, 0.2], [[]]], ["_title", "", [""]], ["_draw", {}, [{}]], ["_arguments", []], ["_centre", [], [[]]]];
_size params ["_width", "_height"];

call FUNC(closePopover);

private _theme = GVAR(theme);
private _radius = _theme getOrDefault ["radius", 0];
private _padY = UNIT * 0.6;
private _padX = SQUARE(_padY);
private _titleH = [0, UNIT * 1.3] select (_title isNotEqualTo "");
private _cardW = _width + _padX * 2;
private _cardH = _height + _titleH + _padY * 2;
private _margin = SQUARE(UNIT * 0.5);
private _controls = [];

private _left = safezoneX + (safezoneW - _cardW) / 2;
private _top = safezoneY + (safezoneH - _cardH) / 2;

if (_anchor isNotEqualTo []) then {
    _anchor params ["_anchorX", "_anchorY", "", "_anchorH"];

    _left = _anchorX;
    _top = _anchorY + _anchorH + UNIT * 0.15;

    if (_top + _cardH > safezoneY + safezoneH - UNIT * 0.5) then {
        _top = _anchorY - _cardH - UNIT * 0.15;
    };
};

if (_anchor isEqualTo [] && {count _centre == 2}) then {
    _left = (_centre select 0) - _cardW / 2;
    _top = (_centre select 1) - _cardH / 2;
};

_left = (_left min (safezoneX + safezoneW - _cardW - _margin)) max (safezoneX + _margin);
_top = (_top min (safezoneY + safezoneH - _cardH - UNIT * 0.5)) max (safezoneY + UNIT * 0.5);

// The top layer, shown while it holds a popover. Made anew with every step drawn; one that is missing
// (a popover before the first step) is made here.
private _layer = uiNamespace getVariable [QGVAR(layer), controlNull];

if (isNull _layer) then {
    _layer = [_display] call FUNC(topLayer);
};

_layer ctrlShow true;

// A question in the middle dims the wizard under it: it is to be answered before anything else.
if (_anchor isEqualTo []) then {
    private _dim = [_display, "EINV_PanelRect", _layer, [0, 0, safezoneW, safezoneH]] call EFUNC(gui,uiCreate);
    _dim ctrlSetBackgroundColor [0, 0, 0, 0.35];
    _controls pushBack _dim;
};

// Under the card, over everything else: a click beside the card closes it, and nothing behind it is hit
// through it. A moment later - it is this control's own click.
private _catcher = [_display, "EINV_Hitbox", _layer, [0, 0, safezoneW, safezoneH]] call EFUNC(gui,uiCreate);
_catcher ctrlAddEventHandler ["ButtonClick", {[{call FUNC(closePopover)}] call FUNC(defer)}];
_catcher ctrlAddEventHandler ["MouseButtonUp", {
    params ["", "_button"];

    if (_button == 1) then {
        [{call FUNC(closePopover)}] call FUNC(defer);
    };
}];
_controls pushBack _catcher;

// In the layer, whose corner is the screen's: its place there is the snapped screen position less that.
private _card = [_display, "EINV_Group", _layer, [SNAP_X(_left) - safezoneX, SNAP_Y(_top) - safezoneY, SNAP_W(_cardW), SNAP_H(_cardH)]] call EFUNC(gui,uiCreate);
_controls pushBack _card;

(ctrlPosition _card) params ["", "", "_cardWidth", "_cardHeight"];

[_display, _card, [0, 0, _cardWidth, _cardHeight], MENU_BG, _radius] call EFUNC(gui,uiPanel);
[_display, _card, [0, 0, _cardWidth, _cardHeight], MENU_EDGE, _radius] call EFUNC(gui,uiRing);

if (_title isNotEqualTo "") then {
    private _closeH = UNIT * 1.05;
    private _closeW = SQUARE(_closeH);
    private _fontBold = _theme getOrDefault ["fontBold", "PuristaSemibold"];
    private _titleW = _cardWidth - _padX * 2 - _closeW;

    [
        _display, _card, [_padX, _padY, _titleW, _titleH * 0.8],
        [_title, _titleW, _fontBold, TEXT_HEAD] call EFUNC(gui,fitText), TEXT_HEAD,
        _theme getOrDefault ["text", [0.925, 0.933, 0.949, 1]], _fontBold, 0
    ] call EFUNC(gui,uiLabel);

    [
        _display, _card, [_cardWidth - _padX - _closeW, _padY + (_titleH * 0.8 - _closeH) / 2, _closeW, _closeH],
        "", UI_TEX(icon_close_ca), _theme, {call FUNC(closePopover)}, [], true, "ghost", LLSTRING(Close)
    ] call FUNC(uiAction);
};

private _inner = [_display, "EINV_Group", _card, [_padX, _padY + _titleH, _width, _height]] call EFUNC(gui,uiCreate);

uiNamespace setVariable [QGVAR(popover), _controls];

// The focus into the layer, so it is drawn over the pane: a button no one sees, so Return and Space press
// nothing. One pixel in the card's padding, not nothing at all - the engine may refuse the focus to a
// control with no size, and the pane would draw over the popover again. Before the content is drawn - a
// text field there takes it from here (the import box, the Same as search).
private _focus = [_display, "EINV_Hitbox", _card, [_padX / 2, _padY / 2, pixelW, pixelH]] call EFUNC(gui,uiCreate);
ctrlSetFocus _focus;

[_display, _inner, _theme, _arguments] call _draw;

_inner
