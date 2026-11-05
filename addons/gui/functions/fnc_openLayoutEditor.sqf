#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The edit mode of the window, as Arma's own layout editor (#67): each column - equipment, your gear, loot - is a frame over the
 * window, to be dragged anywhere and resized at its corners as a window on the desktop (fnc_layoutDrag). Let go, the window is built
 * again with it there. A bar on top has the tile and text size, which take effect at once, Reset for the usual places, and Done.
 * Escape leaves it as well.
 *
 * The loot column has a frame while nothing is looted too, so that it can be placed. A grid column cannot get narrower than its grid
 * (fnc_columnMinimum): the tile scale is what makes it narrower.
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
private _size = UNIT * 0.55;

private _layer = [_display, "AIO_Group", controlNull, [safezoneX, safezoneY, safezoneW, safezoneH]] call FUNC(uiCreate);

_layer setVariable [QGVAR(plain), true];
_layer setVariable [QGVAR(hooked), true];
_layer ctrlAddEventHandler ["MouseButtonDown", {[true, _this] call FUNC(onMouseButton); false}];
_layer ctrlAddEventHandler ["MouseButtonUp", {[false, _this] call FUNC(onMouseButton); false}];

// The window under it takes no click while it is edited; a click beside the frames does nothing either.
[_display, "AIO_Hitbox", _layer, [0, 0, safezoneW, safezoneH]] call FUNC(uiCreate);

// A film over the window, so the frames stand out.
[_display, _layer, [0, 0, safezoneW, safezoneH], [0, 0, 0, 0.35]] call FUNC(uiPanel);

// ----- The frames -----

private _rects = [true] call FUNC(columnRects);
private _grip = UNIT * 0.8;
private _gripW = SQUARE(_grip);

{
    _x params ["_id", "_name"];

    (_rects get _id) params ["_screenX", "_screenY", "_w", "_h"];

    private _left = _screenX - safezoneX;
    private _top = _screenY - safezoneY;

    [_display, _layer, [_left, _top, _w, _h], _accent + [0.14], 0] call FUNC(uiPanel);
    [_display, _layer, [_left, _top, _w, _h], _accent + [0.9], [], 2] call FUNC(uiOutline);
    [_display, _layer, [_left, _top + _h / 2 - UNIT, _w, UNIT * 1.2], _name, UNIT * 0.8, _text, _fontBold, 2, "never"] call FUNC(uiLabel);
    [_display, _layer, [_left, _top + _h / 2 + UNIT * 0.2, _w, UNIT], LLSTRING(Layout_Drag), _size * 0.8, _text2, _font, 2, "never"] call FUNC(uiLabel);

    // The whole frame moves it; the corners over it resize it.
    private _move = [_display, "AIO_Hitbox", _layer, [_left, _top, _w, _h]] call FUNC(uiCreate);

    _move setVariable [QGVAR(layoutDrag), [_id, "move"]];

    private _hits = [_move];

    {
        _x params ["_mode", "_gripX", "_gripY"];

        [_display, _layer, [_gripX, _gripY, _gripW, _grip], _accent + [1], 0] call FUNC(uiPanel);

        private _hit = [_display, "AIO_Hitbox", _layer, [_gripX, _gripY, _gripW, _grip]] call FUNC(uiCreate);

        _hit setVariable [QGVAR(layoutDrag), [_id, _mode]];
        _hits pushBack _hit;
    } forEach [
        ["tl", _left, _top],
        ["tr", _left + _w - _gripW, _top],
        ["bl", _left, _top + _h - _grip],
        ["br", _left + _w - _gripW, _top + _h - _grip]
    ];

    {
        _x ctrlAddEventHandler ["MouseButtonDown", {
            params ["_ctrl", "_button"];

            if (_button != 0) exitWith {};

            ["begin", [ctrlParent _ctrl, _ctrl getVariable [QGVAR(layoutDrag), []], ctrlParentControlsGroup _ctrl]] call FUNC(layoutDrag);
        }];
    } forEach _hits;
} forEach [
    ["equipment", LLSTRING(Column_Equipment)],
    ["storage", LLSTRING(Column_Storage)],
    ["loot", LLSTRING(Column_Loot)]
];

// ----- The bar on top: tile and text size, Reset, Done -----

private _barW = SQUARE(UNIT * 24);
private _barH = UNIT * 1.5;
private _barX = (safezoneW - _barW) / 2;
private _barY = UNIT * 0.5;
private _padX = SQUARE(UNIT * 0.4);
private _buttonH = UNIT * 1;
private _buttonTop = _barY + (_barH - _buttonH) / 2;
private _buttonW = SQUARE(_buttonH);
private _radius = UNIT * 0.3;

private _buttonTheme = createHashMapFromArray [
    ["button", [1, 1, 1, 0.08]],
    ["buttonHover", [1, 1, 1, 0.18]],
    ["buttonText", _text2],
    ["font", _font],
    ["muted", [0.56, 0.56, 0.56, 1]],
    ["radius", _radius],
    ["upper", false]
];

[_display, _layer, [_barX, _barY, _barW, _barH], [0.015, 0.015, 0.015, 1], _radius] call FUNC(uiPanel);
[_display, "AIO_Hitbox", _layer, [_barX, _barY, _barW, _barH]] call FUNC(uiCreate);

private _cursor = _barX + _padX;

{
    private _index = _forEachIndex;
    private _value = [_index] call FUNC(sizeValue);
    private _nameW = SQUARE(UNIT * 2);
    private _shownW = SQUARE(UNIT * 2);

    [_display, _layer, [_cursor, _barY, _nameW, _barH], _x, _size * 0.9, _text2, _font, 0, "never"] call FUNC(uiLabel);

    _cursor = _cursor + _nameW;

    {
        _x params ["_icon", "_step"];

        [
            _display, _layer, [_cursor, _buttonTop, _buttonW, _buttonH], format ["layoutsize%1%2", _index, _forEachIndex], "", _icon, _buttonTheme,
            compile format ["if ((_this select 0) >= 0) then {['step', [%1, %2]] call %3};", _index, _step, QFUNC(layoutDrag)],
            false, -1, true
        ] call FUNC(uiButton);

        _cursor = _cursor + _buttonW;

        if (_forEachIndex == 0) then {
            [_display, _layer, [_cursor, _barY, _shownW, _barH], (str round (_value * 100)) + "%", _size * 0.9, _text, _font, 2, "never"] call FUNC(uiLabel);

            _cursor = _cursor + _shownW;
        };
    } forEach [[UI_TEX(icon_minus_ca), -SIZE_STEP], [UI_TEX(icon_plus_ca), SIZE_STEP]];

    _cursor = _cursor + _padX;
} forEach [LLSTRING(Size_Tiles), LLSTRING(Size_Text)];

private _doneW = ([LLSTRING(Layout_Done), "", _buttonH, _size * 0.85, _buttonTheme] call FUNC(buttonWidth));
private _resetW = ([LLSTRING(Layout_Reset), "", _buttonH, _size * 0.85, _buttonTheme] call FUNC(buttonWidth));
private _doneX = _barX + _barW - _padX - _doneW;
private _resetX = _doneX - _padX - _resetW;

[
    _display, _layer, [_resetX, _buttonTop, _resetW, _buttonH], "layoutreset", LLSTRING(Layout_Reset), "", _buttonTheme, {
        params ["_button"];

        if (_button < 0) exitWith {};

        ["reset"] call FUNC(layoutDrag);
    }, false, _size * 0.85, true
] call FUNC(uiButton);

[
    _display, _layer, [_doneX, _buttonTop, _doneW, _buttonH], "layoutdone", LLSTRING(Layout_Done), "", _buttonTheme, {
        params ["_button"];

        if (_button < 0) exitWith {};

        // Back to the card it was opened from.
        [{[uiNamespace getVariable [QGVAR(display), displayNull]] call FUNC(openSizeMenu)}] call FUNC(later);
    }, false, _size * 0.85, true
] call FUNC(uiButton);

// The focus into the layer, so it is drawn over everything: a button no one sees, one pixel in the bar.
private _focus = [_display, "AIO_Hitbox", _layer, [_barX + pixelW, _barY + pixelH, pixelW, pixelH]] call FUNC(uiCreate);

ctrlSetFocus _focus;

uiNamespace setVariable [QGVAR(menuFocus), [_layer, _focus]];
uiNamespace setVariable [QGVAR(menu), [_layer]];
uiNamespace setVariable [QGVAR(menuFocusBack), _back];
uiNamespace setVariable [QGVAR(menuRect), [safezoneX, safezoneY, safezoneW, safezoneH]];

GVAR(menuState) = ["layout"];
GVAR(menuFor) = ["layout", -1];
