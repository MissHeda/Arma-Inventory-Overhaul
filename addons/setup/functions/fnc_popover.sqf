#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Opens a popover over the wizard - a card in the style of Enhanced First Aid Kits' menus, below what
 * opened it (above when there is no room below), or in the middle of the screen over a dimmed wizard for
 * a question that has to be answered. A click anywhere beside it closes it (a hit area over the whole
 * screen, under the card), as does Escape. Only one at a time: opening one closes the last.
 *
 * The card is made on the display itself, after the wizard's pane, so it lies over all of it. Its
 * content is drawn by the caller, into the group this returns.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Screen rectangle [x, y, w, h] of what opened it, [] for the middle of the screen <ARRAY>
 * 2: Size of the content, [w, h] <ARRAY>
 * 3: Title, "" for none <STRING>
 * 4: Code drawing the content, called with [display, content group, theme, arguments] <CODE>
 * 5: Arguments <ANY> (default: [])
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

params ["_display", ["_anchor", [], [[]]], ["_size", [0.3, 0.2], [[]]], ["_title", "", [""]], ["_draw", {}, [{}]], ["_arguments", []]];
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

_left = (_left min (safezoneX + safezoneW - _cardW - _margin)) max (safezoneX + _margin);
_top = (_top min (safezoneY + safezoneH - _cardH - UNIT * 0.5)) max (safezoneY + UNIT * 0.5);

// A question in the middle dims the wizard under it: it is to be answered before anything else.
if (_anchor isEqualTo []) then {
    private _dim = _display ctrlCreate ["EINV_PanelRect", -1];
    _dim ctrlSetPosition [safezoneX, safezoneY, safezoneW, safezoneH];
    _dim ctrlSetBackgroundColor [0, 0, 0, 0.35];
    _dim ctrlCommit 0;
    _controls pushBack _dim;
};

// Under the card, over everything else: a click beside the card closes it. A moment later - it is this
// control's own click.
private _catcher = _display ctrlCreate ["EINV_Hitbox", -1];
_catcher ctrlSetPosition [safezoneX, safezoneY, safezoneW, safezoneH];
_catcher ctrlCommit 0;
_catcher ctrlAddEventHandler ["ButtonClick", {[{call FUNC(closePopover)}] call FUNC(defer)}];
_catcher ctrlAddEventHandler ["MouseButtonUp", {
    params ["", "_button"];

    if (_button == 1) then {
        [{call FUNC(closePopover)}] call FUNC(defer);
    };
}];
_controls pushBack _catcher;

private _card = _display ctrlCreate ["EINV_Group", -1];
_card ctrlSetPosition [SNAP_X(_left), SNAP_Y(_top), SNAP_W(_cardW), SNAP_H(_cardH)];
_card ctrlCommit 0;
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

[_display, _inner, _theme, _arguments] call _draw;

_inner
