#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Creates a button the way Enhanced First Aid Kits draws them: a flat surface with an icon and a
 * label, centred together, and over it a hit area with no look of its own. The surface lights up
 * while the mouse is on it. A left click runs the code with [1, id], a right click with [-1, id] - so a
 * button that steps through choices goes forward and back, and one code serves several buttons that
 * tell themselves apart by their id (each kit window's cross, fnc_drawWindow).
 *
 * A disabled button is drawn in muted colours, does not light up and does nothing when clicked - Sort
 * while its own moves are under way (fnc_drawSection). The code always runs a frame later
 * (fnc_later): a button may rebuild the window, which deletes this very control.
 *
 * The label sits where the measured text ends up by default, which can be a little off: getTextWidth reports
 * less than the engine draws, and a left-aligned label starts where the measured text would be centred. A
 * "centred" button lets the engine do the centring instead: the label is as wide as the room between the
 * paddings (as wide as what is left of it beside an icon, which keeps to the left padding), aligned in
 * the middle, in a box as high as the text needs (TEXT_MID of its font height either side of the button's
 * middle), so the line of capitals lies in the middle of the button's height too. fnc_buttonWidth gives the
 * width that fits such a button.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group to create it in, or controlNull for the display <CONTROL>
 * 2: Position [x, y, w, h] <ARRAY>
 * 3: Id, kept on the hit area as QGVAR(id) <STRING>
 * 4: Label, "" for none <STRING>
 * 5: Icon texture, "" for none <STRING>
 * 6: Theme <HASHMAP>
 * 7: Code, called with [1, id] or [-1, id] <CODE>
 * 8: Disabled <BOOL> (default: false)
 * 9: Text height - the label's size, -1 for a share of the button's height <NUMBER> (default: -1)
 * 10: Centred - the label and an icon beside it laid out as described above <BOOL> (default: false)
 * 11: How far the hit area would reach beyond the surface, [x, y] either side or [left, top, right, bottom]. Kept
 *     so that the old callers work, but the rule is the same for every button now: the hit area is the drawn
 *     button and 2 pixels on each side, so that one who just misses the button still hits it -
 *     and no more, so a button does not take the clicks of what lies beside it. A larger request is cut to that;
 *     a smaller one is raised to it <ARRAY> (default: [])
 *
 * Return Value:
 * The controls, the hit area last <ARRAY>
 *
 * Example:
 * [_display, controlNull, [0.8, 0.02, 0.1, 0.04], "close", "", "", _theme, {closeDialog 2}] call einv_gui_fnc_uiButton;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_parent", "_rect", "_id", "_text", "_icon", "_theme", "_code", ["_disabled", false], ["_textSize", -1], ["_centred", false], ["_hitPad", []]];
_rect params ["_left", "_top", "_width", "_height"];

private _normal = _theme getOrDefault ["button", [1, 1, 1, 0.06]];
private _hover = _theme getOrDefault ["buttonHover", [1, 1, 1, 0.1]];
private _ink = _theme getOrDefault ["buttonText", [1, 1, 1, 1]];
private _font = _theme getOrDefault ["font", "PuristaMedium"];

// Muted: the label in the theme's muted ink, the surface nearly gone and no lighter under the mouse.
if (_disabled) then {
    _ink = _theme getOrDefault ["muted", [0.56, 0.56, 0.56, 1]];

    if (_normal isNotEqualTo []) then {
        _normal = +_normal;
        _normal set [3, (_normal select 3) * 0.5];
    };

    _hover = _normal;
};

// A style without button surfaces still gets a clear one, so there is something to light up.
if (_normal isEqualTo []) then {
    _normal = [0, 0, 0, 0];
};

private _controls = [_display, _parent, _rect, _normal, (_theme getOrDefault ["radius", 0]) min (_height / 2)] call FUNC(uiPanel);
private _rects = _controls select {ctrlClassName _x isEqualTo "EINV_PanelRect"};
private _corners = _controls select {ctrlClassName _x isEqualTo "EINV_PanelCorner"};

private _caption = [_text, _theme] call FUNC(caption);
private _hasIcon = _icon isNotEqualTo "";
private _size = [_height * 0.48, _textSize] select (_textSize > 0);
private _iconH = _height * BUTTON_ICON;
private _iconW = [0, SQUARE(_iconH)] select _hasIcon;
private _gap = [0, SQUARE(_height * BUTTON_GAP)] select (_hasIcon && {_caption isNotEqualTo ""});
private _pad = SQUARE(_height * BUTTON_PAD);
private _room = _width - _pad * 2 - _iconW - _gap;

if (_centred) then {
    private _labelX = _left + _pad;
    private _labelW = _width - _pad * 2;

    if (_hasIcon) then {
        // An icon alone sits in the middle; with a label it keeps to the left padding, and the label is
        // centred in the room beside it.
        private _iconX = [_left + (_width - _iconW) / 2, _left + _pad] select (_caption isNotEqualTo "");

        _controls pushBack ([_display, _parent, [_iconX, _top + (_height - _iconH) / 2, _iconW, _iconH], _icon, _ink] call FUNC(uiIcon));

        _labelX = _left + _pad + _iconW + _gap;
        _labelW = _room;
    };

    if (_caption isNotEqualTo "" && {_labelW > 0}) then {
        // A box as high as the text needs, middle on the button's middle: the line sits in it the same
        // whether the engine draws it from the box's top or centres it in the box - in a box as high as the
        // button the second put a larger label (the card of fnc_confirmClose) well below the middle.
        private _labelTop = _top + _height / 2 - TEXT_MID * _size;

        _controls pushBack ([
            _display, _parent, [_labelX, _labelTop, _labelW, TEXT_MID * _size * 2],
            [_caption, _labelW, _font, _size] call FUNC(fitText), _size, _ink, _font, 2
        ] call FUNC(uiLabel));
    };
} else {
    private _shown = "";
    private _textW = 0;

    if (_caption isNotEqualTo "" && {_room > 0}) then {
        _shown = [_caption, _room, _font, _size] call FUNC(fitText);
        _textW = (_shown getTextWidth [_font, _size]) min _room;
    };

    // An icon alone sits in the middle; with a label the two keep off the edges.
    private _start = _left + (((_width - _iconW - _gap - _textW) / 2) max ([_pad, 0] select (_shown isEqualTo "")));

    if (_hasIcon) then {
        _controls pushBack ([_display, _parent, [_start, _top + (_height - _iconH) / 2, _iconW, _iconH], _icon, _ink] call FUNC(uiIcon));
    };

    if (_shown isNotEqualTo "") then {
        // Left-aligned in a box running to the button's edge: anything the engine draws wider than measured
        // spills to the right, never off the left.
        private _labelX = _start + _iconW + _gap;

        _controls pushBack ([_display, _parent, [_labelX, _top, _left + _width - _labelX, _height], _shown, _size, _ink, _font, 0] call FUNC(uiLabel));
    };
};

// The hit area: the surface and two pixels on every side, whatever the caller asked for (argument 11 is capped to
// that - the section captions and the kit windows used to ask for a whole cell).
private _padLeft = pixelW * 2;
private _padRight = _padLeft;
private _padTop = pixelH * 2;
private _padBottom = _padTop;

private _hit = [
    _display, "EINV_Hitbox", _parent,
    [_left - _padLeft, _top - _padTop, _width + _padLeft + _padRight, _height + _padTop + _padBottom]
] call FUNC(uiCreate);

// Nothing more to do for a disabled one - it only keeps clicks off what lies under it.
if (_disabled) exitWith {
    _controls pushBack _hit;
    _controls
};

_hit setVariable [QGVAR(id), _id];
_hit setVariable [QGVAR(code), _code];
_hit setVariable [QGVAR(surface), [_rects, _corners, _normal, _hover]];

// The surface lights up under the mouse. Its rectangles take the colour as their background, its
// round corners - pictures - as their text colour.
_hit ctrlAddEventHandler ["MouseEnter", {
    params ["_ctrl"];
    (_ctrl getVariable [QGVAR(surface), [[], [], [], []]]) params ["_rects", "_corners", "", "_color"];

    {_x ctrlSetBackgroundColor _color} forEach _rects;
    {_x ctrlSetTextColor _color} forEach _corners;
}];

_hit ctrlAddEventHandler ["MouseExit", {
    params ["_ctrl"];
    (_ctrl getVariable [QGVAR(surface), [[], [], [], []]]) params ["_rects", "_corners", "_color"];

    {_x ctrlSetBackgroundColor _color} forEach _rects;
    {_x ctrlSetTextColor _color} forEach _corners;
}];

// The code runs a frame later: a button may rebuild the window, and that
// deletes this very control, which should not happen inside its own event. A button's own click event
// is the left button's only, so the right click is taken from the right button's release.
_hit ctrlAddEventHandler ["ButtonClick", {
    params ["_ctrl"];

    [_ctrl getVariable [QGVAR(code), {}], [1, _ctrl getVariable [QGVAR(id), ""]]] call FUNC(later);
}];

_hit ctrlAddEventHandler ["MouseButtonUp", {
    params ["_ctrl", "_button"];

    if (_button != 1) exitWith {};

    [_ctrl getVariable [QGVAR(code), {}], [-1, _ctrl getVariable [QGVAR(id), ""]]] call FUNC(later);
}];

_controls pushBack _hit;

_controls
