#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Opens the palette popover under the palette button in the header: a small card where the player picks the window's colours
 * and transparency, live. Top to bottom:
 *   Style         a dropdown of ready-made looks (fnc_paletteStyles: Classic, Modern, Modern gradient, Tactical, Night, Neon); it
 *                 says "Custom" once a row was changed by hand. Its list opens under it, a swatch strip of each style beside its name.
 *   Accent        "Use my Arma colour" goes back to the colour of Options > Game > Colors
 *   Titles        the colour of the titles (the window's, the columns', the headings, the name at the mouse, the cards' names), with
 *                 a gradient as Discord's gradient names: two colours, left to right (fnc_uiLabel, fnc_gradientText)
 *   Secondary     "Match accent" goes back to the themes' own films (caption tabs, buttons, bar tracks, picked rows); its transparency
 *   Panels        the window's background, kept dark so the text stays readable, with its transparency and a gradient
 *                 (fnc_panelGradient)
 *   Empty cells   the empty grid cells and the slot boxes, kept dark, with their transparency
 *   Item tiles    their transparency only: their colours are the setup's, by category (Categories card, fnc_tileColour)
 *   Text          captions, names and labels with their dimmer shades
 *   Lines         the hairlines and a frame round the panels, the slot boxes and the tiles, with their transparency
 * Every row is folded to one line - name, swatch, its button back to the default - and opens on a click: its picker and its slider
 * under it, one row open at a time. Folding it (a click on the open row) hides all of it, the slider too. A row that can run as a
 * gradient (Titles, Panels) shows a Gradient switch when open, and with it on two colour boxes, Start and End: a click on one binds
 * the picker to it (uiNamespace einv_gui_paletteEnd). Its folded swatch shows both halves. "Reset all" in the title
 * row takes every choice away. The buttons show only while there is a choice to take away.
 *
 * The picker is the kind that painting programs have: a colour square (the saturation across, the value down; a pure-hue rectangle
 * with a white fade and a black fade over it, fnc_paletteSet "square"), a strip of hues beside it, and fields for red, green and
 * blue (0 to 255) and the hex code, which take what is typed (read when the cursor leaves the field - Return does that). A round
 * cursor marks the colour in the square and on the strip. Where nothing is chosen the picker stands at the colour the window wears
 * now (fnc_paletteInfo). Every move goes to fnc_paletteSet (fnc_paletteSlide drags the pickers and the sliders), which updates this
 * card in place (fnc_updatePaletteMenu) and builds the window again. The squares of the panels and the cells show only the values
 * up to PALETTE_PANEL_VALUE_MAX: a black film over them, so what they show is what is chosen.
 *
 * Which row is open is kept in uiNamespace einv_gui_paletteOpen (its id, "" none), and its colour's number in einv_gui_paletteTab
 * (-1 for none, fnc_closeMenu keeps a field being typed in by it); whether the style list is open in einv_gui_paletteStylesOpen.
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

// The rows, top to bottom: id (what its button takes away, fnc_paletteSet "reset"), the colour's number (PALETTE_IDS; -1 for a row
// with no colour of its own), name, what it sets (the name's tooltip), the button's words, its sliders [[kind, words], ...]
// (fnc_paletteSlide, fnc_paletteSet), a note under them ("" for none) and the colour its gradient runs into (-1 for none).
private _transparency = LLSTRING(Palette_Transparency);
private _rowDefs = [
    ["titles", 8, LLSTRING(Palette_Titles), LLSTRING(Palette_Titles_Tip), LLSTRING(Palette_Default), [], "", 7],
    ["text", 5, LLSTRING(Palette_Text), LLSTRING(Palette_Text_Tip), LLSTRING(Palette_Default), [], "", -1],
    ["accent", 0, LLSTRING(Palette_Accent), LLSTRING(Palette_Accent_Tip), LLSTRING(Palette_UseArma), [], "", -1],
    ["secondary", 1, LLSTRING(Palette_Secondary), LLSTRING(Palette_Secondary_Tip), LLSTRING(Palette_MatchAccent), [["secondaryAlpha", _transparency]], "", -1],
    ["panel", 2, LLSTRING(Palette_Panels), LLSTRING(Palette_Panels_Tip), LLSTRING(Palette_Default), [["alpha", _transparency]], "", 9],
    ["cells", 3, LLSTRING(Palette_Cells), LLSTRING(Palette_Cells_Tip), LLSTRING(Palette_Default), [["cellAlpha", _transparency]], "", -1],
    ["items", -1, LLSTRING(Palette_Tiles), LLSTRING(Palette_Tiles_Tip), LLSTRING(Palette_Default), [["tileAlpha", _transparency]], LLSTRING(Palette_TilesNote), -1],
    ["lines", 6, LLSTRING(Palette_Lines), LLSTRING(Palette_Lines_Tip), LLSTRING(Palette_Default), [["linesAlpha", _transparency]], "", -1]
];

// The rows come in three sections, each with a heading over its first row: the words and their gradient first - what the
// palette shows off -, then the colours that tint the controls, then the surfaces under everything.
private _sectionHeads = createHashMapFromArray [
    ["titles", LLSTRING(Palette_Section_Text)], ["accent", LLSTRING(Palette_Section_Colours)], ["panel", LLSTRING(Palette_Section_Surfaces)]
];

// Which row is open ("" none), and so which colour the picker is bound to.
private _open = uiNamespace getVariable [QGVAR(paletteOpen), ""];

if (!(_open isEqualType "") || {(_rowDefs findIf {(_x select 0) isEqualTo _open}) < 0}) then {
    _open = "";
};

private _openDef = _rowDefs param [_rowDefs findIf {(_x select 0) isEqualTo _open}, []];
private _info = [] call FUNC(paletteInfo);

// A row's gradient is on while its end colour is chosen.
private _fnc_gradientOn = {
    params ["_end"];

    _end >= 0 && {(_info get "set") select _end}
};

// The picker is bound to the open row's colour - or, with its gradient on and End picked, to the end's.
private _openEnd = _openDef param [7, -1];
private _pickEnd = ([_openEnd] call _fnc_gradientOn) && {uiNamespace getVariable [QGVAR(paletteEnd), false]};
private _tab = [_openDef param [1, -1], _openEnd] select _pickEnd;

// A part of the gradient picked for colours of its own (its pill in the Text row's checkboxes): the picker is bound to its start or end
// (PALETTE_COLOURS + part * 2, + 1 for the end), and the main Start and End are not outlined.
private _partPick = uiNamespace getVariable [QGVAR(palettePart), -1];

if !(_open isEqualTo "text" && {_partPick isEqualType 0} && {_partPick >= 0} && {_partPick < GRADIENT_PART_COUNT}) then {
    _partPick = -1;
};

// A part with no gradient has no end: its one colour is its start.
if (_partPick >= 0) then {
    private _partRuns = ((floor ((GVAR(theme) getOrDefault ["gradientParts", GRADIENT_PARTS_DEFAULT]) / (2 ^ _partPick))) mod 2) == 1;

    _tab = PALETTE_COLOURS + _partPick * 2 + parseNumber (_partRuns && {uiNamespace getVariable [QGVAR(paletteEnd), false]});
};

uiNamespace setVariable [QGVAR(paletteTab), _tab];

// The style list, open under the Style row or not, and the styles.
private _stylesOpen = uiNamespace getVariable [QGVAR(paletteStylesOpen), false];

// The Import or Export line under the title, or neither ("").
private _io = uiNamespace getVariable [QGVAR(paletteIO), ""];
private _styles = [] call FUNC(paletteStyles);

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
private _sectionH = UNIT * 0.72;
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

// The title, the Style row (and its list), every row folded, and what the open row shows: its picker, its sliders, its note.
private _height = _padY * 2 + _titleH + (_gapY + _headH) + (count _rowDefs) * (_gapY + _headH) + (count _sectionHeads) * (_gapY + _sectionH);

// The hint line at the bottom: the tip of what the mouse is on, inside the panel (a tip floating over it would lie under the
// panel, which is drawn over everything while it holds the focus). As many lines as the longest tip the panel has wraps to -
// two cut the Titles row's tip off in the middle of a sentence.
private _hintSize = _small * 0.9;
private _hintW = _width - _padX * 2;
private _hintLines = 2;

{
    private _words = _x;
    private _lines = 0;

    {
        _lines = _lines + ((ceil (((_x getTextWidth [_font, _hintSize]) * TEXT_SLACK) / (_hintW max pixelW))) max 1);
    } forEach (_words splitString toString [10]);

    _hintLines = _hintLines max _lines;
} forEach ((_rowDefs apply {_x select 3}) + [
    LLSTRING(Palette_Style_Tip), LLSTRING(Palette_Gradient_Tip), LLSTRING(Palette_PartGradient_Tip), LLSTRING(Palette_PartColours_Tip),
    LLSTRING(Palette_PartMain_Tip), LLSTRING(Palette_PartPick), LLSTRING(Palette_Export_Tip), LLSTRING(Palette_Import_Tip),
    LLSTRING(Palette_Channel_Tip), LLSTRING(Palette_Hex_Tip)
]);

private _hintH = _hintSize * 1.3 * (_hintLines min 5) + _hintSize * 0.4;

_height = _height + _gapY + _hintH;

if (_io isNotEqualTo "") then {
    _height = _height + _gapY + _rowH;
};

if (_stylesOpen) then {
    _height = _height + _pickPad * 2 + (count _styles) * _rowH;
};

if (_openDef isNotEqualTo []) then {
    _openDef params ["", "_openWhich", "", "", "", "_openSliders", "_openNote", "_openGradient"];

    // The Gradient line: its switch, and Start and End.
    if (_openGradient >= 0) then {
        _height = _height + _rowH + _gapY;

    };

    // The Text row: where the gradient shows - a group of checkboxes two to a row, a little gap between groups.
    if ((_openDef select 0) isEqualTo "text") then {
        {
            _height = _height + _rowH * ceil ((count (_x select 1)) / 2);
        } forEach GRADIENT_PART_GROUPS;

        _height = _height + _gapY + _gapY * 0.5 * (count GRADIENT_PART_GROUPS - 1);

        // The line of the part picked for colours of its own.
        if (_partPick >= 0) then {
            _height = _height + _gapY + _rowH;
        };
    };

    if (_openWhich >= 0) then {
        _height = _height + _pickPad * 2 + _pickH;
    };

    _height = _height + (count _openSliders) * _rowH + ([0, _rowH] select (_openNote isNotEqualTo "")) + ([0, _pickPad] select (_openWhich < 0));
};

// Left to right in a row: padding, arrow, name, swatch, then the button at the right edge.
private _arrowH = UNIT * 0.5;
private _arrowW = SQUARE(_arrowH);
private _nameX = _padX + _arrowW + SQUARE(UNIT * 0.3);
private _nameW = SQUARE(UNIT * 4.8);
private _swatchH = UNIT * 0.7;
private _swatchW = SQUARE(UNIT * 1.4);
private _swatchX = _nameX + _nameW;
private _chipH = UNIT * 0.8;
private _chipSize = UNIT * 0.44;

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

// The right edge of the window - the header's, where the Close button ends - and a small gap under the header's line, kept on the screen.
private _left = ((CONTENT_X + CONTENT_W - _width) min (safezoneX + safezoneW - _width)) max safezoneX;
private _top = ((HEAD_Y + HEAD_H + UNIT * 0.5) max (safezoneY + UNIT * 2.6 + pixelH * 3)) min (safezoneY + safezoneH - _height);
private _cardX = _left - safezoneX;
private _cardY = _top - safezoneY;

// ----- The layer, the hit area beside the card, the card -----

private _layer = [_display, "EINV_Group", controlNull, [safezoneX, safezoneY, safezoneW, safezoneH]] call FUNC(uiCreate);

// Settings, not the inventory: no word in it takes the gradient (fnc_uiLabel).
_layer setVariable [QGVAR(plain), true];

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

// A click on the card between its controls is no click beside it: this takes it, and does nothing (the catcher above closes the
// popover only for a click beside the card).
[_display, "EINV_Hitbox", _layer, [_cardX, _cardY, _width, _height]] call FUNC(uiCreate);

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

[_display, _layer, [_cardX + _padX, _headTop, _width - _padX * 2, _titleH], LLSTRING(Palette_Title), _size, _text2, _fontBold, 0, "menu"] call FUNC(uiLabel);

private _resetAll = ["all", LLSTRING(Palette_ResetAll), _headTop, _titleH] call _fnc_chip;

// Import and Export, left of Reset all: each opens its line under the title (a click on the open one closes it).
private _ioRight = _cardX + _width - _padX - ([LLSTRING(Palette_ResetAll), "", _chipH, _chipSize, _buttonTheme] call FUNC(buttonWidth)) - _gapX;

{
    _x params ["_ioId", "_ioWords", "_ioTip"];

    private _ioW = [_ioWords, "", _chipH, _chipSize, _buttonTheme] call FUNC(buttonWidth);
    private _ioRect = [_ioRight - _ioW, _headTop + (_titleH - _chipH) / 2, _ioW, _chipH];

    if (_io isEqualTo _ioId) then {
        [_display, _layer, _ioRect, ((GVAR(theme) getOrDefault ["accent", [1, 1, 1, 1]]) select [0, 3]) + [0.45], _chipH / 2] call FUNC(uiPanel);
    };

    private _ioButton = [
        _display, _layer, _ioRect, _ioId, _ioWords, "", _buttonTheme, {
            params ["_button", "_ioId"];

            if (_button < 0) exitWith {};

            [{
                params ["_ioId"];

                private _display = uiNamespace getVariable [QGVAR(display), displayNull];

                if (isNull _display) exitWith {};

                uiNamespace setVariable [QGVAR(paletteIO), [_ioId, ""] select (_ioId isEqualTo (uiNamespace getVariable [QGVAR(paletteIO), ""]))];

                // Exported: on the clipboard as well, where the game allows it.
                if (_ioId isEqualTo "export") then {
                    copyToClipboard str GVAR(palette);
                };

                [_display] call FUNC(openPaletteMenu);
            }, [_ioId]] call FUNC(later);
        }, false, _chipSize, true
    ] call FUNC(uiButton);

    [(_ioButton param [count _ioButton - 1, controlNull]), _ioTip] call FUNC(setTooltip);

    _ioRight = _ioRight - _ioW - _gapX;
} forEach [
    ["export", LLSTRING(Palette_Export), LLSTRING(Palette_Export_Tip)],
    ["import", LLSTRING(Palette_Import), LLSTRING(Palette_Import_Tip)]
];

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
    private _valueMax = PALETTE_VALUE_MAX param [_which, 1];

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
        [_display, _layer, [_fieldsX + _fieldPadX, _rowTop, _fieldLabelW, _fieldH], _label, _fieldSize, _muted, _font, 0, "menu"] call FUNC(uiLabel);

        private _hit = [_display, "EINV_Hitbox", _layer, [_fieldsX, _rowTop, _fieldsW, _fieldH]] call FUNC(uiCreate);
        private _editX = _fieldsX + _fieldPadX + _fieldLabelW;
        private _edit = [
            _display, "EINV_Edit", _layer, [_editX, _rowTop + (_fieldH - _fieldSize * 1.4) / 2, _fieldsX + _fieldsW - _fieldPadX - _editX, _fieldSize * 1.4]
        ] call FUNC(uiCreate);

        _edit ctrlSetFont _font;
        _edit ctrlSetFontHeight _fieldSize;
        _edit ctrlSetTextColor _text;
        [_edit, _tip] call FUNC(setTooltip);
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

// ----- Style: the dropdown, and its list under it while open -----

private _y = _headTop + _titleH + _gapY;

// ----- Import or Export: the colours as text in a field, and its button -----

if (_io isNotEqualTo "") then {
    private _buttonWords = [LLSTRING(Palette_Apply), LLSTRING(Palette_Done)] select (_io isEqualTo "export");
    private _ioButtonW = [_buttonWords, "", _chipH, _chipSize, _buttonTheme] call FUNC(buttonWidth);
    private _fieldRect = [_cardX + _padX, _y, _width - _padX * 2 - _ioButtonW - _gapX, _rowH];

    [_display, _layer, _fieldRect, [1, 1, 1, 0.08], UNIT * 0.25] call FUNC(uiPanel);

    private _ioEdit = [
        _display, "EINV_Edit", _layer,
        [(_fieldRect select 0) + SQUARE(UNIT * 0.3), _y + (_rowH - _small * 1.4) / 2, (_fieldRect select 2) - SQUARE(UNIT * 0.6), _small * 1.4]
    ] call FUNC(uiCreate);

    _ioEdit ctrlSetFont _font;
    _ioEdit ctrlSetFontHeight _small;
    _ioEdit ctrlSetTextColor _text;
    _ioEdit ctrlSetText (["", str GVAR(palette)] select (_io isEqualTo "export"));

    uiNamespace setVariable [QGVAR(paletteIOEdit), _ioEdit];

    [
        _display, _layer, [_cardX + _width - _padX - _ioButtonW, _y + (_rowH - _chipH) / 2, _ioButtonW, _chipH], _io, _buttonWords, "",
        _buttonTheme, {
            params ["_button", "_ioId"];

            if (_button < 0) exitWith {};

            private _typed = ctrlText (uiNamespace getVariable [QGVAR(paletteIOEdit), controlNull]);

            [{
                params ["_ioId", "_typed"];

                private _display = uiNamespace getVariable [QGVAR(display), displayNull];

                if (isNull _display) exitWith {};

                // Apply: the pasted colours are taken; text that holds none says so and the line stays.
                if (_ioId isEqualTo "import" && {!([_typed] call FUNC(paletteImport))}) exitWith {
                    ["ImportBad"] call FUNC(flashHint);
                };

                uiNamespace setVariable [QGVAR(paletteIO), ""];

                [_display] call FUNC(openPaletteMenu);
            }, [_ioId, _typed]] call FUNC(later);
        }, false, _chipSize, true
    ] call FUNC(uiButton);

    // Export: the text is selected, so Ctrl+C copies it where the clipboard was not reached.
    if (_io isEqualTo "export") then {
        ctrlSetFocus _ioEdit;
        _ioEdit ctrlSetTextSelection [0, count ctrlText _ioEdit];
    };

    _y = _y + _rowH + _gapY;
};

[
    _display, _layer, [_cardX + _nameX, _y, _nameW, _headH], [LLSTRING(Palette_Style), _nameW, _fontBold, _size] call FUNC(fitText), _size, _text,
    _fontBold, 0, "menu"
] call FUNC(uiLabel);

// The window as it ships (PALETTE_DEFAULT) is the AIO style, whichever way it came to be.
private _styleName = [LLSTRING(Style_Custom), LLSTRING(Style_Aio)] select (GVAR(palette) isEqualTo PALETTE_DEFAULT);

{
    if ((_x select 0) isEqualTo (_info get "style")) exitWith {_styleName = _x select 1};
} forEach _styles;

private _dropX = _cardX + _swatchX;
private _dropW = _cardX + _width - _padX - _dropX;

private _drop = [
    _display, _layer, [_dropX, _y + (_headH - _chipH) / 2, _dropW, _chipH], "style", _styleName,
    [UI_TEX(icon_chevron_down_ca), UI_TEX(icon_chevron_right_ca)] select !_stylesOpen, _buttonTheme, {
        params ["_button"];

        if (_button < 0) exitWith {};

        [{
            private _display = uiNamespace getVariable [QGVAR(display), displayNull];

            if (isNull _display) exitWith {};

            uiNamespace setVariable [QGVAR(paletteStylesOpen), !(uiNamespace getVariable [QGVAR(paletteStylesOpen), false])];

            [_display] call FUNC(openPaletteMenu);
        }] call FUNC(later);
    }, false, _chipSize
] call FUNC(uiButton);

[(_drop param [count _drop - 1, controlNull]), LLSTRING(Palette_Style_Tip)] call FUNC(setTooltip);

_y = _y + _headH;

if (_stylesOpen) then {
    _y = _y + _pickPad;

    {
        _x params ["_styleId", "_name", "_values"];

        private _current = _styleId isEqualTo (_info get "style") || {_styleId isEqualTo "aio" && {GVAR(palette) isEqualTo PALETTE_DEFAULT}};
        private _rowTop = _y;

        // Flush with the popover's left edge (its title, the rows' arrows): no indent of its own.
        private _textX = _cardX + _padX;

        [_display, _layer, [_textX, _rowTop, _cardX + _width - _padX - _textX, _rowH], _name, _small, [_text2, _text] select _current, _font, 0, "menu"] call FUNC(uiLabel);

        if (_current) then {
            [
                _display, _layer, [_cardX + _width - _padX - SQUARE(_rowH * 0.6), _rowTop + _rowH * 0.2, SQUARE(_rowH * 0.6), _rowH * 0.6],
                UI_TEX(icon_check_ca), _text
            ] call FUNC(uiIcon);
        };

        private _hit = [_display, "EINV_Hitbox", _layer, [_cardX + _padX, _rowTop, _width - _padX * 2, _rowH]] call FUNC(uiCreate);

        _hit setVariable [QGVAR(id), _styleId];
        _hit ctrlAddEventHandler ["ButtonClick", {
            params ["_ctrl"];

            [{
                params ["_styleId"];

                private _display = uiNamespace getVariable [QGVAR(display), displayNull];

                if (isNull _display) exitWith {};

                uiNamespace setVariable [QGVAR(paletteStylesOpen), false];

                ["style", _styleId] call FUNC(paletteSet);

                // The same style again changes nothing and builds nothing: the list still closes.
                [_display] call FUNC(openPaletteMenu);
            }, [_ctrl getVariable [QGVAR(id), ""]]] call FUNC(later);
        }];

        _y = _y + _rowH;
    } forEach _styles;

    _y = _y + _pickPad;
};

// ----- The rows, the open one with its picker, its sliders and its note under it -----

// The swatches and the take-away buttons by row id, and the sliders' parts by their kind.
private _swatches = createHashMap;
private _chips = createHashMap;
private _picker = createHashMap;
private _sliders = createHashMap;

{
    _x params ["_id", "_which", "_name", "_tip", "_words", "_rowSliders", "_note", "_end"];

    // A section begins: its heading, in the accent of the card's own white, over a hairline.
    private _sectionHead = _sectionHeads getOrDefault [_id, ""];

    if (_sectionHead isNotEqualTo "") then {
        _y = _y + _gapY;

        [_display, _layer, [_cardX + _padX, _y, _width - _padX * 2, _sectionH], toUpperANSI _sectionHead, _small, _muted, _fontBold, 0, "never"] call FUNC(uiLabel);

        _y = _y + _sectionH;
    };

    private _isOpen = _id isEqualTo _open;
    private _gradientOn = [_end] call _fnc_gradientOn;

    _y = _y + _gapY;

    [_display, _layer, [_cardX + _padX, _y - _gapY / 2, _width - _padX * 2, pixelH], [1, 1, 1, 0.05]] call FUNC(uiPanel);

    // The arrow: down while the row is open, to the right while it is folded.
    [
        _display, _layer, [_cardX + _padX, _y + (_headH - _arrowH) / 2, _arrowW, _arrowH],
        [UI_TEX(icon_chevron_right_ca), UI_TEX(icon_chevron_down_ca)] select _isOpen, _text2
    ] call FUNC(uiIcon);

    [
        _display, _layer, [_cardX + _nameX, _y, _nameW, _headH], [_name, _nameW, _fontBold, _size] call FUNC(fitText), _size, _text,
        _fontBold, 0, "menu"
    ] call FUNC(uiLabel);

    // The swatch; what can be see-through lies over a grey, so that what shows through is seen.
    private _swatchRect = [_y] call _fnc_swatch;

    if (_rowSliders isNotEqualTo []) then {
        [_display, _layer, _swatchRect, [0.55, 0.55, 0.55, 1], UNIT * 0.2] call FUNC(uiPanel);
    };

    // With its gradient on, the swatch is both colours: the start's half and the end's.
    if (_gradientOn) then {
        ([_display, _layer, _swatchRect, UNIT * 0.2] call FUNC(uiSplitSwatch)) params ["_startCtrls", "_endCtrls"];

        _swatches set [_id, _startCtrls];
        _swatches set [_id + "End", _endCtrls];
    } else {
        _swatches set [_id, [_display, _layer, _swatchRect, [0, 0, 0, 1], UNIT * 0.2] call FUNC(uiPanel)];
    };

    _chips set [_id, [_id, _words, _y, _headH] call _fnc_chip];

    // A click on the arrow, the name or the swatch opens the row (the one open before folds), or folds it where it is open.
    private _nameHit = [_display, "EINV_Hitbox", _layer, [_cardX + _padX, _y, _swatchX + _swatchW + SQUARE(UNIT * 0.3) - _padX, _headH]] call FUNC(uiCreate);

    [_nameHit, _tip] call FUNC(setTooltip);
    _nameHit setVariable [QGVAR(id), _id];
    _nameHit ctrlAddEventHandler ["ButtonClick", {
        params ["_ctrl"];

        // The popover is made again, which deletes this very control: a frame later.
        [{
            params ["_id"];

            private _display = uiNamespace getVariable [QGVAR(display), displayNull];

            if (isNull _display) exitWith {};

            uiNamespace setVariable [QGVAR(paletteOpen), [_id, ""] select (_id isEqualTo (uiNamespace getVariable [QGVAR(paletteOpen), ""]))];
            uiNamespace setVariable [QGVAR(paletteEnd), false];

            [_display] call FUNC(openPaletteMenu);
        }, [_ctrl getVariable [QGVAR(id), ""]]] call FUNC(later);
    }];

    _y = _y + _headH;

    if (_isOpen) then {
        // The Gradient line: the switch, and with it on the two colours, the one the picker is bound to outlined.
        if (_end >= 0) then {
            _y = _y + _gapY;

            [_display, _layer, [_cardX + _padX, _y, _labelW, _rowH], LLSTRING(Palette_Gradient), _small, _text2, _font, 0, "menu"] call FUNC(uiLabel);

            private _switchW = SQUARE(UNIT * 2.2);

            private _switch = [
                _display, _layer, [_cardX + _sliderX, _y + (_rowH - _chipH) / 2, _switchW, _chipH], _id,
                [LLSTRING(Palette_Off), LLSTRING(Palette_On)] select _gradientOn, "", _buttonTheme, {
                    params ["_button", "_id"];

                    if (_button < 0) exitWith {};

                    uiNamespace setVariable [QGVAR(paletteEnd), false];

                    ["gradient", _id] call FUNC(paletteSet);
                }, false, _chipSize, true
            ] call FUNC(uiButton);

            [(_switch param [count _switch - 1, controlNull]), LLSTRING(Palette_Gradient_Tip)] call FUNC(setTooltip);

            if (_gradientOn) then {
                private _boxW = SQUARE(UNIT * 2.6);
                private _boxX = _cardX + _sliderX + _switchW + _gapX;

                {
                    _x params ["_boxId", "_words", "_isEnd"];

                    private _boxRect = [_boxX, _y + _rowH * 0.1, _boxW, _rowH * 0.8];
                    private _picked = _partPick < 0 && {_isEnd isEqualTo _pickEnd};

                    [_display, _layer, _boxRect, [[1, 1, 1, 0.22], _text] select _picked, UNIT * 0.2] call FUNC(uiPanel);
                    _swatches set [_boxId, [
                        _display, _layer, [(_boxRect select 0) + pixelW * 2, (_boxRect select 1) + pixelH * 2, (_boxRect select 2) - pixelW * 4, (_boxRect select 3) - pixelH * 4],
                        [0, 0, 0, 1], UNIT * 0.2
                    ] call FUNC(uiPanel)];

                    [_display, _layer, [_boxX + _boxW + SQUARE(UNIT * 0.15), _y, SQUARE(UNIT * 1.6), _rowH], _words, _small * 0.9, [_muted, _text] select _picked, _font, 0, "menu"] call FUNC(uiLabel);

                    private _boxHit = [_display, "EINV_Hitbox", _layer, [_boxX, _y, _boxW + SQUARE(UNIT * 1.7), _rowH]] call FUNC(uiCreate);

                    _boxHit setVariable [QGVAR(id), _isEnd];
                    _boxHit ctrlAddEventHandler ["ButtonClick", {
                        params ["_ctrl"];

                        [{
                            params ["_isEnd"];

                            private _display = uiNamespace getVariable [QGVAR(display), displayNull];

                            if (isNull _display) exitWith {};

                            uiNamespace setVariable [QGVAR(paletteEnd), _isEnd];
                            uiNamespace setVariable [QGVAR(palettePart), -1];

                            [_display] call FUNC(openPaletteMenu);
                        }, [_ctrl getVariable [QGVAR(id), false]]] call FUNC(later);
                    }];

                    _boxX = _boxX + _boxW + SQUARE(UNIT * 1.9);
                } forEach [["gradStart", LLSTRING(Palette_Start), false], ["gradEnd", LLSTRING(Palette_End), true]];
            };

            _y = _y + _rowH;

        };

        // The Text row: where the gradient shows - a checkbox for each part as CBA's settings have them, a square outline ticked
        // while the part is on (GRADIENT_*, fnc_uiLabel) - in groups, the group's name in the label column, two to a row. The box
        // and its words take the click. A part runs in its own colours where it has them, else in the Titles row's gradient.
        if (_id isEqualTo "text") then {
            _y = _y + _gapY;

            private _parts = GVAR(theme) getOrDefault ["gradientParts", GRADIENT_PARTS_DEFAULT];
            private _partsX = _cardX + _sliderX;
            private _partW = (_cardX + _width - _padX - _partsX - _gapX / 2) / 2;
            private _checkH = _rowH * 0.62;
            private _checkW = SQUARE(_checkH);
            private _edgeW = pixelW * 2;
            private _edgeH = pixelH * 2;

            {
                _x params ["_groupWords", "_groupParts"];

                if (_forEachIndex > 0) then {
                    _y = _y + _gapY * 0.5;
                };

                [_display, _layer, [_cardX + _padX, _y, _labelW, _rowH], _groupWords, _small, _text2, _font, 0] call FUNC(uiLabel);

                {
                    _x params ["_bit", "_words", "_partTip"];

                    private _cellX = _partsX + (_forEachIndex mod 2) * (_partW + _gapX / 2);
                    private _cellY = _y + floor (_forEachIndex / 2) * _rowH;
                    private _checkY = _cellY + (_rowH - _checkH) / 2;
                    private _on = ((floor (_parts / _bit)) mod 2) == 1;

                    [_display, _layer, [_cellX, _checkY, _checkW, _checkH], [_muted, _text] select _on, 0] call FUNC(uiPanel);
                    [_display, _layer, [_cellX + _edgeW, _checkY + _edgeH, _checkW - _edgeW * 2, _checkH - _edgeH * 2], [0.08, 0.08, 0.08, 1], 0] call FUNC(uiPanel);

                    // The tick is always there, shown while the part is on: a click flips it at once, before the window is built
                    // again for the change.
                    private _inset = _checkH * 0.16;
                    private _tick = [
                        _display, _layer, [_cellX + SQUARE(_inset), _checkY + _inset, _checkW - SQUARE(_inset) * 2, _checkH - _inset * 2],
                        UI_TEX(icon_check_ca), _text
                    ] call FUNC(uiIcon);

                    _tick ctrlShow _on;

                    // Its own gradient: a small pill of its start and end right beside the checkbox, outlined while it is the
                    // part the picker is bound to. A click on it picks the part (the line under the groups).
                    private _partIndex = round (log _bit / log 2);
                    private _pillW = SQUARE(_checkH * 1.6);
                    private _pillRect = [_cellX + _checkW + SQUARE(UNIT * 0.15), _checkY, _pillW, _checkH];

                    [_display, _layer, _pillRect, [[1, 1, 1, 0.22], _text] select (_partIndex == _partPick), UNIT * 0.2] call FUNC(uiPanel);

                    ([
                        _display, _layer, [(_pillRect select 0) + _edgeW, (_pillRect select 1) + _edgeH, _pillW - _edgeW * 2, _checkH - _edgeH * 2], UNIT * 0.15
                    ] call FUNC(uiSplitSwatch)) params ["_partStartCtrls", "_partEndCtrls"];

                    _swatches set [format ["part%1", _partIndex], _partStartCtrls];
                    _swatches set [format ["part%1End", _partIndex], _partEndCtrls];

                    // Each half picks its own colour for the picker: the left the start, the right the end. The half that is
                    // picked already, clicked again, lets the part go.
                    {
                        _x params ["_halfRect", "_isEnd"];

                        private _pillHit = [_display, "EINV_Hitbox", _layer, _halfRect] call FUNC(uiCreate);

                        [_pillHit, LLSTRING(Palette_PartPick)] call FUNC(setTooltip);
                        _pillHit setVariable [QGVAR(id), [_partIndex, _isEnd]];
                        _pillHit ctrlAddEventHandler ["ButtonClick", {
                            params ["_ctrl"];

                            [{
                                params ["_partIndex", "_isEnd"];

                                private _display = uiNamespace getVariable [QGVAR(display), displayNull];

                                if (isNull _display) exitWith {};

                                private _again = _partIndex == (uiNamespace getVariable [QGVAR(palettePart), -1])
                                    && {_isEnd isEqualTo (uiNamespace getVariable [QGVAR(paletteEnd), false])};

                                uiNamespace setVariable [QGVAR(palettePart), [_partIndex, -1] select _again];
                                uiNamespace setVariable [QGVAR(paletteEnd), _isEnd];

                                [_display] call FUNC(openPaletteMenu);
                            }, _ctrl getVariable [QGVAR(id), [-1, false]]] call FUNC(later);
                        }];
                    } forEach [
                        [[_pillRect select 0, _cellY, _pillW / 2, _rowH], false],
                        [[(_pillRect select 0) + _pillW / 2, _cellY, _pillW / 2, _rowH], true]
                    ];

                    private _wordsX = (_pillRect select 0) + _pillW + SQUARE(UNIT * 0.15);
                    private _wordsW = _cellX + _partW - _wordsX;

                    private _wordsLabel = [
                        _display, _layer, [_wordsX, _cellY, _wordsW, _rowH], [_words, _wordsW, _font, _small * 0.9] call FUNC(fitText),
                        _small * 0.9, [_muted, _text] select _on, _font, 0
                    ] call FUNC(uiLabel);

                    // The checkbox and the words take the click - two hit areas either side of the pill, which has its own.
                    {
                        private _partHit = [_display, "EINV_Hitbox", _layer, _x] call FUNC(uiCreate);

                        [_partHit, _partTip] call FUNC(setTooltip);
                        _partHit setVariable [QGVAR(id), _bit];
                        _partHit setVariable [QGVAR(tick), [_tick, _wordsLabel]];
                        _partHit ctrlAddEventHandler ["ButtonClick", {
                            params ["_ctrl"];

                            // Seen at once: the tick and the words flip now, the window follows when it is built again.
                            (_ctrl getVariable [QGVAR(tick), []]) params [["_tick", controlNull], ["_wordsLabel", controlNull]];

                            private _now = !ctrlShown _tick;

                            _tick ctrlShow _now;
                            _wordsLabel ctrlSetTextColor ([[0.56, 0.56, 0.56, 1], [1, 1, 1, 1]] select _now);

                            // The popover is made again, which deletes this very control: a frame later.
                            [{
                                params ["_bit"];

                                ["gradientPart", _bit] call FUNC(paletteSet);
                            }, [_ctrl getVariable [QGVAR(id), 0]]] call FUNC(later);
                        }];
                    } forEach [
                        [_cellX, _cellY, (_pillRect select 0) - _cellX, _rowH],
                        [(_pillRect select 0) + _pillW, _cellY, _cellX + _partW - (_pillRect select 0) - _pillW, _rowH]
                    ];
                } forEach _groupParts;

                _y = _y + _rowH * ceil ((count _groupParts) / 2);
            } forEach GRADIENT_PART_GROUPS;

            // The part picked for colours of its own: its name, its Start and End (the one the picker is bound to outlined) and
            // Main, which takes them back to the main gradient's.
            if (_partPick >= 0) then {
                _y = _y + _gapY;

                private _partWords = "";

                {
                    {
                        if (round (log (_x select 0) / log 2) == _partPick) exitWith {
                            _partWords = _x select 1;
                        };
                    } forEach (_x select 1);
                } forEach GRADIENT_PART_GROUPS;

                [
                    _display, _layer, [_cardX + _padX, _y, _labelW, _rowH], [_partWords, _labelW, _font, _small] call FUNC(fitText),
                    _small, _text, _font, 0
                ] call FUNC(uiLabel);

                // Whether this part runs in a gradient at all - the same as its checkbox. Off, it takes its own colour (Start) as
                // one plain colour where one is set, and End is not offered.
                private _partBit = 2 ^ _partPick;
                private _partOn = ((floor ((GVAR(theme) getOrDefault ["gradientParts", GRADIENT_PARTS_DEFAULT]) / _partBit)) mod 2) == 1;
                private _ownEnd = _partOn && {uiNamespace getVariable [QGVAR(paletteEnd), false]};
                private _switchW = SQUARE(UNIT * 2.2);
                private _partSwitch = [
                    _display, _layer, [_cardX + _sliderX, _y + (_rowH - _chipH) / 2, _switchW, _chipH], str _partBit,
                    [LLSTRING(Palette_Off), LLSTRING(Palette_On)] select _partOn, "", _buttonTheme, {
                        params ["_button", "_bitId"];

                        if (_button < 0) exitWith {};

                        uiNamespace setVariable [QGVAR(paletteEnd), false];

                        ["gradientPart", parseNumber _bitId] call FUNC(paletteSet);
                    }, false, _chipSize, true
                ] call FUNC(uiButton);

                [(_partSwitch param [count _partSwitch - 1, controlNull]), LLSTRING(Palette_PartGradient_Tip)] call FUNC(setTooltip);

                // Main shows only where the part has a colour of its own. Start and End share what is left of the line with it:
                // the boxes give way, so Main never lies over End or its word.
                private _ownSet = _info get "ownSet";
                private _mainShown = (_ownSet select (_partPick * 2)) || {_ownSet select (_partPick * 2 + 1)};
                private _mainW = SQUARE(UNIT * 1.8);
                private _boxX = _cardX + _sliderX + _switchW + _gapX;
                private _boxRoom = (_cardX + _width - _padX - ([0, _mainW + _gapX] select _mainShown)) - _boxX;
                private _boxW = (SQUARE(UNIT * 2.6) min ((_boxRoom - SQUARE(UNIT * 1.9) * 2) / 2)) max SQUARE(UNIT * 1);

                {
                    _x params ["_boxId", "_words", "_isEnd"];

                    if (_isEnd && {!_partOn}) then {continue};

                    private _boxRect = [_boxX, _y + _rowH * 0.1, _boxW, _rowH * 0.8];
                    private _picked = _isEnd isEqualTo _ownEnd;

                    [_display, _layer, _boxRect, [[1, 1, 1, 0.22], _text] select _picked, UNIT * 0.2] call FUNC(uiPanel);
                    _swatches set [_boxId, [
                        _display, _layer, [(_boxRect select 0) + pixelW * 2, (_boxRect select 1) + pixelH * 2, (_boxRect select 2) - pixelW * 4, (_boxRect select 3) - pixelH * 4],
                        [0, 0, 0, 1], UNIT * 0.2
                    ] call FUNC(uiPanel)];

                    [_display, _layer, [_boxX + _boxW + SQUARE(UNIT * 0.15), _y, SQUARE(UNIT * 1.6), _rowH], _words, _small * 0.9, [_muted, _text] select _picked, _font, 0] call FUNC(uiLabel);

                    private _boxHit = [_display, "EINV_Hitbox", _layer, [_boxX, _y, _boxW + SQUARE(UNIT * 1.7), _rowH]] call FUNC(uiCreate);

                    [_boxHit, LLSTRING(Palette_PartColours_Tip)] call FUNC(setTooltip);
                    _boxHit setVariable [QGVAR(id), _isEnd];
                    _boxHit ctrlAddEventHandler ["ButtonClick", {
                        params ["_ctrl"];

                        [{
                            params ["_isEnd"];

                            private _display = uiNamespace getVariable [QGVAR(display), displayNull];

                            if (isNull _display) exitWith {};

                            uiNamespace setVariable [QGVAR(paletteEnd), _isEnd];

                            [_display] call FUNC(openPaletteMenu);
                        }, [_ctrl getVariable [QGVAR(id), false]]] call FUNC(later);
                    }];

                    _boxX = _boxX + _boxW + SQUARE(UNIT * 1.9);
                } forEach [["partStart", [LLSTRING(Palette_PartColour), LLSTRING(Palette_Start)] select _partOn, false], ["partEnd", LLSTRING(Palette_End), true]];

                // Main: only where the part has a colour of its own.
                if (_mainShown) then {
                    private _main = [
                        _display, _layer, [_cardX + _width - _padX - _mainW, _y + (_rowH - _chipH) / 2, _mainW, _chipH], str _partPick,
                        LLSTRING(Palette_PartMain), "", _buttonTheme, {
                            params ["_button", "_partId"];

                            if (_button < 0) exitWith {};

                            ["partColours", parseNumber _partId] call FUNC(paletteSet);
                        }, false, _chipSize, true
                    ] call FUNC(uiButton);

                    [(_main param [count _main - 1, controlNull]), LLSTRING(Palette_PartMain_Tip)] call FUNC(setTooltip);
                };

                _y = _y + _rowH;
            };
        };

        if (_which >= 0) then {
            // The Text row's picker edits the part picked for colours of its own, where one is (_tab, above).
            _picker = [[[_which, _end] select (_pickEnd && {_end >= 0}), _tab] select (_id isEqualTo "text" && {_partPick >= 0}), _y + _pickPad] call _fnc_picker;
            _y = _y + _pickPad * 2 + _pickH;
        } else {
            _y = _y + _pickPad;
        };

        // Its sliders: a name, a track with its fill, a knob and its value, and the hit area that drags it.
        {
            _x params ["_kind", "_sliderLabel"];

            private _trackY = _y + (_rowH - _trackH) / 2;
            private _trackRect = [_cardX + _trackX, _trackY, _trackW, _trackH];

            [
                _display, _layer, [_cardX + _padX, _y, _labelW, _rowH], [_sliderLabel, _labelW, _font, _small] call FUNC(fitText),
                _small, _text2, _font, 0, "menu"
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
                _display, _layer, [_cardX + _width - _padX - _valueW, _y, _valueW, _rowH], "", _small * 0.9, _text2, _font, 1, "menu"
            ] call FUNC(uiLabel);

            // The hit area is the slider's whole room, a knob's width beyond the track at each end: a press near an end is that end.
            // The track's place on the screen goes with it, for the mouse's place along it (fnc_paletteSlide).
            private _hit = [_display, "EINV_Hitbox", _layer, [_cardX + _sliderX, _y, _sliderW, _rowH]] call FUNC(uiCreate);

            _hit setVariable [QGVAR(picker), [_kind, 0, [safezoneX + _cardX + _trackX, safezoneY + _trackY, _trackW, _trackH]]];

            _hit ctrlAddEventHandler ["MouseButtonDown", {
                params ["_ctrl", "_button"];

                if (_button != 0) exitWith {};

                (_ctrl getVariable [QGVAR(picker), []]) params ["_kind", "_which", "_screen"];

                ["begin", [ctrlParent _ctrl, _kind, _which, _screen]] call FUNC(paletteSlide);
            }];

            _sliders set [_kind, [[_ring, _thumb], [_cardX + _trackX, _trackY, _trackW, _trackH, _thumbW, _thumbH, _thumbTop], _value, _fill]];
            _y = _y + _rowH;
        } forEach _rowSliders;

        if (_note isNotEqualTo "") then {
            [_display, _layer, [_cardX + _padX, _y, _width - _padX * 2, _rowH], _note, _small * 0.9, _muted, _font, 0, "menu"] call FUNC(uiLabel);
            _y = _y + _rowH;
        };
    };
} forEach _rowDefs;

// ----- The hint line: what the control under the mouse does (fnc_updateHover writes it) -----

private _hintTop = _cardY + _height - _padY - _hintH;

[_display, _layer, [_cardX + _padX, _hintTop - _gapY / 2, _width - _padX * 2, pixelH], [1, 1, 1, 0.05]] call FUNC(uiPanel);

private _hintLine = [_display, "EINV_StructuredText", _layer, [_cardX + _padX, _hintTop, _hintW, _hintH]] call FUNC(uiCreate);

_hintLine ctrlEnable false;
_hintLine setVariable [QGVAR(hintSize), _hintSize];
uiNamespace setVariable [QGVAR(menuHint), _hintLine];

// The panel made again after a click: the tip shown before stays.
[_hintLine, uiNamespace getVariable [QGVAR(menuHintText), ""]] call FUNC(setMenuHint);

// The focus into the layer, so it is drawn over everything: a button no one sees, one pixel in the card's
// padding. Return and Space press nothing on it (fnc_openMenu).
private _focus = [_display, "EINV_Hitbox", _layer, [_cardX + _padX / 2, _cardY + _padY / 2, pixelW, pixelH]] call FUNC(uiCreate);
ctrlSetFocus _focus;

// Kept, so the frame can give the focus back should it leave the layer (fnc_onFrame): without it the layer sinks under the columns,
// which then take the clicks meant for the panel.
uiNamespace setVariable [QGVAR(menuFocus), [_layer, _focus]];

uiNamespace setVariable [QGVAR(menu), [_layer]];
uiNamespace setVariable [QGVAR(menuFocusBack), _back];
uiNamespace setVariable [QGVAR(menuRect), [_left, _top, _width, _height]];

// What lies in it, to show the values in place (fnc_updatePaletteMenu): the open picker's controls and places, its fields, the
// open row's sliders' knobs, places, values and fills by their kind ("alpha", "cellAlpha", "tileAlpha"), the swatches and the
// buttons by row id, and Reset all.
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
