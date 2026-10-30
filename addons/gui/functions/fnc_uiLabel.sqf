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
 * "window", "title" (a column's), "section" (or true), "caption", "tab", "name", "weapon", "stack", "ammo", "key", "weight",
 * "value", "hover", "hint" (or false, the default), "button", "keyhint", "menu" or "never" (a line written to later). Window, titles,
 * sections, captions and tabs show it in the wizard too, the rest only on the inventory's own window and never in a layer marked
 * plain (the colour and sound panels). Where it cannot run - a count, one letter, ink on a lit surface - the line takes one colour
 * of it (see below).
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
    case (_title isEqualType true): {["hint", "section"] select _title};
    default {["never", "title", "section", "hint"] select (((_title + 1) max 0) min 3)};
};

// The window's titles, sections, captions and tabs take the titles' colour, and show the gradient in the setup wizard too.
// Everything else only on the inventory's own window, and never in a layer that asks for plain words (the colour and sound
// panels, QGVAR(plain)): their buttons and rows are settings, not the inventory.
_title = _part in ["window", "title", "section", "heading", "caption", "tab"];

private _bit = (createHashMapFromArray [
    ["window", GRADIENT_WINDOW], ["title", GRADIENT_COLUMNS], ["section", GRADIENT_SECTIONS], ["heading", GRADIENT_CAPTIONS],
    ["caption", GRADIENT_CAPTIONS], ["tab", GRADIENT_TABS], ["name", GRADIENT_NAMES], ["weapon", GRADIENT_WEAPONS],
    ["stack", GRADIENT_STACKS], ["ammo", GRADIENT_AMMO], ["count", GRADIENT_AMMO], ["weaponammo", GRADIENT_WEAPONAMMO], ["key", GRADIENT_KEYS],
    ["weight", GRADIENT_WEIGHT], ["value", GRADIENT_VALUES], ["hover", GRADIENT_HOVER], ["hint", GRADIENT_NOTES],
    ["text", GRADIENT_NOTES], ["button", GRADIENT_BUTTONS], ["keyhint", GRADIENT_KEYHINTS], ["menu", GRADIENT_MENUS]
]) getOrDefault [_part, 0];

if (!isNull _parent && {_parent getVariable [QGVAR(plain), false]}) then {
    _bit = 0;
};

private _ownStart = [];
private _graded = _bit > 0 && {count _gradient >= 3} && {((floor ((_theme getOrDefault ["gradientParts", GRADIENT_PARTS_DEFAULT]) / _bit)) mod 2) == 1} && {
    _title || {_part isEqualTo "hover"} || {_display isEqualTo (uiNamespace getVariable [QGVAR(display), displayNull])}
};

// The part's own gradient where the player set one (the theme's "gradientOwn", by the part's place): its start, its end, or both.
if (_graded) then {
    private _ownPair = (_theme getOrDefault ["gradientOwn", []]) param [round (log _bit / log 2), [[], []]];

    if ((_ownPair select 1) isNotEqualTo []) then {
        _gradient = (_ownPair select 1) select [0, 3];
    };

    if ((_ownPair select 0) isNotEqualTo []) then {
        _ownStart = _ownPair select 0;
    };
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

if (_ownStart isNotEqualTo []) then {
    _start = _ownStart;
};

// Where the gradient cannot run, the line takes one colour of it as a plain label: a count in its little box ("5/5", "30/30") is
// too tight for structured text, and one letter has nothing to run along - they take the start. Ink on a lit surface (a key's
// badge, a lit button: the theme's "onAccent", or dark ink) takes the end or the start, whichever reads on the accent, else its ink.
if (_graded) then {
    private _solid = [];

    if (_color isNotEqualTo []) then {
        private _onAccent = (_theme getOrDefault ["onAccent", []]) select [0, 3];
        private _light = (_color select 0) * 0.2126 + (_color select 1) * 0.7152 + (_color select 2) * 0.0722;

        // On the lit surface the end or the start, whichever stands out from the accent (3 : 1 at least, the end first); where
        // neither does, the ink the theme worked out for it, with no gradient at all - a key that cannot be read is no key.
        if ((_color select [0, 3]) isEqualTo _onAccent || {_light < 0.35}) then {
            private _fnc_luma = {
                params ["_rgb"];

                (((_rgb select 0) max 0) ^ 2.2) * 0.2126 + (((_rgb select 1) max 0) ^ 2.2) * 0.7152 + (((_rgb select 2) max 0) ^ 2.2) * 0.0722
            };

            private _under = [(_theme getOrDefault ["accent", [1, 1, 1, 1]]) select [0, 3]] call _fnc_luma;
            private _readable = [_gradient select [0, 3], _start select [0, 3]] select {
                private _luma = [_x] call _fnc_luma;

                ((_luma max _under) + 0.05) / ((_luma min _under) + 0.05) >= 3
            };

            _solid = _readable param [0, _color select [0, 3]];
        };
    };

    if (_solid isEqualTo [] && {_part in ["stack", "ammo", "count", "weaponammo"] || {_text isEqualType "" && {count _text < 2}}}) then {
        _solid = _start select [0, 3];
    };

    if (_solid isNotEqualTo []) then {
        _graded = false;
        _color = _solid + [[1, _color param [3, 1]] select (count _color >= 4)];
    };
};

if (_graded && {_text isEqualType ""} && {_text isNotEqualTo ""}) exitWith {
    _color = (_start select [0, 3]) + [[1, _color param [3, 1]] select (count _color >= 4)];

    // Structured text is drawn from the top of its control: the line is set where a label centres it, its top half the free
    // height down - as high as the font, not a bit more, or the words sit higher than a label's would. A letter of its own
    // in each colour loses the font's kerning, so the line runs a little wider than a label's: the box gets that room on the
    // side the text grows to, and nothing is cut.
    _rect params ["_left", "_top", "_width", "_height"];

    private _extra = _width * 0.25;
    private _boxLeft = [_left, _left - _extra, _left - _extra / 2] select ((_align max 0) min 2);
    private _ctrl = [_display, "EINV_StructuredText", _parent, [_boxLeft, _top + (_height - _size) / 2, _width + _extra, _size * 1.3]] call FUNC(uiCreate);

    _ctrl ctrlSetStructuredText ([_text, _font, _size, _align, _color, _gradient] call FUNC(gradientText));

    // Structured text takes the mouse and the focus, where a label does neither: over a button or a fold tab it kept their
    // tips from showing until a click, and focused, its column was drawn over the name at the mouse. Off, it is words only.
    _ctrl ctrlEnable false;

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
