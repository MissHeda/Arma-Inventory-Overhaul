#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The red screen's display was created: builds its card inside a controls group of its own - the title, the
 * reason, the server's own message and the button.
 *
 * Red glass: the screen is dimmed and tinted with the theme's loss colour, with a card of the window's glass
 * in the middle, a ring in the same colour round it and the blocked sign over the words. The group is made
 * with ctrlCreate and holds everything, so nothing of it lands in the window engine's list of controls
 * (this display is not the window and has no frame). The one control that takes the focus, the button, lies
 * inside the card and overlaps nothing, so being drawn on top when focused changes nothing.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display] call einv_arsenal_fnc_onBlockedLoad;
 *
 * Public: No
 */

disableSerialization;

params [["_display", displayNull, [displayNull]]];

if (isNull _display) exitWith {};

private _theme = call EFUNC(gui,theme);
private _font = _theme getOrDefault ["font", "RobotoCondensed"];
private _fontBold = _theme getOrDefault ["fontBold", "RobotoCondensedBold"];
private _loss = _theme getOrDefault ["loss", [0.941, 0.333, 0.353, 1]];

// The whole screen, in one group; what is in it counts from its corner.
private _group = _display ctrlCreate ["EINV_Group", -1];
_group ctrlSetPosition [safezoneX, safezoneY, safezoneW, safezoneH];
_group ctrlCommit 0;

// Red glass: dark, with the loss colour over it.
[_display, _group, [0, 0, safezoneW, safezoneH], [0.04, 0.045, 0.055, 0.55]] call EFUNC(gui,uiPanel);
[_display, _group, [0, 0, safezoneW, safezoneH], [_loss select 0, _loss select 1, _loss select 2, 0.16]] call EFUNC(gui,uiPanel);

// The card in the middle.
private _cardW = SQUARE(UNIT * 22);
private _cardH = UNIT * 17;
private _cardX = (safezoneW - _cardW) / 2;
private _cardY = (safezoneH - _cardH) / 2;
private _radius = _theme getOrDefault ["radius", UNIT * 0.45];
private _pad = SQUARE(UNIT * 1.2);
private _innerW = _cardW - _pad * 2;

[_display, _group, [_cardX, _cardY, _cardW, _cardH], _theme getOrDefault ["panel", [0.04, 0.045, 0.055, 0.85]], _radius] call EFUNC(gui,uiPanel);
[_display, _group, [_cardX, _cardY, _cardW, _cardH], _loss, _radius] call EFUNC(gui,uiRing);

private _y = _cardY + UNIT * 1;
private _iconH = UNIT * 3;

[_display, _group, [_cardX + (_cardW - SQUARE(_iconH)) / 2, _y, SQUARE(_iconH), _iconH], UI_TEX(icon_blocked_ca), _loss] call EFUNC(gui,uiIcon);

_y = _y + _iconH + UNIT * 0.7;

private _titleSize = UNIT * 1.0;

[
    _display, _group, [_cardX + _pad, _y, _innerW, UNIT * 1.4],
    [LLSTRING(Blocked_Title), _innerW, _fontBold, _titleSize] call EFUNC(gui,fitText), _titleSize, _theme getOrDefault ["text", [0.925, 0.933, 0.949, 1]], _fontBold, 2
] call EFUNC(gui,uiLabel);

_y = _y + UNIT * 1.7;

// The colour as structured text wants it.
private _fnc_hex = {
    params ["_color"];

    "#" + ((_color select [0, 3]) apply {
        private _value = round ((_x max 0 min 1) * 255);

        ("0123456789ABCDEF" select [floor (_value / 16), 1]) + ("0123456789ABCDEF" select [_value mod 16, 1])
    } joinString "")
};

// Words in the card, as many lines as given; the server's message may be longer than one.
private _fnc_text = {
    params ["_text", "_color", "_lines"];

    private _height = UNIT * 0.7 * 1.3 * _lines;
    private _box = [_display, "EINV_StructuredText", _group, [_cardX + _pad, _y, _innerW, _height]] call EFUNC(gui,uiCreate);

    _box ctrlSetStructuredText (text _text setAttributes ["align", "center", "valign", "top", "font", _font, "color", [_color] call _fnc_hex]);
    _y = _y + _height;
};

[LLSTRING(Blocked_Text), _theme getOrDefault ["text2", [0.639, 0.675, 0.725, 1]], 1] call _fnc_text;

private _message = missionNamespace getVariable [QGVAR(biMessage), ""];

if (_message isNotEqualTo "") then {
    _y = _y + UNIT * 0.3;
    [_message, _theme getOrDefault ["text", [0.925, 0.933, 0.949, 1]], 3] call _fnc_text;
};

// Where to look for the setting, small and muted at the bottom.
private _small = UNIT * 0.5;

[
    _display, _group, [_cardX + _pad, _cardY + _cardH - UNIT * 3.7, _innerW, UNIT * 0.9],
    [LLSTRING(Blocked_Setting), _innerW, _font, _small] call EFUNC(gui,fitText), _small, _theme getOrDefault ["muted", [0.412, 0.443, 0.494, 1]], _font, 2
] call EFUNC(gui,uiLabel);

private _buttonW = SQUARE(UNIT * 8);
private _buttonTheme = createHashMap;
_buttonTheme merge _theme;
_buttonTheme set ["buttonText", _theme getOrDefault ["accent", [1, 1, 1, 1]]];

[
    _display, _group, [_cardX + (_cardW - _buttonW) / 2, _cardY + _cardH - UNIT * 2.4, _buttonW, UNIT * 1.5], "ok", LLSTRING(Blocked_OK), "", _buttonTheme,
    {(findDisplay IDD_ARSENAL_BLOCKED) closeDisplay 2}
] call EFUNC(gui,uiButton);
