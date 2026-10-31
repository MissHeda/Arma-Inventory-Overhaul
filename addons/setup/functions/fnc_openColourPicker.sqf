#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * A colour picker in a popover (fnc_popover), as the window's colour panel has one (aio_gui_fnc_openPaletteMenu): a colour
 * square (the saturation across, the value down - the pure hue with a white fade and a black fade over it), a strip of hues
 * beside it, under them the colour as it is and its six hex digits to type, and the buttons Default (no colour of its own)
 * and Apply. Pressing on the square or the strip and moving picks live in the popover; nothing is written before Apply,
 * so the undo history gets one step per colour. The Categories card opens it from a category's colour (issue #33).
 * While a picker is held the display follows the mouse (MouseMoving, MouseButtonUp), as fnc_paletteSlide does for the
 * colour panel. The state is kept in uiNamespace aio_setup_colourPick.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Screen rectangle of what opened it [x, y, w, h] <ARRAY>
 * 2: Title <STRING>
 * 3: The colour now, six hex digits, "" for none <STRING>
 * 4: The colour shown while there is none, [r, g, b] 0 to 1 <ARRAY>
 * 5: Code, called with [six hex digits or "" for Default, arguments] <CODE>
 * 6: Arguments <ANY> (default: [])
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, _rect, "Medical", "c03030", [0.12, 0.21, 0.14], {params ["_hex", "_id"]}, "medical"] call aio_setup_fnc_openColourPicker;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_anchor", ["_title", "", [""]], ["_hex", "", [""]], ["_plain", [0.5, 0.5, 0.5], [[]]], ["_code", {}, [{}]], ["_arguments", []]];

// Six hex digits to [r, g, b], [] for anything else.
private _fnc_rgb = {
    params ["_text"];

    private _digits = "0123456789abcdef";
    private _clean = toLowerANSI ((trim _text) regexReplace ["#", ""]);

    if (count _clean != 6) exitWith {[]};

    private _nibbles = (_clean splitString "") apply {_digits find _x};

    if (_nibbles findIf {_x < 0} >= 0) exitWith {[]};

    [0, 2, 4] apply {((_nibbles select _x) * 16 + (_nibbles select (_x + 1))) / 255}
};

private _rgb = [_hex] call _fnc_rgb;

if (_rgb isEqualTo []) then {
    _rgb = _plain select [0, 3];
};

private _state = createHashMapFromArray [
    ["hsv", ["hsv", _rgb] call EFUNC(gui,hsv)],
    ["code", _code],
    ["arguments", _arguments],
    ["fnc_rgb", _fnc_rgb]
];

uiNamespace setVariable [QGVAR(colourPick), _state];

private _pickH = UNIT * 7;
private _pickW = SQUARE(_pickH);
private _stripW = SQUARE(UNIT * 0.9);
private _gap = SQUARE(UNIT * 0.4);
private _rowH = UNIT * 1.1;
private _width = _pickW + _gap + _stripW;
private _height = _pickH + (_rowH + UNIT * 0.35) * 2;

[_display, _anchor, [_width, _height], _title, {
    params ["_display", "_inner", "_theme", "_sizes"];
    _sizes params ["_pickW", "_pickH", "_stripW", "_gap", "_rowH", "_width"];

    private _state = uiNamespace getVariable [QGVAR(colourPick), createHashMap];
    private _radius = (_theme getOrDefault ["radius", 0]) min (UNIT * 0.3);
    private _knobH = UNIT * 0.7;
    private _knobW = SQUARE(_knobH);

    // The square: the pure hue, white fading out to the right, black fading in downwards.
    private _squareRect = [0, 0, _pickW, _pickH];
    private _base = [_display, "AIO_PanelRect", _inner, _squareRect] call EFUNC(gui,uiCreate);

    {
        private _fade = [_display, "AIO_PanelCorner", _inner, _squareRect] call EFUNC(gui,uiCreate);

        _fade ctrlSetText _x;
        _fade ctrlSetTextColor [1, 1, 1, 1];
    } forEach [UI_TEX(fade_strip_ca), UI_TEX(shade_strip_ca)];

    [_display, _inner, _squareRect, [1, 1, 1, 0.22]] call EFUNC(gui,uiFrame);

    // The hues beside it.
    private _stripRect = [_pickW + _gap, 0, _stripW, _pickH];
    private _strip = [_display, "AIO_PanelCorner", _inner, _stripRect] call EFUNC(gui,uiCreate);

    _strip ctrlSetText UI_TEX(hue_vstrip_ca);
    _strip ctrlSetTextColor [1, 1, 1, 1];

    [_display, _inner, _stripRect, [1, 1, 1, 0.22]] call EFUNC(gui,uiFrame);

    private _squareKnob = [_display, _inner, [0, 0, _knobW, _knobH], UI_TEX(cursor_ring_ca), [1, 1, 1, 1]] call EFUNC(gui,uiIcon);
    private _hueKnob = [_display, _inner, [_pickW + _gap + (_stripW - _knobW) / 2, 0, _knobW, _knobH], UI_TEX(cursor_ring_ca), [1, 1, 1, 1]] call EFUNC(gui,uiIcon);

    // A press on the square or the strip picks and follows the mouse until the button comes up.
    {
        _x params ["_kind", "_rect"];

        private _hit = [_display, "AIO_Hitbox", _inner, _rect] call EFUNC(gui,uiCreate);

        _hit setVariable [QGVAR(pickKind), _kind];
        _hit ctrlAddEventHandler ["MouseButtonDown", {
            params ["_ctrl", "_button"];

            if (_button != 0) exitWith {};

            ["begin", _ctrl] call FUNC(colourPickerSlide);
        }];
    } forEach [["square", _squareRect], ["hue", _stripRect]];

    // The colour as it is, and its hex digits.
    private _rowY = _pickH + UNIT * 0.35;
    private _swatchW = SQUARE(_rowH);

    [_display, _inner, [0, _rowY, _swatchW, _rowH], [1, 1, 1, 0.25], _radius] call EFUNC(gui,uiPanel);

    private _preview = [_display, _inner, [pixelW, _rowY + pixelH, _swatchW - pixelW * 2, _rowH - pixelH * 2], [0, 0, 0, 1], 0] call EFUNC(gui,uiPanel);

    private _edit = [_display, _inner, [_swatchW + _gap, _rowY, _width - _swatchW - _gap, _rowH], "", LLSTRING(Categories_ColourShort), _theme, {
        params ["_text", "_submitted"];

        if (!_submitted) exitWith {};

        private _state = uiNamespace getVariable [QGVAR(colourPick), createHashMap];
        private _rgb = [_text] call (_state get "fnc_rgb");

        if (_rgb isEqualTo []) exitWith {
            [LLSTRING(Categories_BadColour), "loss"] call FUNC(setHint);
        };

        _state set ["hsv", ["hsv", _rgb] call EFUNC(gui,hsv)];
        ["show"] call FUNC(colourPickerSlide);
    }] call FUNC(uiEdit);

    // Default and Apply.
    _rowY = _rowY + _rowH + UNIT * 0.35;

    private _font = _theme getOrDefault ["font", "PuristaMedium"];
    private _applyLabel = LLSTRING(Colour_Apply);
    private _applyW = ACTION_W(_applyLabel,_rowH,true,_font);

    [_display, _inner, [0, _rowY, _width - _applyW - _gap, _rowH], LLSTRING(Colour_Default), "", _theme, {
        private _state = uiNamespace getVariable [QGVAR(colourPick), createHashMap];

        call FUNC(closePopover);
        ["", _state get "arguments"] call (_state get "code");
    }, [], true, "ghost", LLSTRING(Colour_DefaultTip)] call FUNC(uiAction);

    [_display, _inner, [_width - _applyW, _rowY, _applyW, _rowH], _applyLabel, UI_TEX(icon_style_ca), _theme, {
        private _state = uiNamespace getVariable [QGVAR(colourPick), createHashMap];
        private _rgb = ["rgb", _state get "hsv"] call EFUNC(gui,hsv);

        call FUNC(closePopover);
        [(([_rgb] call FUNC(hex)) select [1]), _state get "arguments"] call (_state get "code");
    }, [], true, "accent"] call FUNC(uiAction);

    _state set ["controls", createHashMapFromArray [
        ["base", _base], ["squareKnob", _squareKnob], ["hueKnob", _hueKnob], ["preview", _preview select 0], ["edit", _edit select (count _edit - 1)]
    ]];
    _state set ["geometry", [_pickW, _pickH, _stripW, _gap, _knobW, _knobH]];

    ["show"] call FUNC(colourPickerSlide);
}, [_pickW, _pickH, _stripW, _gap, _rowH, _width], [], "colour"] call FUNC(popover);
