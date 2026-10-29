#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Creates a line of text. Font, size and colour are set here rather than in the class, because the
 * style decides them.
 *
 * A title (argument 8) takes the palette's titles colour where the player chose one (the theme's "titleColor"), and with the titles'
 * gradient on runs from it (or the accent) into the gradient's colour, letter by letter from left to right, as Discord's gradient
 * names do (fnc_gradientText). That line is structured text, set once: a later ctrlSetText does not reach it.
 * Where the gradient shows is the player's (the theme's "gradientParts", fnc_theme, GRADIENT_*): argument 8 says what the line is -
 * "title", "heading" (or true), "name", "count", "button", "text" (or false, the default), "hover" or "never" (a line written to
 * later). Anything but titles and headings only on the inventory's own window, never in the wizard.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group to create it in, or controlNull for the display <CONTROL>
 * 2: Position [x, y, w, h] <ARRAY>
 * 3: Text <STRING>
 * 4: Font size, as a height <NUMBER>
 * 5: Colour, [] for the class's own <ARRAY>
 * 6: Font, "" for the class's own <STRING>
 * 7: Alignment - 0 left, 1 right, 2 centre <NUMBER> (default: 0)
 * 8: What the line is, for the gradient (see above) <STRING, BOOL> (default: false)
 *
 * Return Value:
 * The label <CONTROL>
 *
 * Example:
 * [_display, controlNull, [0.1, 0.1, 0.2, 0.03], "Vest", 0.025, [1, 1, 1, 1], "PuristaSemibold", 0] call einv_gui_fnc_uiLabel;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_parent", "_rect", "_text", "_size", ["_color", []], ["_font", ""], ["_align", 0], ["_title", false]];

private _theme = missionNamespace getVariable [QGVAR(theme), createHashMap];
private _gradient = _theme getOrDefault ["titleGradient", []];

// What the line is: a word for it, or the older numbers and the title flag.
private _part = switch (true) do {
    case (_title isEqualType ""): {_title};
    case (_title isEqualType true): {["text", "heading"] select _title};
    default {["never", "title", "heading", "text"] select (((_title + 1) max 0) min 3)};
};

// Titles and headings take the titles' colour; the gradient shows where the player switched it on (GRADIENT_*). Anything but a
// title or heading only on the inventory's own window, never in the wizard.
_title = _part in ["title", "heading"];

private _bit = (createHashMapFromArray [
    ["title", GRADIENT_TITLES], ["heading", GRADIENT_HEADINGS], ["name", GRADIENT_NAMES], ["count", GRADIENT_COUNTS],
    ["button", GRADIENT_BUTTONS], ["text", GRADIENT_TEXT], ["hover", GRADIENT_HOVER]
]) getOrDefault [_part, 0];

private _graded = _bit > 0 && {count _gradient >= 3} && {((floor ((_theme getOrDefault ["gradientParts", GRADIENT_PARTS_DEFAULT]) / _bit)) mod 2) == 1} && {
    _title || {_part isEqualTo "hover"} || {_display isEqualTo (uiNamespace getVariable [QGVAR(display), displayNull])}
};

if (_title) then {
    private _own = _theme getOrDefault ["titleColor", []];

    if (count _own >= 3) then {
        _color = (_own select [0, 3]) + [[1, _color param [3, 1]] select (count _color >= 4)];
    };
};

// The gradient's start: the titles' colour, else the accent, at the strength the label would have.
private _start = _theme getOrDefault ["titleColor", []];

if (count _start < 3) then {
    _start = _theme getOrDefault ["accent", [1, 1, 1, 1]];
};

// A count in its little box ("5/5", "30/30") is too short for a gradient and too tight for structured text: it takes the
// gradient's start colour as a plain label.
if (_graded && {_part isEqualTo "count"}) then {
    _graded = false;
    _color = (_start select [0, 3]) + [[1, _color param [3, 1]] select (count _color >= 4)];
};

if (_graded && {_text isEqualType ""} && {_text isNotEqualTo ""}) exitWith {
    _color = (_start select [0, 3]) + [[1, _color param [3, 1]] select (count _color >= 4)];

    // Structured text is drawn from the top of its control: the line is set where a label would centre it. A letter of its own
    // in each colour loses the font's kerning, so the line runs a little wider than a label's: the box gets that room on the
    // side the text grows to, and nothing is cut.
    _rect params ["_left", "_top", "_width", "_height"];

    private _extra = _width * 0.25;
    private _boxLeft = [_left, _left - _extra, _left - _extra / 2] select ((_align max 0) min 2);
    private _ctrl = [_display, "EINV_StructuredText", _parent, [_boxLeft, _top + (_height - _size * 1.15) / 2, _width + _extra, _size * 1.3]] call FUNC(uiCreate);

    _ctrl ctrlSetStructuredText ([_text, _font, _size, _align, _color, _gradient] call FUNC(gradientText));

    _ctrl
};

private _class = ["EINV_Label", "EINV_LabelRight", "EINV_LabelCenter"] select ((_align max 0) min 2);
private _ctrl = [_display, _class, _parent, _rect] call FUNC(uiCreate);

if (_font isNotEqualTo "") then {
    _ctrl ctrlSetFont _font;
};

_ctrl ctrlSetFontHeight _size;

if (_color isNotEqualTo []) then {
    _ctrl ctrlSetTextColor _color;
};

_ctrl ctrlSetText _text;

_ctrl
