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
 * [_tooltip, "MX 6.5 mm", 0.2] call einv_gui_fnc_setTipText;
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

if (_tooltip getVariable [QGVAR(gradient), false]) then {
    private _from = _theme getOrDefault ["titleColor", []];

    if (count _from < 3) then {
        _from = _theme getOrDefault ["accent", [1, 1, 1, 1]];
    };

    private _words = [_display, "EINV_StructuredText", _tooltip, [0, (_height - _size) / 2 - pixelH, _width, _size * 1.4]] call FUNC(uiCreate);

    _words ctrlSetStructuredText ([
        _text, _font, _size, 2, (_from select [0, 3]) + [1], _theme getOrDefault ["titleGradient", [1, 1, 1]]
    ] call FUNC(gradientText));

    _parts pushBack _words;
} else {
    _parts pushBack ([
        _display, _tooltip, [0, 0, _width, _height], _text, _size, _theme getOrDefault ["text", [1, 1, 1, 1]], _font, 2
    ] call FUNC(uiLabel));
};

_tooltip setVariable [QGVAR(tipParts), _parts];
