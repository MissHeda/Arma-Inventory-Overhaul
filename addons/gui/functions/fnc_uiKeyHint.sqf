#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Creates a key hint for the footer: the key on a badge, then what it does. The badge is a rounded
 * key cap, or with the theme's keyRound a circle - a pill when the key's name is too
 * long for a circle.
 *
 * A key with a mouse button in it is written with a token: "@left", "@right", "@scroll" or "@double" (two
 * left clicks), alone or after modifiers joined by "+" - "Ctrl+@left". The modifiers are key caps as any
 * key, the mouse button is ACE's own picture on a cap of its own (ACE's interaction addon ships mouse_left,
 * mouse_right and mouse_scroll); with no such picture the cap says it in words ("Right click").
 *
 * The spacing is one rule for every hint, so a row of them reads evenly: all caps are the same height
 * (whole pixels, so none is a pixel off its neighbour) and a mouse cap is as large as a one-letter key cap;
 * caps of one key and the cap and its words are one gap apart; the next hint begins a larger gap after the
 * words, which are measured as they are (the label's own box has room to spare, the advance has not).
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group to create it in, or controlNull for the display <CONTROL>
 * 2: Top left corner [x, y] <ARRAY>
 * 3: Key, e.g. "ESC", or with a mouse button, e.g. "Ctrl+@left" <STRING>
 * 4: What it does, "" for nothing <STRING>
 * 5: Theme <HASHMAP>
 * 6: Height <NUMBER> (default: TEXT_UNIT * 0.9 - it grows with the tile scale, fnc_textScale)
 * 7: Only measure: nothing is created <BOOL> (default: false)
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

params ["_display", "_parent", "_position", "_key", "_text", "_theme", ["_height", TEXT_UNIT * 0.9], ["_measure", false]];
_position params ["_left", "_top"];

// Whole pixels: every cap of every hint is then the same height and sits on the same line.
private _originY = [safezoneY, 0] select !isNull _parent;

_height = ((round (_height / pixelH)) max 1) * pixelH;
_top = _originY + round ((_top - _originY) / pixelH) * pixelH;

private _font = _theme getOrDefault ["font", "PuristaMedium"];
private _fontBold = _theme getOrDefault ["fontBold", "PuristaSemibold"];
private _keyBg = _theme getOrDefault ["keyBg", [1, 1, 1, 0.15]];
private _keyText = _theme getOrDefault ["keyText", [1, 1, 1, 1]];
private _round = _theme getOrDefault ["keyRound", false];

private _keySize = _height * 0.56;
private _textSize = _height * 0.62;
private _circleW = SQUARE(_height);

// One gap between caps of one key and between the cap and its words; a larger one before the next hint.
private _gap = SQUARE(_height * 0.3);
private _capGap = _gap;
private _entryGap = SQUARE(_height * 0.9);

// The caps the key is made of: [text, "", 1] for a key cap, ["", picture, how many] for a mouse button. A key with
// no token is one cap, as ever.
private _caps = [];

if ((_key find "@") < 0) then {
    _caps pushBack [_key, "", 1];
} else {
    {
        private _part = _x;

        if ((_part select [0, 1]) isNotEqualTo "@") then {
            _caps pushBack [_part, "", 1];
            continue;
        };

        // The picture in ACE's interaction addon, and words for the same where it is not there.
        private _pair = switch (_part) do {
            case "@left": {["mouse_left_ca.paa", LLSTRING(Key_LeftClick), 1]};
            case "@right": {["mouse_right_ca.paa", LLSTRING(Key_RightClick), 1]};
            case "@scroll": {["mouse_scroll_ca.paa", LLSTRING(Key_Scroll), 1]};
            case "@double": {["mouse_left_ca.paa", LLSTRING(Key_DoubleClick), 2]};
            default {["", _part, 1]};
        };

        _pair params ["_file", "_words", "_times"];

        private _picture = if (_file isEqualTo "") then {""} else {[MOUSE_ICON_PATH + "\" + _file] call FUNC(safePicture)};

        if (_picture isEqualTo "") then {
            _caps pushBack [_words, "", 1];
        } else {
            _caps pushBack ["", _picture, _times];
        };
    } forEach (_key splitString "+");
};

// A mouse picture as large as the letter of a key cap: the cap is the same square, the picture is not
// to make it look bigger than the keys beside it.
private _iconSide = (round (_height * 0.66 / pixelH)) * pixelH;

// Each cap's width: a key cap as wide as its name, at least a circle; a mouse button's a circle, two of
// them a little wider than two pictures.
private _widths = _caps apply {
    _x params ["_capText", "_capPicture", "_times"];

    if (_capPicture isEqualTo "") then {
        (((_capText getTextWidth [_fontBold, _keySize]) * TEXT_SLACK) + SQUARE(_height * 0.45)) max _circleW
    } else {
        [_circleW, SQUARE(_height * 0.3) + SQUARE(_iconSide) * _times] select (_times > 1)
    }
};

private _badgeW = _capGap * (count _caps - 1);

{
    _badgeW = _badgeW + _x;
} forEach _widths;

private _taken = _badgeW + _entryGap;
private _textW = 0;

if (_text isNotEqualTo "") then {
    // The advance is the words as they are, the label has the slack: the gap after them is the same
    // whatever the words.
    private _textExact = _text getTextWidth [_font, _textSize];

    _textW = _textExact * TEXT_SLACK;
    _taken = _taken + _gap + _textExact;
};

if (_measure) exitWith {_taken};

private _capX = _left;

{
    _x params ["_capText", "_capPicture", "_times"];

    private _capW = _widths select _forEachIndex;

    if (_round && {_capW <= _circleW}) then {
        [_display, _parent, [_capX, _top, _circleW, _height], UI_TEX(circle_ca), _keyBg] call FUNC(uiIcon);
    } else {
        private _radius = [(_theme getOrDefault ["radius", 0]) min (_height * 0.3), _height / 2] select _round;

        [_display, _parent, [_capX, _top, _capW, _height], _keyBg, _radius] call FUNC(uiPanel);
    };

    if (_capPicture isEqualTo "") then {
        [_display, _parent, [_capX, _top, _capW, _height], _capText, _keySize, _keyText, _fontBold, 2, "key"] call FUNC(uiLabel);
    } else {
        private _iconW = SQUARE(_iconSide);
        private _iconX = _capX + (_capW - _iconW * _times) / 2;

        for "_i" from 0 to (_times - 1) do {
            [_display, _parent, [_iconX + _iconW * _i, _top + (round ((_height - _iconSide) / 2 / pixelH)) * pixelH, _iconW, _iconSide], _capPicture, _keyText] call FUNC(uiIcon);
        };
    };

    _capX = _capX + _capW + _capGap;
} forEach _caps;

if (_text isNotEqualTo "") then {
    [_display, _parent, [_left + _badgeW + _gap, _top, _textW, _height], _text, _textSize, _theme getOrDefault ["text2", [0.78, 0.78, 0.78, 1]], _font, 0, "button"] call FUNC(uiLabel);
};

_taken
