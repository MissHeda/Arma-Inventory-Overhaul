#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Draws the comparison card (fnc_compareRows) that stands in for the name at the mouse when the mouse rests
 * on a vest, uniform, helmet or backpack: the name, what it is compared with, and a row each of armor,
 * the zones it covers, space, load and weight, the difference in green when it helps and in red when it
 * does not.
 *
 * One controls group on the display, made on every change of what the mouse is on (fnc_updateHover) and
 * sized to its content plus two pixels - a group scrolls as soon as its content is taller than it. It is
 * made off screen: fnc_onFrame puts it beside the pointer, by the width and height kept on it, as it does the
 * name. Kept in uiNamespace (compare) and registered with the display's controls like any other, so the next
 * build sweeps it away.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: The card, as fnc_compareRows gives it <HASHMAP>
 *
 * Return Value:
 * The card <CONTROL>
 *
 * Example:
 * [_display, [player, "V_PlateCarrier2_rgr"] call aio_gui_fnc_compareRows] call aio_gui_fnc_drawCompare;
 *
 * Public: No
 */

disableSerialization;

params ["_display", ["_compare", createHashMap, [createHashMap]]];

private _theme = GVAR(theme);
private _font = _theme getOrDefault ["font", "PuristaMedium"];
private _fontBold = _theme getOrDefault ["fontBold", "PuristaSemibold"];
private _colorText = _theme getOrDefault ["text", [1, 1, 1, 1]];
private _muted = _theme getOrDefault ["muted", [0.56, 0.56, 0.56, 1]];

// The card and its words grow with the tiles (TEXT_UNIT, fnc_textScale).
private _textUnit = TEXT_UNIT;
private _padX = SQUARE(_textUnit * 0.2);
private _padY = _textUnit * 0.25;
private _nameSize = _textUnit * 0.58;
private _smallSize = _textUnit * 0.5;
private _nameH = _textUnit * 0.8;
private _versusH = _textUnit * 0.62;

private _name = _compare getOrDefault ["name", ""];
private _rows = _compare getOrDefault ["rows", []];

// As wide as the standard card, or the name when that is longer.
private _width = (COMPARE_W * TEXT_SCALE) max (((_name getTextWidth [_fontBold, _nameSize]) * TEXT_SLACK) + _padX * 2);
private _valueX = _padX + COMPARE_LABEL_W;
private _diffX = _width - _padX - COMPARE_DIFF_W;
private _valueW = (_diffX - _valueX) max COMPARE_VALUE_W;

// Each row is one line, a list of zones as many as it takes.
private _heights = _rows apply {
    private _plain = _x param [5, ""];
    private _lines = (ceil (((_plain getTextWidth [_font, _smallSize]) * TEXT_SLACK) / _valueW)) max 1 min 3;

    _lines * COMPARE_ROW_H
};

private _height = _padY * 2 + _nameH + _versusH;

{
    _height = _height + _x;
} forEach _heights;

private _group = [_display, "AIO_Group", controlNull, [-10, -10, _width + pixelW * 2, _height + pixelH * 2]] call FUNC(uiCreate);

// The glass of the tooltip.
[_display, _group, [0, 0, _width, _height], _theme getOrDefault ["tooltipBg", [0.03, 0.03, 0.03, 0.96]], (_theme getOrDefault ["radius", 0]) * 0.5] call FUNC(uiPanel);

private _cursor = _padY;

[_display, _group, [_padX, _cursor, _width - _padX * 2, _nameH], _name, _nameSize, _colorText, _fontBold, 0, "hover"] call FUNC(uiLabel);
_cursor = _cursor + _nameH;

[_display, _group, [_padX, _cursor, _width - _padX * 2, _versusH], _compare getOrDefault ["versus", ""], _smallSize, _muted, _font, 0, "hint"] call FUNC(uiLabel);
_cursor = _cursor + _versusH;

{
    _x params ["_label", "_value", "_diff", "_diffKey", ["_structured", false], ""];

    private _rowH = _heights select _forEachIndex;

    [_display, _group, [_padX, _cursor, COMPARE_LABEL_W, _rowH], _label, _smallSize, _muted, _font, 0, "hint"] call FUNC(uiLabel);

    if (_structured) then {
        // Structured text sizes itself against its control's own: the card's rows are 0.5 where the class says 0.7.
        private _text = [_display, "AIO_StructuredText", _group, [_valueX, _cursor, _valueW, _rowH]] call FUNC(uiCreate);

        _text ctrlSetStructuredText (_value setAttributes ["size", str (_smallSize / (UNIT * 0.7)), "font", _font]);
    } else {
        [_display, _group, [_valueX, _cursor, _valueW, _rowH], _value, _smallSize, _colorText, _font, 0, "value"] call FUNC(uiLabel);
    };

    if (_diff isNotEqualTo "") then {
        [
            _display, _group, [_diffX, _cursor, COMPARE_DIFF_W, _rowH], _diff, _smallSize,
            _theme getOrDefault [_diffKey, _muted], _fontBold, 1, "value"
        ] call FUNC(uiLabel);
    };

    _cursor = _cursor + _rowH;
} forEach _rows;

_group setVariable [QGVAR(width), _width];
_group setVariable [QGVAR(height), _height];

// What it was made from, to make it again over something made after it (fnc_raiseTooltip).
_group setVariable [QGVAR(source), _compare];

uiNamespace setVariable [QGVAR(compare), _group];

_group
