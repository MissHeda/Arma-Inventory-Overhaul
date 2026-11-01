#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Opens the size popover under the size button in the header: a small card with a slider for each size of the window
 * (fnc_sizeDefs) - its name, the slider and its value - and the window grows and shrinks behind it while a slider moves, live
 * (Mia, #51: "ahh, that gets bigger and smaller"). Top to bottom:
 *   Tiles          the cells, the item pictures and the words with them (aio_gui_cellScale), in per cent
 *   Text           the window's words on top of that (aio_gui_textSize), in per cent - larger words on small tiles, or smaller ones
 *   Rows per page  how many rows of a tall crate or vehicle show at a time (aio_gui_pageRows); "All" at the right end
 * "Default" in the title row takes every size back to its default; it shows only while one differs from it. A note at the bottom
 * says where else they are set.
 *
 * The sizes are the player's CBA client settings, both ways: a slider sets the size at once for the window (fnc_sizeSet,
 * fnc_sizeSlide) and writes it to CBA when it is let go, and a change made in CBA's options shows here and in the window at once
 * (the settings' scripts, fnc_sizeChanged). A size a server or a mission forces (fnc_settingForced) is dimmed and does not move;
 * its name's tip says why.
 *
 * The card is the sound dropdown's (fnc_openSoundMenu) in look, size and machinery - measured in UNITs, not in the window's words,
 * so it does not grow under the mouse while its own slider makes the words larger: darker than the panels, a one-pixel border, a
 * soft shadow, neutral greys, right-aligned to the window's right edge a small gap under the header's line; a layer over the
 * screen in aio_gui_menu with the hit area beside the card, aio_gui_menuFor "size", closing on a click beside it, on Escape and
 * on a click on the size button again, and then written to CBA (fnc_sizeSettle, via fnc_closeMenu).
 *
 * Like the palette popover (fnc_openPaletteMenu) it stays open while the window is built again: fnc_build asks for it to be made
 * again at its end and fnc_raiseMenu makes it again on top of a redraw. That is this function with the popover already open; it
 * then closes the old one without writing anything (aio_gui_menuRemake), and a slider that is held stays held (fnc_sizeSlide).
 * What lies in it is kept in aio_gui_sizeMenuRows, to be shown in place (fnc_updateSizeMenu).
 *
 * Arguments:
 * 0: Display <DISPLAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display] call aio_gui_fnc_openSizeMenu;
 *
 * Public: No
 */

disableSerialization;

params ["_display"];

// A field that had the cursor before the menu took the focus, to have it back when the menu goes (fnc_openMenu).
private _back = if ((uiNamespace getVariable [QGVAR(menu), []]) isEqualTo []) then {
    private _focused = focusedCtrl _display;

    [controlNull, _focused] select (!isNull _focused && {ctrlType _focused == 2})
} else {
    uiNamespace getVariable [QGVAR(menuFocusBack), controlNull]
};

// Made again where it stands: the old one goes without being written to CBA (fnc_closeMenu).
GVAR(menuRemake) = !isNull ((uiNamespace getVariable [QGVAR(menu), []]) param [0, controlNull]) && {(GVAR(menuFor) param [0, ""]) isEqualTo "size"};
[] call FUNC(closeMenu);
GVAR(menuRemake) = false;

// The name at the mouse would sit under it - and so would the comparison card (fnc_drawCompare).
(uiNamespace getVariable [QGVAR(tooltip), controlNull]) ctrlShow false;
ctrlDelete (uiNamespace getVariable [QGVAR(compare), controlNull]);
uiNamespace setVariable [QGVAR(compare), controlNull];
uiNamespace setVariable [QGVAR(tipShown), controlNull];

private _theme = GVAR(theme);
private _font = _theme getOrDefault ["font", "PuristaMedium"];
private _fontBold = _theme getOrDefault ["fontBold", _font];
private _line = [1, 1, 1, 0.08];
private _radius = (_theme getOrDefault ["radius", 0]) * 0.7;

// Neutral greys, as the sound dropdown: the card is darker than the panels (0.05) behind it, its words white and grey whatever the
// palette sets.
private _cardColor = [0.015, 0.015, 0.015, 1];
private _borderColor = [0.27, 0.27, 0.27, 1];
private _text = [1, 1, 1, 1];
private _text2 = [0.78, 0.78, 0.78, 1];
private _muted = [0.56, 0.56, 0.56, 1];

private _defs = call FUNC(sizeDefs);
private _count = count _defs;

// ----- Sizes -----

private _size = UNIT * 0.55;
private _rowH = UNIT * 1.1;
private _headH = UNIT * 1.1;
private _noteH = UNIT * 0.9;
private _padX = SQUARE(UNIT * 0.6);
private _padY = UNIT * 0.35;
private _gapX = SQUARE(UNIT * 0.45);
private _width = SQUARE(UNIT * 15);
private _height = _padY * 2 + _headH + _count * _rowH + _noteH;
private _chipH = UNIT * 0.8;
private _chipSize = UNIT * 0.44;

// Left to right: padding, name, gap, slider, gap, value, padding.
private _labelX = _padX;
private _labelW = SQUARE(UNIT * 4.8);
private _sliderX = _labelX + _labelW + _gapX;
private _valueW = SQUARE(UNIT * 1.8);
private _sliderW = _width - _padX - _valueW - _gapX - _sliderX;
private _trackH = UNIT * 0.2;
private _thumbH = UNIT * 0.55;
private _thumbW = SQUARE(_thumbH);

// The track runs between the knob's middle at the least and at the most: the knob stays inside the slider's room at both ends.
private _trackX = _sliderX + _thumbW / 2;
private _trackW = _sliderW - _thumbW;

// The right edge of the window - the header's, where the Close button ends - and a small gap under the header's line, kept on the screen.
private _left = ((CONTENT_X + CONTENT_W - _width) min (safezoneX + safezoneW - _width)) max safezoneX;
private _top = (((HEAD_Y + HEAD_H + UNIT * 0.5) max (safezoneY + UNIT * 2.6 + pixelH * 3)) min (safezoneY + safezoneH - _height)) max safezoneY;
private _cardX = _left - safezoneX;
private _cardY = _top - safezoneY;

// ----- The layer, the hit area beside the card, the card -----

private _layer = [_display, "AIO_Group", controlNull, [safezoneX, safezoneY, safezoneW, safezoneH]] call FUNC(uiCreate);

// Settings, not the inventory: no word in it takes the gradient (fnc_uiLabel).
_layer setVariable [QGVAR(plain), true];

// A group keeps the mouse's buttons from the display's own handlers: it reports them as the columns do (fnc_build)
// and so does the hit area over the screen in it (fnc_openMenu).
_layer setVariable [QGVAR(hooked), true];
_layer ctrlAddEventHandler ["MouseButtonDown", {[true, _this] call FUNC(onMouseButton); false}];
_layer ctrlAddEventHandler ["MouseButtonUp", {[false, _this] call FUNC(onMouseButton); false}];

private _catcher = [_display, "AIO_Hitbox", _layer, [0, 0, safezoneW, safezoneH]] call FUNC(uiCreate);
_catcher ctrlAddEventHandler ["MouseButtonDown", {[true, _this] call FUNC(onMouseButton); false}];
_catcher ctrlAddEventHandler ["MouseButtonUp", {[false, _this] call FUNC(onMouseButton); false}];
_catcher ctrlAddEventHandler ["ButtonClick", {[{[] call FUNC(closeMenu)}] call FUNC(later)}];

// The shadow (a faint dark panel a few pixels lower), the border (the card's size in the border's colour) and the
// card one pixel in from it.
[_display, _layer, [_cardX, _cardY + pixelH * 3, _width, _height], [0, 0, 0, 0.35], _radius] call FUNC(uiPanel);
[_display, _layer, [_cardX, _cardY, _width, _height], _borderColor, _radius] call FUNC(uiPanel);
[
    _display, _layer, [_cardX + pixelW, _cardY + pixelH, _width - pixelW * 2, _height - pixelH * 2], _cardColor, (_radius - pixelH) max 0
] call FUNC(uiPanel);

// A click on the card between its controls is no click beside it: this takes it, and does nothing (the catcher above closes the
// popover only for a click beside the card).
[_display, "AIO_Hitbox", _layer, [_cardX, _cardY, _width, _height]] call FUNC(uiCreate);

// ----- The top: the title, with Default -----

private _headTop = _cardY + _padY;

[_display, _layer, [_cardX + _padX, _headTop, _width - _padX * 2, _headH], LLSTRING(Size_Title), _size, _text2, _fontBold, 0, "menu"] call FUNC(uiLabel);

// What the small button is drawn with: neutral films, the light ink of the card - the palette popover's.
private _buttonTheme = createHashMapFromArray [
    ["button", [1, 1, 1, 0.08]],
    ["buttonHover", [1, 1, 1, 0.18]],
    ["buttonText", _text2],
    ["font", _font],
    ["muted", _muted],
    ["radius", UNIT * 0.3],
    ["upper", false]
];

private _chipW = [LLSTRING(Size_Default), "", _chipH, _chipSize, _buttonTheme] call FUNC(buttonWidth);

private _reset = [
    _display, _layer, [_cardX + _width - _padX - _chipW, _headTop + (_headH - _chipH) / 2, _chipW, _chipH], "default", LLSTRING(Size_Default), "",
    _buttonTheme, {
        params ["_button"];

        // A left click only.
        if (_button < 0) exitWith {};

        ["reset"] call FUNC(sizeSet);
    }, false, _chipSize, true
] call FUNC(uiButton);

[(_reset param [count _reset - 1, controlNull]), LLSTRING(Size_Default_Tip)] call FUNC(setTooltip);

[_display, _layer, [_cardX + _padX, _headTop + _headH - pixelH, _width - _padX * 2, pixelH], _line] call FUNC(uiPanel);

// ----- A row for each size -----

private _rows = [];

{
    _x params ["_setting", "_name", "_tip"];

    private _rowTop = _headTop + _headH + _forEachIndex * _rowH;
    private _forced = [_setting] call FUNC(settingForced);

    private _label = [
        _display, _layer, [_cardX + _labelX, _rowTop, _labelW, _rowH], [_name, _labelW, _font, _size] call FUNC(fitText), _size, _text, _font, 0, "never"
    ] call FUNC(uiLabel);

    // The name's tip says what the size is - and that the server set it, where it did. Its hit area ends where the slider's begins.
    private _nameHit = [_display, "AIO_Hitbox", _layer, [_cardX + _labelX, _rowTop, _labelW, _rowH]] call FUNC(uiCreate);

    [_nameHit, [_tip, _tip + " " + LLSTRING(Size_Forced)] select _forced] call FUNC(setTooltip);

    private _trackY = _rowTop + (_rowH - _trackH) / 2;

    [_display, _layer, [_cardX + _trackX, _trackY, _trackW, _trackH], [1, 1, 1, 0.12], _trackH / 2] call FUNC(uiPanel);

    private _fill = [_display, "AIO_PanelRect", _layer, [_cardX + _trackX, _trackY, _trackW, _trackH]] call FUNC(uiCreate);
    private _thumbTop = _rowTop + (_rowH - _thumbH) / 2;
    private _thumb = [_display, _layer, [_cardX + _trackX - _thumbW / 2, _thumbTop, _thumbW, _thumbH], UI_TEX(circle_ca), _text] call FUNC(uiIcon);

    private _value = [
        _display, _layer, [_cardX + _width - _padX - _valueW, _rowTop, _valueW, _rowH], "", _size * 0.9, _text2, _font, 1, "menu"
    ] call FUNC(uiLabel);

    // The hit area is the slider's whole room, a knob's width beyond the track at each end: a press near an end is that end. The
    // track's place on the screen goes with it, for the mouse's place along it (fnc_sizeSlide). None where the server set the size.
    if (!_forced) then {
        private _hit = [_display, "AIO_Hitbox", _layer, [_cardX + _sliderX, _rowTop, _sliderW, _rowH]] call FUNC(uiCreate);

        _hit setVariable [QGVAR(slider), [_forEachIndex, safezoneX + _cardX + _trackX, _trackW]];

        _hit ctrlAddEventHandler ["MouseButtonDown", {
            params ["_ctrl", "_button"];

            if (_button != 0) exitWith {};

            (_ctrl getVariable [QGVAR(slider), []]) params ["_index", "_left", "_width"];

            ["begin", [ctrlParent _ctrl, _index, _left, _width]] call FUNC(sizeSlide);
        }];
    };

    // The track's place relative to the layer, and the knob's, for fnc_updateSizeMenu.
    _rows pushBack [_forEachIndex, _forced, _label, _fill, _thumb, _value, [_cardX + _trackX, _trackY, _trackW, _trackH, _thumbW, _thumbH, _thumbTop]];
} forEach _defs;

// ----- The note: where else the sizes are -----

private _noteTop = _headTop + _headH + _count * _rowH;

[_display, _layer, [_cardX + _padX, _noteTop, _width - _padX * 2, pixelH], _line] call FUNC(uiPanel);
[
    _display, _layer, [_cardX + _padX, _noteTop, _width - _padX * 2, _noteH],
    [LLSTRING(Size_Note), _width - _padX * 2, _font, _size * 0.8] call FUNC(fitText), _size * 0.8, _muted, _font, 0, "never"
] call FUNC(uiLabel);

// The focus into the layer, so it is drawn over everything: a button no one sees, one pixel in the card's
// padding. Return and Space press nothing on it (fnc_openMenu).
private _focus = [_display, "AIO_Hitbox", _layer, [_cardX + _padX / 2, _cardY + _padY / 2, pixelW, pixelH]] call FUNC(uiCreate);
ctrlSetFocus _focus;

uiNamespace setVariable [QGVAR(menu), [_layer]];
uiNamespace setVariable [QGVAR(menuFocusBack), _back];
uiNamespace setVariable [QGVAR(menuRect), [_left, _top, _width, _height]];
uiNamespace setVariable [QGVAR(sizeMenuRows), [_rows, _reset]];

// What it shows, to make it again on top (fnc_raiseMenu); who it is for, so that closing it is known (fnc_closeMenu).
GVAR(menuState) = ["size"];
GVAR(menuFor) = ["size", -1];

[] call FUNC(updateSizeMenu);
[] call FUNC(updateSizeButton);
