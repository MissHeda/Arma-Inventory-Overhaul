#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Opens the palette popover under the palette button in the header: a small card where the player picks the window's colours
 * and transparency, live. Three blocks, each a row with its name, a swatch of what is set and a small button that takes the
 * choice away, then its sliders:
 *   Accent        hue and vividness; "Use my Arma colour" goes back to the colour of Options > Game > Colors
 *   Secondary     hue and vividness; "Match accent" goes back to the themes' own films (what it tints: fnc_theme)
 *   Transparency  how see-through the panels are, 0 % up to the most PALETTE_ALPHA_MIN allows; "Default"
 * and "Reset all" in the title row. The buttons show only while there is a choice to take away. A colour is a hue (a rainbow
 * track) and a vividness (a track from white to the full colour of that hue): two sliders pick any colour, red or white
 * or pink, without three numbers to balance. Where nothing is chosen the sliders stand at the colour the window wears now
 * (fnc_paletteInfo). Every move goes to fnc_paletteSet (fnc_paletteSlide drags the sliders), which updates this card in place
 * (fnc_updatePaletteMenu) and builds the window again for the colour.
 *
 * The card is the sound dropdown's (fnc_openSoundMenu) in look and machinery: darker than the panels, a one-pixel border, a
 * soft shadow, neutral greys - the swatches and tracks are the only colour -, right-aligned to the window's right edge a small
 * gap under the header's line; a layer over the screen in einv_gui_menu with the hit area beside the card, einv_gui_menuFor
 * "palette", closing on a click beside it, on Escape and on a click on the palette button again, and then written to the profile
 * (fnc_paletteSettle, via fnc_closeMenu).
 *
 * Unlike the dropdown it stays open while the window is built again: fnc_build asks for it to be made again at its end and
 * fnc_raiseMenu makes it again on top of a redraw. That is this function with the popover already open; it then closes the old
 * one without writing anything (einv_gui_menuRemake) and a slider that is held stays held (fnc_paletteSlide).
 *
 * Arguments:
 * 0: Display <DISPLAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display] call einv_gui_fnc_openPaletteMenu;
 *
 * Public: No
 */

disableSerialization;

params ["_display"];

// The server switched the palette off while it was open: it closes.
if !([] call FUNC(paletteAllowed)) exitWith {
    [] call FUNC(closeMenu);
};

// A field that had the cursor before the menu took the focus, to have it back when the menu goes (fnc_openMenu).
private _back = if ((uiNamespace getVariable [QGVAR(menu), []]) isEqualTo []) then {
    private _focused = focusedCtrl _display;

    [controlNull, _focused] select (!isNull _focused && {ctrlType _focused == 2})
} else {
    uiNamespace getVariable [QGVAR(menuFocusBack), controlNull]
};

// Made again where it stands: the old one goes without being written to the profile (fnc_closeMenu).
GVAR(menuRemake) = !isNull ((uiNamespace getVariable [QGVAR(menu), []]) param [0, controlNull]) && {(GVAR(menuFor) param [0, ""]) isEqualTo "palette"};
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
private _text = _theme getOrDefault ["text", [1, 1, 1, 1]];
private _text2 = _theme getOrDefault ["text2", [0.78, 0.78, 0.78, 1]];
private _line = [1, 1, 1, 0.08];
private _radius = (_theme getOrDefault ["radius", 0]) * 0.7;

// Neutral greys, as the sound dropdown: the card is darker than the panels (0.05) behind it.
private _cardColor = [0.015, 0.015, 0.015, 1];
private _borderColor = [0.27, 0.27, 0.27, 1];

// What the sliders are, by their index (fnc_paletteSet): its name and its kind.
private _sliders = [
    [LLSTRING(Palette_Hue), "hue"],
    [LLSTRING(Palette_Vividness), "vivid"],
    [LLSTRING(Palette_Hue), "hue"],
    [LLSTRING(Palette_Vividness), "vivid"],
    [LLSTRING(Palette_Panels), "alpha"]
];

// The blocks: id, name, what it tints (the name's tooltip), the button that takes the choice away, its sliders.
private _blocks = [
    ["accent", LLSTRING(Palette_Accent), LLSTRING(Palette_Accent_Tip), LLSTRING(Palette_UseArma), [0, 1]],
    ["secondary", LLSTRING(Palette_Secondary), LLSTRING(Palette_Secondary_Tip), LLSTRING(Palette_MatchAccent), [2, 3]],
    ["alpha", LLSTRING(Palette_Transparency), LLSTRING(Palette_Transparency_Tip), LLSTRING(Palette_Default), [4]]
];

// ----- Sizes -----

private _size = UNIT * 0.55;
private _small = UNIT * 0.5;
private _titleH = UNIT * 1.1;
private _headH = UNIT * 1.2;
private _rowH = UNIT * 0.95;
private _gapY = UNIT * 0.2;
private _padX = SQUARE(UNIT * 0.6);
private _padY = UNIT * 0.35;
private _gapX = SQUARE(UNIT * 0.45);
private _width = SQUARE(UNIT * 15.5);

private _sliderCount = 0;

{_sliderCount = _sliderCount + count (_x select 4)} forEach _blocks;

private _height = _padY * 2 + _titleH + (count _blocks) * (_gapY + _headH) + _sliderCount * _rowH;

// Left to right in a slider's row: padding, name, gap, slider, gap, value, padding.
private _labelW = SQUARE(UNIT * 3.2);
private _sliderX = _padX + _labelW + _gapX;
private _valueW = SQUARE(UNIT * 1.6);
private _sliderW = _width - _padX - _valueW - _gapX - _sliderX;
private _trackH = UNIT * 0.26;
private _thumbH = UNIT * 0.55;
private _thumbW = SQUARE(_thumbH);

// The track runs between the knob's middle at 0 and at full: the knob stays inside the slider's room at both ends.
private _trackX = _sliderX + _thumbW / 2;
private _trackW = _sliderW - _thumbW;

private _swatchH = UNIT * 0.7;
private _swatchW = SQUARE(UNIT * 1.4);
private _nameW = SQUARE(UNIT * 4.2);
private _chipH = UNIT * 0.8;
private _chipSize = UNIT * 0.44;

// The right edge of the window - the header's, where the Close button ends - and a small gap under the header's line, kept on the screen.
private _left = ((CONTENT_X + CONTENT_W - _width) min (safezoneX + safezoneW - _width)) max safezoneX;
private _top = ((HEAD_Y + HEAD_H + UNIT * 0.5) max (safezoneY + UNIT * 2.6 + pixelH * 3)) min (safezoneY + safezoneH - _height);
private _cardX = _left - safezoneX;
private _cardY = _top - safezoneY;

// ----- The layer, the hit area beside the card, the card -----

private _layer = [_display, "EINV_Group", controlNull, [safezoneX, safezoneY, safezoneW, safezoneH]] call FUNC(uiCreate);

// A group keeps the mouse's buttons from the display's own handlers: it reports them as the columns do (fnc_build)
// and so does the hit area over the screen in it (fnc_openMenu).
_layer setVariable [QGVAR(hooked), true];
_layer ctrlAddEventHandler ["MouseButtonDown", {[true, _this] call FUNC(onMouseButton); false}];
_layer ctrlAddEventHandler ["MouseButtonUp", {[false, _this] call FUNC(onMouseButton); false}];

private _catcher = [_display, "EINV_Hitbox", _layer, [0, 0, safezoneW, safezoneH]] call FUNC(uiCreate);
_catcher ctrlAddEventHandler ["MouseButtonDown", {[true, _this] call FUNC(onMouseButton); false}];
_catcher ctrlAddEventHandler ["MouseButtonUp", {[false, _this] call FUNC(onMouseButton); false}];
_catcher ctrlAddEventHandler ["ButtonClick", {[{[] call FUNC(closeMenu)}] call FUNC(later)}];

// The shadow, the border (the card's size in the border's colour) and the card one pixel in from it.
[_display, _layer, [_cardX, _cardY + pixelH * 3, _width, _height], [0, 0, 0, 0.35], _radius] call FUNC(uiPanel);
[_display, _layer, [_cardX, _cardY, _width, _height], _borderColor, _radius] call FUNC(uiPanel);
[
    _display, _layer, [_cardX + pixelW, _cardY + pixelH, _width - pixelW * 2, _height - pixelH * 2], _cardColor, (_radius - pixelH) max 0
] call FUNC(uiPanel);

// What the small buttons are drawn with: neutral films, the light ink of the card.
private _buttonTheme = createHashMapFromArray [
    ["button", [1, 1, 1, 0.08]],
    ["buttonHover", [1, 1, 1, 0.18]],
    ["buttonText", _text2],
    ["font", _font],
    ["muted", [0.56, 0.56, 0.56, 1]],
    ["radius", UNIT * 0.3],
    ["upper", false]
];

// A small button that takes a choice away: its width is its words', its place the card's right padding or a given right edge.
private _fnc_chip = {
    params ["_id", "_words", "_rowTop", "_rowHeight"];

    private _chipW = [_words, "", _chipH, _chipSize, _buttonTheme] call FUNC(buttonWidth);

    [
        _display, _layer, [_cardX + _width - _padX - _chipW, _rowTop + (_rowHeight - _chipH) / 2, _chipW, _chipH], _id, _words, "",
        _buttonTheme, {
            params ["_button", "_id"];

            // A left click only.
            if (_button < 0) exitWith {};

            ["reset", _id] call FUNC(paletteSet);
        }, false, _chipSize, true
    ] call FUNC(uiButton)
};

// ----- The title, with Reset all -----

private _headTop = _cardY + _padY;

[_display, _layer, [_cardX + _padX, _headTop, _width - _padX * 2, _titleH], LLSTRING(Palette_Title), _size, _text2, _fontBold, 0] call FUNC(uiLabel);

private _resetAll = ["all", LLSTRING(Palette_ResetAll), _headTop, _titleH] call _fnc_chip;

[_display, _layer, [_cardX + _padX, _headTop + _titleH - pixelH, _width - _padX * 2, pixelH], _line] call FUNC(uiPanel);

// ----- One slider: its name, a track, a knob and its value, and the hit area that drags it -----

private _fnc_slider = {
    params ["_index", "_rowTop"];

    private _kind = (_sliders select _index) select 1;
    private _trackY = _rowTop + (_rowH - _trackH) / 2;
    private _trackRect = [_cardX + _trackX, _trackY, _trackW, _trackH];
    private _extra = controlNull;

    [
        _display, _layer, [_cardX + _padX, _rowTop, _labelW, _rowH], [(_sliders select _index) select 0, _labelW, _font, _small] call FUNC(fitText),
        _small, _text2, _font, 0
    ] call FUNC(uiLabel);

    // The track is a picture stretched over it (EINV_PanelCorner): every hue, from red round to red; or a panel of the pure
    // hue with white fading out over it, which updates with the hue (fnc_updatePaletteMenu); or a plain track and its fill.
    switch (_kind) do {
        case "hue": {
            private _strip = [_display, "EINV_PanelCorner", _layer, _trackRect] call FUNC(uiCreate);

            _strip ctrlSetText UI_TEX(hue_strip_ca);
            _strip ctrlSetTextColor [1, 1, 1, 1];
        };
        case "vivid": {
            _extra = [_display, "EINV_PanelRect", _layer, _trackRect] call FUNC(uiCreate);
            _extra ctrlSetBackgroundColor [1, 0, 0, 1];

            private _fade = [_display, "EINV_PanelCorner", _layer, _trackRect] call FUNC(uiCreate);

            _fade ctrlSetText UI_TEX(fade_strip_ca);
            _fade ctrlSetTextColor [1, 1, 1, 1];
        };
        default {
            [_display, _layer, _trackRect, [1, 1, 1, 0.12], _trackH / 2] call FUNC(uiPanel);

            _extra = [_display, "EINV_PanelRect", _layer, _trackRect] call FUNC(uiCreate);
            _extra ctrlSetBackgroundColor [0.72, 0.72, 0.72, 1];
        };
    };

    // The knob is white on a dark ring: white alone would vanish at the white end of a vividness track.
    private _thumbTop = _rowTop + (_rowH - _thumbH) / 2;
    private _ring = [
        _display, _layer, [_cardX + _trackX - _thumbW / 2 - pixelW * 2, _thumbTop - pixelH * 2, _thumbW + pixelW * 4, _thumbH + pixelH * 4],
        UI_TEX(circle_ca), [0.04, 0.04, 0.04, 0.9]
    ] call FUNC(uiIcon);
    private _thumb = [
        _display, _layer, [_cardX + _trackX - _thumbW / 2, _thumbTop, _thumbW, _thumbH], UI_TEX(circle_ca), _text
    ] call FUNC(uiIcon);

    private _value = [
        _display, _layer, [_cardX + _width - _padX - _valueW, _rowTop, _valueW, _rowH], "", _small * 0.9, _text2, _font, 1
    ] call FUNC(uiLabel);

    // The hit area is the slider's whole room, a knob's width beyond the track at each end: a press near an end is that end. The
    // track's place on the screen goes with it, for the mouse's place along it (fnc_paletteSlide).
    private _hit = [_display, "EINV_Hitbox", _layer, [_cardX + _sliderX, _rowTop, _sliderW, _rowH]] call FUNC(uiCreate);

    _hit setVariable [QGVAR(slider), [_index, safezoneX + _cardX + _trackX, _trackW]];

    _hit ctrlAddEventHandler ["MouseButtonDown", {
        params ["_ctrl", "_button"];

        if (_button != 0) exitWith {};

        (_ctrl getVariable [QGVAR(slider), []]) params ["_index", "_left", "_width"];

        ["begin", [ctrlParent _ctrl, _index, _left, _width]] call FUNC(paletteSlide);
    }];

    // The knob's place relative to the layer, for fnc_updatePaletteMenu.
    [[_ring, _thumb], [_cardX + _trackX, _trackY, _trackW, _trackH, _thumbW, _thumbH, _thumbTop], _value, _extra]
};

// ----- The blocks -----

private _sliderRows = [];
private _swatches = [];
private _chips = [];
private _y = _headTop + _titleH;

{
    _x params ["_id", "_name", "_tip", "_words", "_indices"];

    private _blockIndex = _forEachIndex;

    _y = _y + _gapY;

    // Its row: the name, what is set, the button that takes it away.
    if (_blockIndex > 0) then {
        [_display, _layer, [_cardX + _padX, _y - _gapY / 2, _width - _padX * 2, pixelH], [1, 1, 1, 0.05]] call FUNC(uiPanel);
    };

    private _nameRect = [_cardX + _padX, _y, _nameW, _headH];

    [_display, _layer, _nameRect, _name, _size, _text, _fontBold, 0] call FUNC(uiLabel);

    private _nameHit = [_display, "EINV_Hitbox", _layer, _nameRect] call FUNC(uiCreate);

    _nameHit ctrlSetTooltip _tip;

    private _swatchRect = [_cardX + _padX + _nameW, _y + (_headH - _swatchH) / 2, _swatchW, _swatchH];
    private _swatchRadius = UNIT * 0.2;

    // The transparency's swatch is the panel colour over a mid grey, so that what shows through is seen.
    if (_id isEqualTo "alpha") then {
        [_display, _layer, _swatchRect, [0.55, 0.55, 0.55, 1], _swatchRadius] call FUNC(uiPanel);
    };

    _swatches pushBack ([_display, _layer, _swatchRect, [0, 0, 0, 1], _swatchRadius] call FUNC(uiPanel));
    _chips pushBack ([_id, _words, _y, _headH] call _fnc_chip);

    _y = _y + _headH;

    {
        _sliderRows set [_x, [_x, _y] call _fnc_slider];

        _y = _y + _rowH;
    } forEach _indices;
} forEach _blocks;

// The focus into the layer, so it is drawn over everything: a button no one sees, one pixel in the card's
// padding. Return and Space press nothing on it (fnc_openMenu).
private _focus = [_display, "EINV_Hitbox", _layer, [_cardX + _padX / 2, _cardY + _padY / 2, pixelW, pixelH]] call FUNC(uiCreate);
ctrlSetFocus _focus;

uiNamespace setVariable [QGVAR(menu), [_layer]];
uiNamespace setVariable [QGVAR(menuFocusBack), _back];
uiNamespace setVariable [QGVAR(menuRect), [_left, _top, _width, _height]];

// What lies in it, to show the values in place (fnc_updatePaletteMenu): by slider index, the knob's two circles, its place, its value
// and the panel or fill behind its track; the swatches and the buttons by block.
uiNamespace setVariable [QGVAR(paletteRows), createHashMapFromArray [
    ["sliders", _sliderRows],
    ["swatches", _swatches],
    ["chips", _chips],
    ["resetAll", _resetAll]
]];

// What it shows, to make it again on top (fnc_raiseMenu); who it is for, so that closing it is known (fnc_closeMenu).
GVAR(menuState) = ["palette"];
GVAR(menuFor) = ["palette", -1];

[] call FUNC(updatePaletteMenu);
[] call FUNC(updatePaletteButton);
