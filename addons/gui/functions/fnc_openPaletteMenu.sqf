#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Opens the palette popover under the palette button in the header: a small card where the player picks the window's colours
 * and transparency, live, element by element. A row for each - its name (a tooltip says what it sets), a swatch of what is set and a
 * small button that takes the choice away - and one shared picker, open under the row it is bound to: a click on a colour's row,
 * its swatch or its arrow binds the picker to that colour and moves it under that row, a click on the row it is open under folds
 * it. Which theme key follows which row is the table at the top of fnc_theme:
 *   Accent        "Use my Arma colour" goes back to the colour of Options > Game > Colors
 *   Secondary     "Match accent" goes back to the themes' own films (caption tabs, buttons, bar tracks, picked rows)
 *   Panels        the window's background; "Default" goes back to the near-black, and the colour is kept dark so the text stays
 *                 readable (PALETTE_PANEL_VALUE_MAX, fnc_panelColour)
 *   Transparency  how see-through the panels are, 0 % up to 100 % (PALETTE_ALPHA_MIN), with its slider under the row
 *   Cells         the empty grid cells and the slot boxes, kept dark as the panels are
 *   Tiles         the item tiles' background, kept dark as the panels are
 *   Tile          how see-through the item tiles are, 0 % up to 100 %, with its slider under the row (the one after Tiles; the
 *   transparency  tiles' hints stay)
 *   Text          captions, names and labels with their dimmer shades
 *   Lines         the tint of the hairlines and borders
 * Every row but Accent and Secondary goes back with "Default", and "Reset all" in the title row takes every choice away. The
 * buttons show only while there is a choice to take away. The rows are a little lower than a header's (and the picker a little
 * smaller), so the card stays at most about 19 UNIT tall with the picker open and both sliders in - under half the screen, the whole
 * of it on the screen under the header at any size - and needs neither a scroll nor a second column.
 *
 * The picker is the kind that painting programs and Advanced Developer Tools' colour window have: a colour square (the saturation
 * across, from white to the full colour, and the value down, from the colour to black; a pure-hue rectangle with a white fade and a
 * black fade over it, fnc_paletteSet "square"), a strip of hues beside it, and fields for red, green and blue (0 to 255) and the
 * hex code, which take what is typed (read when the cursor leaves the field - Return does that - because every change builds the
 * window again). A round cursor marks the colour in the square and on the strip. Where nothing is chosen the picker stands at the
 * colour the window wears now (fnc_paletteInfo). Every move goes to fnc_paletteSet (fnc_paletteSlide drags the pickers), which
 * updates this card in place (fnc_updatePaletteMenu) and builds the window again for the colour. The panels' picker shows only the
 * values up to PALETTE_PANEL_VALUE_MAX, and so do the cells' and the tiles': a black film over the square, so what it shows is what
 * is chosen.
 *
 * Which colour the picker is bound to is kept in uiNamespace einv_gui_paletteTab (its number, 0 accent to 6 lines as PALETTE_IDS,
 * -1 none).
 *
 * The card is the sound dropdown's (fnc_openSoundMenu) in look and machinery: darker than the panels, a one-pixel border, a
 * soft shadow, neutral greys and white words whatever the palette sets - the swatches and the picker are the only colour -,
 * right-aligned to the window's right edge a small gap under the header's line; a layer over the screen in einv_gui_menu with the
 * hit area beside the card, einv_gui_menuFor "palette", closing on a click beside it, on Escape and on a click on the palette
 * button again, and then written to the profile (fnc_paletteSettle, via fnc_closeMenu).
 *
 * Unlike the dropdown it stays open while the window is built again: fnc_build asks for it to be made again at its end and
 * fnc_raiseMenu makes it again on top of a redraw. That is this function with the popover already open; it then closes the old
 * one without writing anything (einv_gui_menuRemake), a picker that is held stays held (fnc_paletteSlide) and the text that was being
 * typed in a field is put back with the cursor in it (fnc_closeMenu keeps it, einv_gui_paletteTyping).
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

// What was being typed in a field of the popover when it was made again: [colour, field, text], or [] (fnc_closeMenu).
private _typing = uiNamespace getVariable [QGVAR(paletteTyping), []];

uiNamespace setVariable [QGVAR(paletteTyping), []];

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

// Neutral greys, as the sound dropdown: the card is darker than the panels (0.05) behind it. The popover keeps these - and its own
// white and grey words - whatever the palette sets: it is the control, not part of the look being set.
private _cardColor = [0.015, 0.015, 0.015, 1];
private _borderColor = [0.27, 0.27, 0.27, 1];
private _text = [1, 1, 1, 1];
private _text2 = [0.78, 0.78, 0.78, 1];
private _muted = [0.56, 0.56, 0.56, 1];

// Which colour the picker is bound to: its number (PALETTE_IDS), -1 none.
private _tab = uiNamespace getVariable [QGVAR(paletteTab), 0];

if (!(_tab isEqualType 0) || {_tab < -1} || {_tab >= PALETTE_COLOURS}) then {
    _tab = 0;
};

// The rows, top to bottom: id (what its button takes away, fnc_paletteSet "reset"; for a transparency also the kind of its slider,
// fnc_paletteSlide), the colour's number (PALETTE_IDS; -1 for a transparency, which has a slider instead of the picker), name, what
// it sets (the name's tooltip), the button's words and, for a transparency, the word before its slider.
private _rowDefs = [
    ["accent", 0, LLSTRING(Palette_Accent), LLSTRING(Palette_Accent_Tip), LLSTRING(Palette_UseArma)],
    ["secondary", 1, LLSTRING(Palette_Secondary), LLSTRING(Palette_Secondary_Tip), LLSTRING(Palette_MatchAccent)],
    ["panel", 2, LLSTRING(Palette_Panels), LLSTRING(Palette_Panels_Tip), LLSTRING(Palette_Default)],
    ["alpha", -1, LLSTRING(Palette_Transparency), LLSTRING(Palette_Transparency_Tip), LLSTRING(Palette_Default), LLSTRING(Palette_Panels)],
    ["cells", 3, LLSTRING(Palette_Cells), LLSTRING(Palette_Cells_Tip), LLSTRING(Palette_Default)],
    ["tiles", 4, LLSTRING(Palette_Tiles), LLSTRING(Palette_Tiles_Tip), LLSTRING(Palette_Default)],
    ["tileAlpha", -1, LLSTRING(Palette_TileTransparency), LLSTRING(Palette_TileTransparency_Tip), LLSTRING(Palette_Default), LLSTRING(Palette_Tiles)],
    ["text", 5, LLSTRING(Palette_Text), LLSTRING(Palette_Text_Tip), LLSTRING(Palette_Default)],
    ["lines", 6, LLSTRING(Palette_Lines), LLSTRING(Palette_Lines_Tip), LLSTRING(Palette_Default)]
];

// The fields of a picker: the words by it, and the tip.
private _fieldDefs = [
    [LLSTRING(Palette_Red), LLSTRING(Palette_Channel_Tip)],
    [LLSTRING(Palette_Green), LLSTRING(Palette_Channel_Tip)],
    [LLSTRING(Palette_Blue), LLSTRING(Palette_Channel_Tip)],
    [LLSTRING(Palette_Hex), LLSTRING(Palette_Hex_Tip)]
];

// ----- Sizes -----

private _size = UNIT * 0.55;
private _small = UNIT * 0.5;
private _titleH = UNIT * 1.1;
private _headH = UNIT * 0.95;
private _rowH = UNIT * 0.8;
private _gapY = UNIT * 0.1;
private _padX = SQUARE(UNIT * 0.6);
private _padY = UNIT * 0.35;
private _gapX = SQUARE(UNIT * 0.45);
private _width = SQUARE(UNIT * 15.5);

// The picker under the open colour's row: the square and the strip as tall as the four fields are together.
private _pickH = UNIT * 5.4;
private _pickW = SQUARE(_pickH);
private _stripW = SQUARE(UNIT * 0.8);
private _pickGap = SQUARE(UNIT * 0.55);
private _pickPad = UNIT * 0.3;
private _knobH = UNIT * 0.8;
private _knobW = SQUARE(_knobH);
private _fieldH = UNIT * 1.2;
private _fieldSize = _fieldH * 0.48;
private _fieldPadX = SQUARE(UNIT * 0.3);
private _fieldLabelW = SQUARE(UNIT * 1.4);

// The rows, a slider under each transparency's row, and the picker under the row it is bound to.
private _height = _padY * 2 + _titleH + (count _rowDefs) * (_gapY + _headH) + (count (_rowDefs select {(_x select 1) < 0})) * _rowH;

if (_tab >= 0) then {
    _height = _height + _pickPad * 2 + _pickH;
};

// Left to right in a colour's row: padding, arrow, name, swatch, then the button at the right edge.
private _arrowH = UNIT * 0.5;
private _arrowW = SQUARE(_arrowH);
private _nameX = _padX + _arrowW + SQUARE(UNIT * 0.3);
private _nameW = SQUARE(UNIT * 4.8);
private _swatchH = UNIT * 0.7;
private _swatchW = SQUARE(UNIT * 1.4);
private _swatchX = _nameX + _nameW;
private _chipH = UNIT * 0.8;
private _chipSize = UNIT * 0.44;

// Left to right in a transparency slider's row: padding, name, gap, slider, gap, value, padding.
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
    ["muted", _muted],
    ["radius", UNIT * 0.3],
    ["upper", false]
];

// A small button that takes a choice away: its width is its words', its place the card's right padding.
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

// ----- A swatch: a light edge round the colour, so that a near-black one is seen on the card -----

private _fnc_swatch = {
    params ["_rowTop"];

    private _rect = [_cardX + _swatchX, _rowTop + (_headH - _swatchH) / 2, _swatchW, _swatchH];
    private _swatchRadius = UNIT * 0.2;

    [
        _display, _layer, [(_rect select 0) - pixelW, (_rect select 1) - pixelH, (_rect select 2) + pixelW * 2, (_rect select 3) + pixelH * 2],
        [1, 1, 1, 0.22], _swatchRadius + pixelH
    ] call FUNC(uiPanel);

    _rect
};

// ----- One colour's picker: the square, the hue strip, the fields -----

// Returns what updatePaletteMenu needs: the pure-hue rectangle behind the square, the cursors and their places, the fields.
private _fnc_picker = {
    params ["_which", "_pickTop"];

    private _squareX = _cardX + _padX;
    private _stripX = _squareX + _pickW + _pickGap;
    private _fieldsX = _stripX + _stripW + _pickGap;
    private _fieldsW = _cardX + _width - _padX - _fieldsX;

    // The square: the pure hue, white fading out over it to the right (saturation), black fading in over that downwards (value).
    private _squareRect = [_squareX, _pickTop, _pickW, _pickH];
    private _base = [_display, "EINV_PanelRect", _layer, _squareRect] call FUNC(uiCreate);

    _base ctrlSetBackgroundColor [1, 0, 0, 1];

    {
        private _fade = [_display, "EINV_PanelCorner", _layer, _squareRect] call FUNC(uiCreate);

        _fade ctrlSetText _x;
        _fade ctrlSetTextColor [1, 1, 1, 1];
    } forEach [UI_TEX(fade_strip_ca), UI_TEX(shade_strip_ca)];

    // The square of a surface under the text (the panels, the cells, the tiles) shows only the dark values it may have: a black film
    // over all of it, so that what it shows is what is chosen.
    private _valueMax = PALETTE_VALUE_MAX select _which;

    if (_valueMax < 1) then {
        [_display, _layer, _squareRect, [0, 0, 0, 1 - _valueMax]] call FUNC(uiPanel);
    };

    [_display, _layer, _squareRect, [1, 1, 1, 0.22]] call FUNC(uiFrame);

    // The strip of hues beside it.
    private _stripRect = [_stripX, _pickTop, _stripW, _pickH];
    private _strip = [_display, "EINV_PanelCorner", _layer, _stripRect] call FUNC(uiCreate);

    _strip ctrlSetText UI_TEX(hue_vstrip_ca);
    _strip ctrlSetTextColor [1, 1, 1, 1];

    [_display, _layer, _stripRect, [1, 1, 1, 0.22]] call FUNC(uiFrame);

    // The cursors: a ring, put in place by fnc_updatePaletteMenu.
    private _squareKnob = [_display, _layer, [_squareX, _pickTop, _knobW, _knobH], UI_TEX(cursor_ring_ca), [1, 1, 1, 1]] call FUNC(uiIcon);
    private _hueKnob = [_display, _layer, [_stripX, _pickTop, _knobW, _knobH], UI_TEX(cursor_ring_ca), [1, 1, 1, 1]] call FUNC(uiIcon);

    // The hit areas: a press on one starts a drag (fnc_paletteSlide), the place on the screen going with it.
    {
        _x params ["_kind", "_rect"];

        private _hit = [_display, "EINV_Hitbox", _layer, _rect] call FUNC(uiCreate);

        _hit setVariable [QGVAR(picker), [_kind, _which, [safezoneX + (_rect select 0), safezoneY + (_rect select 1), _rect select 2, _rect select 3]]];

        _hit ctrlAddEventHandler ["MouseButtonDown", {
            params ["_ctrl", "_button"];

            if (_button != 0) exitWith {};

            (_ctrl getVariable [QGVAR(picker), []]) params ["_kind", "_which", "_screen"];

            ["begin", [ctrlParent _ctrl, _kind, _which, _screen]] call FUNC(paletteSlide);
        }];
    } forEach [["square", _squareRect], ["hue", _stripRect]];

    // The fields: red, green and blue, and the hex code - a film, the letter, the field, and a hit area over the film that
    // puts the cursor in the field. What is typed counts when the cursor leaves the field (Return does that, fnc_onKeyDown).
    private _fields = [];
    private _fieldPitch = (_pickH - _fieldH) / 3;

    {
        _x params ["_label", "_tip"];

        private _index = _forEachIndex;
        private _rowTop = _pickTop + _index * _fieldPitch;

        [_display, _layer, [_fieldsX, _rowTop, _fieldsW, _fieldH], [1, 1, 1, 0.08], UNIT * 0.25] call FUNC(uiPanel);
        [_display, _layer, [_fieldsX + _fieldPadX, _rowTop, _fieldLabelW, _fieldH], _label, _fieldSize, _muted, _font, 0] call FUNC(uiLabel);

        private _hit = [_display, "EINV_Hitbox", _layer, [_fieldsX, _rowTop, _fieldsW, _fieldH]] call FUNC(uiCreate);
        private _editX = _fieldsX + _fieldPadX + _fieldLabelW;
        private _edit = [
            _display, "EINV_Edit", _layer, [_editX, _rowTop + (_fieldH - _fieldSize * 1.4) / 2, _fieldsX + _fieldsW - _fieldPadX - _editX, _fieldSize * 1.4]
        ] call FUNC(uiCreate);

        _edit ctrlSetFont _font;
        _edit ctrlSetFontHeight _fieldSize;
        _edit ctrlSetTextColor _text;
        _edit ctrlSetTooltip _tip;
        _edit setVariable [QGVAR(field), [_which, _index]];

        _hit setVariable [QGVAR(edit), _edit];
        _hit ctrlAddEventHandler ["ButtonClick", {
            ctrlSetFocus ((_this select 0) getVariable [QGVAR(edit), controlNull]);
        }];

        // The cursor left the field: what it holds is the new value. A popover that is being closed or made again hides its layer
        // first, and what was typed is dropped (or carried over, fnc_closeMenu).
        _edit ctrlAddEventHandler ["KillFocus", {
            params ["_edit"];

            private _group = ctrlParentControlsGroup _edit;

            if (isNull _group || {!ctrlShown _group}) exitWith {};

            (_edit getVariable [QGVAR(field), []]) params [["_which", -1], ["_field", 0]];

            ["field", [_which, _field, ctrlText _edit]] call FUNC(paletteSet);
        }];

        _fields pushBack _edit;
    } forEach _fieldDefs;

    createHashMapFromArray [
        ["base", _base],
        ["squareKnob", _squareKnob],
        ["squareGeo", [_squareX, _pickTop, _pickW, _pickH, _knobW, _knobH]],
        ["hueKnob", _hueKnob],
        ["hueGeo", [_stripX, _pickTop, _stripW, _pickH, _knobW, _knobH]],
        ["fields", _fields]
    ]
};

// ----- The rows, the picker under the one it is bound to, the transparency's slider under its own -----

// The swatches and the take-away buttons by row id (and a transparency's swatch, the surface over a grey, by "alpha" and "tileAlpha"),
// and the sliders' parts by their row id.
private _swatches = createHashMap;
private _chips = createHashMap;
private _picker = createHashMap;
private _sliders = createHashMap;
private _y = _headTop + _titleH;

{
    _x params ["_id", "_which", "_name", "_tip", "_words", ["_sliderLabel", ""]];

    _y = _y + _gapY;

    if (_forEachIndex > 0) then {
        [_display, _layer, [_cardX + _padX, _y - _gapY / 2, _width - _padX * 2, pixelH], [1, 1, 1, 0.05]] call FUNC(uiPanel);
    };

    [
        _display, _layer, [_cardX + _nameX, _y, _nameW, _headH], [_name, _nameW, _fontBold, _size] call FUNC(fitText), _size, _text,
        _fontBold, 0
    ] call FUNC(uiLabel);

    private _swatchRect = [_y] call _fnc_swatch;

    _chips set [_id, [_id, _words, _y, _headH] call _fnc_chip];

    if (_which >= 0) then {
        private _open = _which == _tab;

        // The arrow: down while the picker is open under this row, to the right while it is not.
        [
            _display, _layer, [_cardX + _padX, _y + (_headH - _arrowH) / 2, _arrowW, _arrowH],
            [UI_TEX(icon_chevron_right_ca), UI_TEX(icon_chevron_down_ca)] select _open, _text2
        ] call FUNC(uiIcon);

        _swatches set [_id, [_display, _layer, _swatchRect, [0, 0, 0, 1], UNIT * 0.2] call FUNC(uiPanel)];

        // A click on the arrow, the name or the swatch binds the picker to this colour (it moves here from the row it was under), or
        // folds it where it is open already.
        private _nameHit = [_display, "EINV_Hitbox", _layer, [_cardX + _padX, _y, _swatchX + _swatchW + SQUARE(UNIT * 0.3) - _padX, _headH]] call FUNC(uiCreate);

        _nameHit ctrlSetTooltip _tip;
        _nameHit setVariable [QGVAR(colour), _which];
        _nameHit ctrlAddEventHandler ["ButtonClick", {
            params ["_ctrl"];

            // The popover is made again, which deletes this very control: a frame later.
            [{
                params ["_which"];

                private _display = uiNamespace getVariable [QGVAR(display), displayNull];

                if (isNull _display) exitWith {};

                uiNamespace setVariable [QGVAR(paletteTab), [_which, -1] select (_which == (uiNamespace getVariable [QGVAR(paletteTab), 0]))];

                [_display] call FUNC(openPaletteMenu);
            }, [_ctrl getVariable [QGVAR(colour), 0]]] call FUNC(later);
        }];

        _y = _y + _headH;

        if (_open) then {
            _picker = [_which, _y + _pickPad] call _fnc_picker;
            _y = _y + _pickPad * 2 + _pickH;
        };
    } else {
        // A transparency: the surface's colour over a grey so that what shows through is seen, and its slider under the row.
        private _alphaNameHit = [_display, "EINV_Hitbox", _layer, [_cardX + _nameX, _y, _nameW, _headH]] call FUNC(uiCreate);

        _alphaNameHit ctrlSetTooltip _tip;

        [_display, _layer, _swatchRect, [0.55, 0.55, 0.55, 1], UNIT * 0.2] call FUNC(uiPanel);
        _swatches set [_id, [_display, _layer, _swatchRect, [0, 0, 0, 1], UNIT * 0.2] call FUNC(uiPanel)];

        _y = _y + _headH;

        // The slider: its name, a track with its fill, a knob and its value, and the hit area that drags it.
        private _trackY = _y + (_rowH - _trackH) / 2;
        private _trackRect = [_cardX + _trackX, _trackY, _trackW, _trackH];

        [
            _display, _layer, [_cardX + _padX, _y, _labelW, _rowH], [_sliderLabel, _labelW, _font, _small] call FUNC(fitText),
            _small, _text2, _font, 0
        ] call FUNC(uiLabel);

        [_display, _layer, _trackRect, [1, 1, 1, 0.12], _trackH / 2] call FUNC(uiPanel);

        private _fill = [_display, "EINV_PanelRect", _layer, _trackRect] call FUNC(uiCreate);

        _fill ctrlSetBackgroundColor [0.72, 0.72, 0.72, 1];

        // The knob is white on a dark ring: white alone would vanish at the white end of the track.
        private _thumbTop = _y + (_rowH - _thumbH) / 2;
        private _ring = [
            _display, _layer, [_cardX + _trackX - _thumbW / 2 - pixelW * 2, _thumbTop - pixelH * 2, _thumbW + pixelW * 4, _thumbH + pixelH * 4],
            UI_TEX(circle_ca), [0.04, 0.04, 0.04, 0.9]
        ] call FUNC(uiIcon);
        private _thumb = [
            _display, _layer, [_cardX + _trackX - _thumbW / 2, _thumbTop, _thumbW, _thumbH], UI_TEX(circle_ca), _text
        ] call FUNC(uiIcon);

        private _value = [
            _display, _layer, [_cardX + _width - _padX - _valueW, _y, _valueW, _rowH], "", _small * 0.9, _text2, _font, 1
        ] call FUNC(uiLabel);

        // The hit area is the slider's whole room, a knob's width beyond the track at each end: a press near an end is that end. The
        // track's place on the screen goes with it, for the mouse's place along it (fnc_paletteSlide).
        private _hit = [_display, "EINV_Hitbox", _layer, [_cardX + _sliderX, _y, _sliderW, _rowH]] call FUNC(uiCreate);

        _hit setVariable [QGVAR(picker), [_id, 0, [safezoneX + _cardX + _trackX, safezoneY + _trackY, _trackW, _trackH]]];

        _hit ctrlAddEventHandler ["MouseButtonDown", {
            params ["_ctrl", "_button"];

            if (_button != 0) exitWith {};

            (_ctrl getVariable [QGVAR(picker), []]) params ["_kind", "_which", "_screen"];

            ["begin", [ctrlParent _ctrl, _kind, _which, _screen]] call FUNC(paletteSlide);
        }];

        _sliders set [_id, [[_ring, _thumb], [_cardX + _trackX, _trackY, _trackW, _trackH, _thumbW, _thumbH, _thumbTop], _value, _fill]];
        _y = _y + _rowH;
    };
} forEach _rowDefs;

// The focus into the layer, so it is drawn over everything: a button no one sees, one pixel in the card's
// padding. Return and Space press nothing on it (fnc_openMenu).
private _focus = [_display, "EINV_Hitbox", _layer, [_cardX + _padX / 2, _cardY + _padY / 2, pixelW, pixelH]] call FUNC(uiCreate);
ctrlSetFocus _focus;

uiNamespace setVariable [QGVAR(menu), [_layer]];
uiNamespace setVariable [QGVAR(menuFocusBack), _back];
uiNamespace setVariable [QGVAR(menuRect), [_left, _top, _width, _height]];

// What lies in it, to show the values in place (fnc_updatePaletteMenu): the open picker's controls and places, its fields, the
// transparency sliders' knobs, places, values and fills by row id ("alpha", "tileAlpha"), the swatches and the buttons by row id (the
// colours by PALETTE_IDS, the transparencies by "alpha" and "tileAlpha"), and Reset all.
uiNamespace setVariable [QGVAR(paletteRows), createHashMapFromArray [
    ["tab", _tab],
    ["picker", _picker],
    ["fields", _picker getOrDefault ["fields", []]],
    ["sliders", _sliders],
    ["swatches", _swatches],
    ["chips", _chips],
    ["resetAll", _resetAll]
]];

// What it shows, to make it again on top (fnc_raiseMenu); who it is for, so that closing it is known (fnc_closeMenu).
GVAR(menuState) = ["palette"];
GVAR(menuFor) = ["palette", -1];

[] call FUNC(updatePaletteMenu);
[] call FUNC(updatePaletteButton);

// A field that was being typed in when the popover was made again has its text and the cursor back.
_typing params [["_typingTab", -1], ["_typingField", -1], ["_typed", ""]];

private _fieldControls = _picker getOrDefault ["fields", []];

if (_typingTab == _tab && {_typingField >= 0} && {_typingField < count _fieldControls}) then {
    private _edit = _fieldControls select _typingField;

    _edit ctrlSetText _typed;
    ctrlSetFocus _edit;
    _edit ctrlSetTextSelection [count _typed, 0];
};
