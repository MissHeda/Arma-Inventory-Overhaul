#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The edit mode of the window, as Arma's own layout editor (#67): each column - equipment, your gear, loot - is a frame over the
 * window, to be dragged anywhere and resized at its edges and corners as a window on the desktop, each grip with the arrows the
 * mouse shows there (fnc_layoutDrag). The parts of the equipment column - the weight, the weapons, the gear, the hotbar - have a
 * frame of their own inside it: dragged out, a part stands on its own, with its own panel (fnc_layoutGlass), and its title has a
 * button that puts it back. Let go, the window is built again with it there. A bar on top has the tile and text size, which take
 * effect at once, Reset for the usual places, and Done. Escape leaves it as well.
 *
 * The loot column has a frame while nothing is looted too, so that it can be placed. A grid column cannot get narrower than its grid
 * (fnc_columnMinimum): the tile scale is what makes it narrower.
 *
 * Every button here acts on the press, not on the click: a click is a press and a release on the same control, and a window built
 * again in between - the loot nearby, the hotbar - made the release land on a new control, so the click never came.
 *
 * A layer over the screen like the other popovers (aio_gui_menu, aio_gui_menuFor "layout"), which stays open while the window is built
 * again: fnc_build and fnc_raiseMenu make it again.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display] call aio_gui_fnc_openLayoutEditor;
 *
 * Public: No
 */

disableSerialization;

params ["_display"];

private _back = if ((uiNamespace getVariable [QGVAR(menu), []]) isEqualTo []) then {
    private _focused = focusedCtrl _display;

    [controlNull, _focused] select (!isNull _focused && {ctrlType _focused == 2})
} else {
    uiNamespace getVariable [QGVAR(menuFocusBack), controlNull]
};

GVAR(menuRemake) = !isNull ((uiNamespace getVariable [QGVAR(menu), []]) param [0, controlNull]) && {(GVAR(menuFor) param [0, ""]) isEqualTo "layout"};
[] call FUNC(closeMenu);
GVAR(menuRemake) = false;

(uiNamespace getVariable [QGVAR(tooltip), controlNull]) ctrlShow false;
ctrlDelete (uiNamespace getVariable [QGVAR(compare), controlNull]);
uiNamespace setVariable [QGVAR(compare), controlNull];
uiNamespace setVariable [QGVAR(tipShown), controlNull];

private _theme = GVAR(theme);
private _font = _theme getOrDefault ["font", "PuristaMedium"];
private _fontBold = _theme getOrDefault ["fontBold", _font];
private _accent = (_theme getOrDefault ["accent", [0.84, 0.54, 0.1, 1]]) select [0, 3];
private _text = [1, 1, 1, 1];
private _text2 = [0.78, 0.78, 0.78, 1];
private _muted = [0.56, 0.56, 0.56, 1];
private _dark = [0.02, 0.02, 0.02, 0.9];
private _size = UNIT * 0.55;

private _layer = [_display, "AIO_Group", controlNull, [safezoneX, safezoneY, safezoneW, safezoneH]] call FUNC(uiCreate);

_layer setVariable [QGVAR(plain), true];
_layer setVariable [QGVAR(hooked), true];
_layer ctrlAddEventHandler ["MouseButtonDown", {[true, _this] call FUNC(onMouseButton); false}];
_layer ctrlAddEventHandler ["MouseButtonUp", {[false, _this] call FUNC(onMouseButton); false}];

// The window under it takes no click while it is edited; a click beside the frames does nothing either.
[_display, "AIO_Hitbox", _layer, [0, 0, safezoneW, safezoneH]] call FUNC(uiCreate);

// A film over the window, so the frames stand out.
[_display, _layer, [0, 0, safezoneW, safezoneH], [0, 0, 0, 0.45], 0] call FUNC(uiPanel);

// A button that acts on the press (see above): its surface, an icon and a word, lighter under the mouse. The code gets the button's
// argument, a frame later.
private _fnc_button = {
    params ["_rect", "_icon", "_word", "_code", ["_argument", []], ["_colors", [[1, 1, 1, 0.08], [1, 1, 1, 0.18]]], ["_ink", _text2], ["_tip", ""]];
    _rect params ["_left", "_top", "_width", "_height"];
    _colors params ["_normal", "_hover"];

    private _surface = [_display, _layer, _rect, _normal, _height * 0.3] call FUNC(uiPanel);
    private _iconH = _height * 0.6;
    private _iconW = [0, SQUARE(_iconH)] select (_icon isNotEqualTo "");
    private _wordSize = _height * 0.5;
    private _wordW = [0, (_word getTextWidth [_font, _wordSize]) * 1.05] select (_word isNotEqualTo "");
    private _gap = [0, SQUARE(_height * 0.2)] select (_iconW > 0 && {_wordW > 0});
    private _start = _left + (_width - _iconW - _gap - _wordW) / 2;

    if (_iconW > 0) then {
        [_display, _layer, [_start, _top + (_height - _iconH) / 2, _iconW, _iconH], _icon, _ink] call FUNC(uiIcon);
    };

    if (_wordW > 0) then {
        [_display, _layer, [_start + _iconW + _gap, _top, _wordW + pixelW * 4, _height], _word, _wordSize, _ink, _font, 0, "never"] call FUNC(uiLabel);
    };

    private _hit = [_display, "AIO_Hitbox", _layer, _rect] call FUNC(uiCreate);

    _hit setVariable [QGVAR(layoutPress), [_code, _argument]];
    _hit setVariable [QGVAR(layoutSurface), [_surface select {ctrlClassName _x isEqualTo "AIO_PanelRect"}, _surface select {ctrlClassName _x isEqualTo "AIO_PanelCorner"}, _normal, _hover]];

    if (_tip isNotEqualTo "") then {
        [_hit, _tip] call FUNC(setTooltip);
    };

    _hit ctrlAddEventHandler ["MouseButtonDown", {
        params ["_ctrl", "_button"];

        if (_button != 0) exitWith {};

        (_ctrl getVariable [QGVAR(layoutPress), [{}, []]]) params ["_code", "_argument"];

        [_code, _argument] call FUNC(later);
    }];

    {
        _x params ["_event", "_which"];

        _hit ctrlAddEventHandler [_event, compile format ["
            params ['_ctrl'];
            (_ctrl getVariable ['%1', [[], [], [], []]]) params ['_rects', '_corners', '_normal', '_hover'];
            private _color = %2;
            {_x ctrlSetBackgroundColor _color} forEach _rects;
            {_x ctrlSetTextColor _color} forEach _corners;
        ", QGVAR(layoutSurface), _which]];
    } forEach [["MouseEnter", "_hover"], ["MouseExit", "_normal"]];

    _hit
};

// A grip: a press on it starts a drag of that frame in that mode.
private _fnc_grip = {
    params ["_rect", "_drag"];

    private _hit = [_display, "AIO_Hitbox", _layer, _rect] call FUNC(uiCreate);

    _hit setVariable [QGVAR(layoutDrag), _drag];
    _hit ctrlAddEventHandler ["MouseButtonDown", {
        params ["_ctrl", "_button"];

        if (_button != 0) exitWith {};

        ["begin", [ctrlParent _ctrl, _ctrl getVariable [QGVAR(layoutDrag), []], ctrlParentControlsGroup _ctrl]] call FUNC(layoutDrag);
    }];

    _hit
};

// ----- The frames -----

private _rects = [true] call FUNC(columnRects);
private _knob = UNIT * 0.9;
private _knobW = SQUARE(_knob);
private _strip = UNIT * 0.35;
private _stripW = SQUARE(_strip);
private _chipH = UNIT * 0.9;
private _names = createHashMapFromArray [
    ["equipment", LLSTRING(Column_Equipment)], ["storage", LLSTRING(Column_Storage)], ["loot", LLSTRING(Column_Loot)],
    ["weight", LLSTRING(SettingsMenu_PartWeight)], ["weapons", LLSTRING(SettingsMenu_PartWeapons)],
    ["gear", LLSTRING(SettingsMenu_PartGear)], ["hotbar", LLSTRING(SettingsMenu_PartHotbar)]
];

// [id, screen rect, a part in the column - moved only, which takes it out -, a part on its own - with the button back].
private _frames = [];

{
    _frames pushBack [_x, _rects get _x, false, false];
} forEach ["equipment", "storage", "loot"];

{
    if ([_x] call FUNC(partShown)) then {
        if (_x in _rects) then {
            _frames pushBack [_x, _rects get _x, false, true];
        } else {
            private _inColumn = GVAR(partRects) getOrDefault [_x, []];

            if (count _inColumn == 4) then {
                _frames pushBack [_x, _inColumn, true, false];
            };
        };
    };
} forEach EQUIPMENT_PARTS;

{
    _x params ["_id", "_screen", "_inColumn", "_alone"];
    _screen params ["_screenX", "_screenY", "_w", "_h"];

    private _left = _screenX - safezoneX;
    private _top = _screenY - safezoneY;
    private _rect = [_left, _top, _w, _h];
    private _part = _id in EQUIPMENT_PARTS;

    // A column a light film and a fine line; a part in the column a little stronger, so it stands out of its column.
    [_display, _layer, _rect, _accent + [[0.06, 0.14] select _part], 0] call FUNC(uiPanel);
    [_display, _layer, _rect, _accent + [[0.55, 0.85] select _part], [], 1] call FUNC(uiOutline);

    // The body moves it. A part in the column only moves - out of it.
    [_rect, [_id, "move", _screen]] call _fnc_grip;

    // The title: a dark chip at the top left with the four arrows and the name - the frame's handle.
    private _name = _names getOrDefault [_id, _id];
    private _nameSize = _chipH * 0.55;
    private _chipW = ((SQUARE(_chipH * 0.7) + SQUARE(_chipH * 0.5) + (_name getTextWidth [_fontBold, _nameSize]) * 1.05) min (_w - SQUARE(UNIT * 2.4))) max SQUARE(_chipH);
    // Clear of the corner's knob.
    private _chipX = _left + SQUARE(UNIT * 0.7);
    private _chipY = _top + UNIT * 0.25;

    [_display, _layer, [_chipX, _chipY, _chipW, _chipH], _dark, _chipH * 0.3] call FUNC(uiPanel);
    [_display, _layer, [_chipX + SQUARE(_chipH * 0.2), _chipY + _chipH * 0.2, SQUARE(_chipH * 0.6), _chipH * 0.6], UI_TEX(icon_move_ca), _accent + [1]] call FUNC(uiIcon);
    [
        _display, _layer, [_chipX + SQUARE(_chipH * 0.95), _chipY, _chipW - SQUARE(_chipH * 1.05), _chipH],
        [_name, _chipW - SQUARE(_chipH * 1.05), _fontBold, _nameSize] call FUNC(fitText), _nameSize, _text, _fontBold, 0, "never"
    ] call FUNC(uiLabel);

    // A part on its own: back into the column, at the top right.
    if (_alone) then {
        [
            [_left + _w - SQUARE(_chipH + UNIT * 0.7), _chipY, SQUARE(_chipH), _chipH], UI_TEX(icon_undo_ca), "",
            {["attach", _this] call FUNC(layoutDrag)}, [_id], [_dark, [0.2, 0.2, 0.2, 0.95]], _text, LLSTRING(Layout_Attach)
        ] call _fnc_button;
    };

    if (!_inColumn) then {
        // The edges, whole: a thin strip along each resizes it one way. Then their middles and the corners, a knob with the arrows.
        [[_left - _stripW / 2, _top + _knob / 2, _stripW, _h - _knob], [_id, "l", _screen]] call _fnc_grip;
        [[_left + _w - _stripW / 2, _top + _knob / 2, _stripW, _h - _knob], [_id, "r", _screen]] call _fnc_grip;
        [[_left + _knobW / 2, _top - _strip / 2, _w - _knobW, _strip], [_id, "t", _screen]] call _fnc_grip;
        [[_left + _knobW / 2, _top + _h - _strip / 2, _w - _knobW, _strip], [_id, "b", _screen]] call _fnc_grip;

        {
            _x params ["_mode", "_icon", "_centreX", "_centreY"];

            private _knobRect = [_centreX - _knobW / 2, _centreY - _knob / 2, _knobW, _knob];

            [_display, _layer, _knobRect, _dark, _knob * 0.3] call FUNC(uiPanel);
            [_display, _layer, _knobRect, _accent + [0.9], [], 1] call FUNC(uiOutline);
            [
                _display, _layer, [(_knobRect select 0) + _knobW * 0.15, (_knobRect select 1) + _knob * 0.15, _knobW * 0.7, _knob * 0.7],
                _icon, _accent + [1]
            ] call FUNC(uiIcon);
            [_knobRect, [_id, _mode, _screen]] call _fnc_grip;
        } forEach [
            ["l", UI_TEX(icon_resize_h_ca), _left, _top + _h / 2],
            ["r", UI_TEX(icon_resize_h_ca), _left + _w, _top + _h / 2],
            ["t", UI_TEX(icon_resize_v_ca), _left + _w / 2, _top],
            ["b", UI_TEX(icon_resize_v_ca), _left + _w / 2, _top + _h],
            ["tl", UI_TEX(icon_resize_nwse_ca), _left, _top],
            ["br", UI_TEX(icon_resize_nwse_ca), _left + _w, _top + _h],
            ["tr", UI_TEX(icon_resize_nesw_ca), _left + _w, _top],
            ["bl", UI_TEX(icon_resize_nesw_ca), _left, _top + _h]
        ];
    };
} forEach _frames;

// ----- The bar on top: tile and text size, what to do, Reset, Done -----

private _barH = UNIT * 1.6;
private _buttonH = UNIT * 1;
private _buttonW = SQUARE(_buttonH);
private _padX = SQUARE(UNIT * 0.5);
private _gapX = SQUARE(UNIT * 0.3);
private _radius = UNIT * 0.3;
private _hint = LLSTRING(Layout_Drag);
private _hintSize = _size * 0.85;
private _titleSize = _size * 1.05;
private _title = LLSTRING(Layout_Edit);
private _stepNames = [LLSTRING(Size_Tiles), LLSTRING(Size_Text)];
private _stepNameW = selectMax (_stepNames apply {(_x getTextWidth [_font, _size * 0.9]) * 1.1});
private _shownW = SQUARE(UNIT * 1.9);
private _resetW = SQUARE(UNIT * 1.2) + ((LLSTRING(Layout_Reset) getTextWidth [_font, _buttonH * 0.5]) * 1.1) + SQUARE(UNIT * 0.6);
private _doneW = SQUARE(UNIT * 1.2) + ((LLSTRING(Layout_Done) getTextWidth [_font, _buttonH * 0.5]) * 1.1) + SQUARE(UNIT * 0.6);
private _titleW = SQUARE(UNIT * 0.9) + (_title getTextWidth [_fontBold, _titleSize]) * 1.05;
private _hintW = ((_hint getTextWidth [_font, _hintSize]) * 1.05) min SQUARE(UNIT * 9);
private _stepW = _stepNameW + _buttonW * 2 + _shownW;
private _barW = (_padX * 2 + _titleW + _gapX * 6 + _stepW * 2 + _hintW + _resetW + _doneW) min (safezoneW - SQUARE(UNIT));
private _barX = (safezoneW - _barW) / 2;
private _barY = UNIT * 0.4;
private _buttonTop = _barY + (_barH - _buttonH) / 2;

[_display, _layer, [_barX, _barY + pixelH * 3, _barW, _barH], [0, 0, 0, 0.4], _radius] call FUNC(uiPanel);
[_display, _layer, [_barX, _barY, _barW, _barH], [0.015, 0.015, 0.015, 0.97], _radius] call FUNC(uiPanel);
[_display, _layer, [_barX, _barY, _barW, _barH], _accent + [0.35], [], 1] call FUNC(uiOutline);
[_display, "AIO_Hitbox", _layer, [_barX, _barY, _barW, _barH]] call FUNC(uiCreate);

private _cursor = _barX + _padX;

// What it is: the four arrows and "Edit layout".
[_display, _layer, [_cursor, _barY + (_barH - UNIT * 0.7) / 2, SQUARE(UNIT * 0.7), UNIT * 0.7], UI_TEX(icon_move_ca), _accent + [1]] call FUNC(uiIcon);
[_display, _layer, [_cursor + SQUARE(UNIT * 0.9), _barY, _titleW, _barH], _title, _titleSize, _text, _fontBold, 0, "never"] call FUNC(uiLabel);

_cursor = _cursor + _titleW + _gapX;

private _fnc_divider = {
    [_display, _layer, [_cursor, _barY + _barH * 0.25, pixelW, _barH * 0.5], [1, 1, 1, 0.12], 0] call FUNC(uiPanel);
    _cursor = _cursor + _gapX;
};

call _fnc_divider;

{
    private _index = _forEachIndex;
    private _value = [_index] call FUNC(sizeValue);

    [_display, _layer, [_cursor, _barY, _stepNameW, _barH], _x, _size * 0.9, _text2, _font, 0, "never"] call FUNC(uiLabel);

    _cursor = _cursor + _stepNameW;

    [[_cursor, _buttonTop, _buttonW, _buttonH], UI_TEX(icon_minus_ca), "", {["step", _this] call FUNC(layoutDrag)}, [_index, -SIZE_STEP]] call _fnc_button;

    _cursor = _cursor + _buttonW;

    [_display, _layer, [_cursor, _barY, _shownW, _barH], (str round (_value * 100)) + "%", _size * 0.9, _text, _fontBold, 2, "never"] call FUNC(uiLabel);

    _cursor = _cursor + _shownW;

    [[_cursor, _buttonTop, _buttonW, _buttonH], UI_TEX(icon_plus_ca), "", {["step", _this] call FUNC(layoutDrag)}, [_index, SIZE_STEP]] call _fnc_button;

    _cursor = _cursor + _buttonW + _gapX;

    call _fnc_divider;
} forEach _stepNames;

// How it works, in a word.
private _hintRoom = (_barX + _barW - _padX - _doneW - _gapX - _resetW - _gapX) - _cursor;

if (_hintRoom > SQUARE(UNIT * 2)) then {
    [_display, _layer, [_cursor, _barY, _hintRoom, _barH], [_hint, _hintRoom, _font, _hintSize] call FUNC(fitText), _hintSize, _muted, _font, 0, "never"] call FUNC(uiLabel);
};

private _doneX = _barX + _barW - _padX - _doneW;
private _resetX = _doneX - _gapX - _resetW;

[[_resetX, _buttonTop, _resetW, _buttonH], UI_TEX(icon_reset_ca), LLSTRING(Layout_Reset), {["reset"] call FUNC(layoutDrag)}] call _fnc_button;

// Done, in the accent: back to the card it was opened from.
[
    [_doneX, _buttonTop, _doneW, _buttonH], UI_TEX(icon_check_ca), LLSTRING(Layout_Done),
    {[uiNamespace getVariable [QGVAR(display), displayNull]] call FUNC(openSizeMenu)}, [],
    [_accent + [0.85], _accent + [1]], _theme getOrDefault ["onAccent", [0.05, 0.05, 0.05, 1]]
] call _fnc_button;

// The focus into the layer, so it is drawn over everything: a button no one sees, one pixel in the bar.
private _focus = [_display, "AIO_Hitbox", _layer, [_barX + pixelW, _barY + pixelH, pixelW, pixelH]] call FUNC(uiCreate);

ctrlSetFocus _focus;

uiNamespace setVariable [QGVAR(menuFocus), [_layer, _focus]];
uiNamespace setVariable [QGVAR(menu), [_layer]];
uiNamespace setVariable [QGVAR(menuFocusBack), _back];
uiNamespace setVariable [QGVAR(menuRect), [safezoneX, safezoneY, safezoneW, safezoneH]];

GVAR(menuState) = ["layout"];
GVAR(menuFor) = ["layout", -1];
