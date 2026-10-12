#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Creates a key hint for the footer: the key on a badge, then what it does. The badge is a rounded
 * key cap, or with the theme's keyRound a circle - a pill when the key's name is too
 * long for a circle.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group to create it in, or controlNull for the display <CONTROL>
 * 2: Top left corner [x, y] <ARRAY>
 * 3: Key, e.g. "ESC" <STRING>
 * 4: What it does, "" for nothing <STRING>
 * 5: Theme <HASHMAP>
 * 6: Height <NUMBER> (default: UNIT * 0.9)
 *
 * Return Value:
 * Width taken, including the space before the next hint - the next one starts at x plus this <NUMBER>
 *
 * Example:
 * [_display, controlNull, [0.1, 0.9], "ESC", "Close", _theme] call einv_gui_fnc_uiKeyHint;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_parent", "_position", "_key", "_text", "_theme", ["_height", UNIT * 0.9]];
_position params ["_left", "_top"];

private _font = _theme getOrDefault ["font", "PuristaMedium"];
private _fontBold = _theme getOrDefault ["fontBold", "PuristaSemibold"];
private _keyBg = _theme getOrDefault ["keyBg", [1, 1, 1, 0.15]];
private _keyText = _theme getOrDefault ["keyText", [0.925, 0.933, 0.949, 1]];
private _round = _theme getOrDefault ["keyRound", false];

private _keySize = _height * 0.56;
private _textSize = _height * 0.62;
private _circleW = SQUARE(_height);
private _badgeW = (((_key getTextWidth [_fontBold, _keySize]) * TEXT_SLACK) + SQUARE(_height * 0.45)) max _circleW;

if (_round && {_badgeW <= _circleW}) then {
    [_display, _parent, [_left, _top, _circleW, _height], UI_TEX(circle_ca), _keyBg] call FUNC(uiIcon);
} else {
    private _radius = [(_theme getOrDefault ["radius", 0]) min (_height * 0.3), _height / 2] select _round;

    [_display, _parent, [_left, _top, _badgeW, _height], _keyBg, _radius] call FUNC(uiPanel);
};

[_display, _parent, [_left, _top, _badgeW, _height], _key, _keySize, _keyText, _fontBold, 2] call FUNC(uiLabel);

private _taken = _badgeW + SQUARE(_height * 0.9);

if (_text isNotEqualTo "") then {
    private _gap = SQUARE(_height * 0.3);
    private _textW = (_text getTextWidth [_font, _textSize]) * TEXT_SLACK;

    [_display, _parent, [_left + _badgeW + _gap, _top, _textW, _height], _text, _textSize, _theme getOrDefault ["text2", [0.639, 0.675, 0.725, 1]], _font, 0] call FUNC(uiLabel);

    _taken = _taken + _gap + _textW;
};

_taken
