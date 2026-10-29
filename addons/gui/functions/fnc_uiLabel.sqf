#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Creates a line of text. Font, size and colour are set here rather than in the class, because the
 * style decides them.
 *
 * A text in the accent's colour runs into the palette's gradient colour, letter by letter from left to right, where the player
 * chose one (the theme's "accentGradient", fnc_theme) - as Discord's gradient names do. That line is structured text, one colour
 * per letter, set once: a later ctrlSetText does not reach it.
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

params ["_display", "_parent", "_rect", "_text", "_size", ["_color", []], ["_font", ""], ["_align", 0]];

private _theme = missionNamespace getVariable [QGVAR(theme), createHashMap];
private _gradient = _theme getOrDefault ["accentGradient", []];

if (
    count _gradient >= 3 && {_text isEqualType ""} && {_text isNotEqualTo ""} && {count _color >= 3}
    && {(_color select [0, 3]) isEqualTo ((_theme getOrDefault ["accent", []]) select [0, 3])}
) exitWith {
    // Structured text is drawn from the top of its control: the line is set where a label would centre it.
    _rect params ["_left", "_top", "_width", "_height"];

    private _ctrl = [_display, "EINV_StructuredText", _parent, [_left, _top + (_height - _size * 1.15) / 2, _width, _size * 1.3]] call FUNC(uiCreate);
    private _codes = toArray _text;
    private _last = (count _codes - 1) max 1;
    private _digits = "0123456789ABCDEF";
    private _alpha = _color param [3, 1];
    private _letters = [];

    {
        private _at = _forEachIndex / _last;
        private _bytes = [0, 1, 2] apply {round (((_color select _x) + ((_gradient select _x) - (_color select _x)) * _at) * 255)};
        private _hex = (_bytes + [round (_alpha * 255)]) apply {(_digits select [floor (_x / 16), 1]) + (_digits select [_x mod 16, 1])};
        private _letter = switch (_x) do {
            case 38: {"&amp;"};
            case 60: {"&lt;"};
            case 62: {"&gt;"};
            default {toString [_x]};
        };

        _letters pushBack format ["<t color='#%1%2%3%4'>%5</t>", _hex select 3, _hex select 0, _hex select 1, _hex select 2, _letter];
    } forEach _codes;

    _ctrl ctrlSetStructuredText parseText format [
        "<t font='%1' size='%2' align='%3'>%4</t>",
        [_font, "PuristaMedium"] select (_font isEqualTo ""), _size / (UNIT * 0.7), ["left", "right", "center"] select ((_align max 0) min 2),
        _letters joinString ""
    ];

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
