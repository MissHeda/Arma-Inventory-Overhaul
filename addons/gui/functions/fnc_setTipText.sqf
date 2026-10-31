#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Puts a name on the name at the mouse (fnc_makeTooltip) and draws it at that size: the tooltip glass with round corners (the
 * comparison card's, fnc_drawCompare) and the words on it in the middle - plain text, or while the palette's titles gradient is
 * on the letters running from the titles' colour into the gradient's (fnc_gradientText). Structured text starts at the top of its
 * box, so that box starts half a line above the middle, as the footer's hint does. The glass and the words are made anew each
 * time, the words last so they lie on the glass. The text and the size are kept on the group, so that one made again over
 * something (fnc_raiseTooltip) gets them back.
 *
 * Arguments:
 * 0: The name at the mouse <CONTROL>
 * 1: Text <STRING>
 * 2: Width <NUMBER>
 * 3: Height <NUMBER> (default: the name's line height)
 *
 * Return Value:
 * None
 *
 * Example:
 * [_tooltip, "MX 6.5 mm", 0.2] call aio_gui_fnc_setTipText;
 *
 * Public: No
 */

disableSerialization;

params ["_tooltip", ["_text", "", [""]], ["_width", 0, [0]], ["_height", -1, [0]]];

if (_height <= 0) then {
    _height = TEXT_UNIT * 0.85;
};

_tooltip setVariable [QGVAR(tipText), _text];
_tooltip setVariable [QGVAR(width), _width];
_tooltip setVariable [QGVAR(height), _height];

{ctrlDelete _x} forEach (_tooltip getVariable [QGVAR(tipParts), []]);

private _display = ctrlParent _tooltip;
private _theme = missionNamespace getVariable [QGVAR(theme), createHashMap];
private _font = _theme getOrDefault ["font", "PuristaMedium"];
private _size = TEXT_UNIT * 0.58;

private _parts = [
    _display, _tooltip, [0, 0, _width, _height], _theme getOrDefault ["tooltipBg", [0.03, 0.03, 0.03, 0.96]],
    (_theme getOrDefault ["radius", 0]) * 0.5
] call FUNC(uiPanel);

private _lines = round ((_height - TEXT_UNIT * 0.85) / (TEXT_UNIT * 0.62)) + 1;

if (_tooltip getVariable [QGVAR(gradient), false] || {_lines > 1}) then {
    // In the gradient, or one colour (from and to the same) where only structured text breaks the lines.
    private _plainColor = (_theme getOrDefault ["text", [1, 1, 1, 1]]) select [0, 3];
    private _from = _plainColor;
    private _to = _plainColor;

    if (_tooltip getVariable [QGVAR(gradient), false]) then {
        _from = (_theme getOrDefault ["titleColor", []]) select [0, 3];

        if (count _from < 3) then {
            _from = (_theme getOrDefault ["accent", [1, 1, 1, 1]]) select [0, 3];
        };

        _to = _theme getOrDefault ["titleGradient", [1, 1, 1]];

        // The tooltips' own gradient, where the player set one.
        private _ownPair = (_theme getOrDefault ["gradientOwn", []]) param [round (log GRADIENT_HOVER / log 2), [[], []]];

        if ((_ownPair select 0) isNotEqualTo []) then {
            _from = (_ownPair select 0) select [0, 3];
        };

        if ((_ownPair select 1) isNotEqualTo []) then {
            _to = _ownPair select 1;
        };
    };

    // One line runs across the whole glass, centred, and never breaks (a letter of its own in each colour runs wider than the
    // name was measured); several keep a margin and break at their spaces.
    private _textH = _size * 1.1 * _lines;
    private _pad = [0, SQUARE(TEXT_UNIT * 0.3)] select (_lines > 1);
    private _words = [_display, "AIO_StructuredText", _tooltip, [_pad, (_height - _textH) / 2 + _size * 0.05, _width - _pad * 2, _textH + _size * 0.4]] call FUNC(uiCreate);

    _words ctrlSetStructuredText ([_text, _font, _size, 2, _from + [1], _to, _lines == 1] call FUNC(gradientText));
    _words ctrlEnable false;

    _parts pushBack _words;
} else {
    _parts pushBack ([
        _display, _tooltip, [0, 0, _width, _height], _text, _size, _theme getOrDefault ["text", [1, 1, 1, 1]], _font, 2, "never"
    ] call FUNC(uiLabel));
};

_tooltip setVariable [QGVAR(tipParts), _parts];
