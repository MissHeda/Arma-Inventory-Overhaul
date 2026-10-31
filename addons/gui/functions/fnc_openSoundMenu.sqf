#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Opens the sound dropdown under the speaker in the header: a small card with a row for each kind of sound
 * (fnc_soundGroup) - a switch, its name by what the player hears, a volume slider and the percentage. There is no
 * master volume and no "Mute all" in it (a right click on the speaker still mutes everything or brings it back).
 * Turning a switch off sets its volume to 0 and silences the kind; turning it on brings the volume back to what it
 * was; dragging a slider up from 0 turns the kind on (fnc_soundSet, fnc_soundSlide).
 *
 * The card is darker than the panels behind it, with a one-pixel border and a soft shadow, and neutral: white and
 * grey switches, tracks and fills, no accent. It is right-aligned to the window's right edge - the right edge of the header,
 * flush with the Close button (Mia, 0.5.7) -, a small gap under the header's line, so it never lies over the header. Its
 * inside has one rhythm: the same padding on the left and the right, the same gap between the switch, the name, the slider and
 * the percentage, a row's light round the whole row and a track that ends where the knob's middle does. Closes on a click beside it,
 * on Escape and on a click on the speaker again (which the hit area over the screen takes): what was set is written to the
 * profile then (fnc_soundSettle).
 *
 * It is the context menu's layer (fnc_openMenu): one controls group over the screen, made last, with the focus
 * taken into it, kept in einv_gui_menu so that Escape (fnc_onKeyDown), a click beside it (fnc_onMouseButton), a
 * rebuild (fnc_build) and fnc_raiseMenu treat it as they treat a menu; einv_gui_menuFor says "sound", and
 * fnc_closeMenu tells fnc_soundSettle when it closes it. What lies in it is kept in einv_gui_soundRows, to be
 * shown in place (fnc_updateSoundMenu).
 *
 * Arguments:
 * 0: Display <DISPLAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display] call einv_gui_fnc_openSoundMenu;
 *
 * Public: No
 */

disableSerialization;

params ["_display"];

// A field that had the cursor before the menu took the focus, to have it back when the menu goes (fnc_openMenu).
private _back = if ((uiNamespace getVariable [QGVAR(menu), []]) isEqualTo []) then {
    private _focused = focusedCtrl _display;

    [controlNull, _focused] select (!isNull _focused && {ctrlType _focused == 2})
} else {
    uiNamespace getVariable [QGVAR(menuFocusBack), controlNull]
};

call FUNC(closeMenu);

// The name at the mouse would sit under it - and so would the comparison card (fnc_drawCompare).
(uiNamespace getVariable [QGVAR(tooltip), controlNull]) ctrlShow false;
ctrlDelete (uiNamespace getVariable [QGVAR(compare), controlNull]);
uiNamespace setVariable [QGVAR(compare), controlNull];
uiNamespace setVariable [QGVAR(tipShown), controlNull];

private _theme = GVAR(theme);
private _font = _theme getOrDefault ["font", "PuristaMedium"];
private _fontBold = _theme getOrDefault ["fontBold", _font];
private _text = _theme getOrDefault ["text", [1, 1, 1, 1]];
private _text2 = _theme getOrDefault ["text2", [0.78, 0.78, 0.78, 1]];
private _line = _theme getOrDefault ["line", [1, 1, 1, 0.08]];
private _radius = (_theme getOrDefault ["radius", 0]) * 0.7;

// Neutral greys: the dropdown wears no accent. The card is darker than the panels (0.05) behind it.
private _cardColor = [0.015, 0.015, 0.015, 1];
private _borderColor = [0.27, 0.27, 0.27, 1];

private _names = [LLSTRING(Sound_Moves), LLSTRING(Sound_Magazines), LLSTRING(Sound_Containers), LLSTRING(Sound_Search), LLSTRING(Sound_Other)];
private _count = count GVAR(soundGroups);

// ----- Sizes -----

private _size = UNIT * 0.55;
private _rowH = UNIT * 1;
private _headH = UNIT * 1.1;
private _padX = SQUARE(UNIT * 0.6);
private _padY = UNIT * 0.35;
private _gapX = SQUARE(UNIT * 0.45);
private _width = SQUARE(UNIT * 14);
private _height = _padY * 2 + _headH + _count * _rowH;

// Left to right: padding, switch, gap, name, gap, slider, gap, percentage, padding.
private _boxH = UNIT * 0.58;
private _boxW = SQUARE(_boxH);
private _labelX = _padX + _boxW + _gapX;
private _labelW = SQUARE(UNIT * 4.6);
private _sliderX = _labelX + _labelW + _gapX;
private _percentW = SQUARE(UNIT * 1.6);
private _sliderW = _width - _padX - _percentW - _gapX - _sliderX;
private _trackH = UNIT * 0.2;
private _thumbH = UNIT * 0.55;
private _thumbW = SQUARE(_thumbH);

// The track runs between the knob's middle at 0 and at full: the knob stays inside the slider's room at both ends.
private _trackX = _sliderX + _thumbW / 2;
private _trackW = _sliderW - _thumbW;

// The right edge of the window - the header's, where the Close button ends - and a small gap under the header's line, kept on the screen.
private _left = ((CONTENT_X + CONTENT_W - _width) min (safezoneX + safezoneW - _width)) max safezoneX;
private _top = ((HEAD_Y + HEAD_H + UNIT * 0.5) max (safezoneY + UNIT * 2.6 + pixelH * 3)) min (safezoneY + safezoneH - _height);
private _cardX = _left - safezoneX;
private _cardY = _top - safezoneY;

// ----- The layer, the hit area beside the card, the card -----

private _layer = [_display, "EINV_Group", controlNull, [safezoneX, safezoneY, safezoneW, safezoneH]] call FUNC(uiCreate);

// Settings, not the inventory: no word in it takes the gradient (fnc_uiLabel).
_layer setVariable [QGVAR(plain), true];

// A group keeps the mouse's buttons from the display's own handlers: it reports them as the columns do (fnc_build)
// and so does the hit area over the screen in it (fnc_openMenu).
_layer setVariable [QGVAR(hooked), true];
_layer ctrlAddEventHandler ["MouseButtonDown", {[true, _this] call FUNC(onMouseButton); false}];
_layer ctrlAddEventHandler ["MouseButtonUp", {[false, _this] call FUNC(onMouseButton); false}];

private _catcher = [_display, "EINV_Hitbox", _layer, [0, 0, safezoneW, safezoneH]] call FUNC(uiCreate);
_catcher ctrlAddEventHandler ["MouseButtonDown", {[true, _this] call FUNC(onMouseButton); false}];
_catcher ctrlAddEventHandler ["MouseButtonUp", {[false, _this] call FUNC(onMouseButton); false}];
_catcher ctrlAddEventHandler ["ButtonClick", {[{call FUNC(closeMenu)}] call FUNC(later)}];

// The shadow (a faint dark panel a few pixels lower), the border (the card's size in the border's colour) and the
// card one pixel in from it.
[_display, _layer, [_cardX, _cardY + pixelH * 3, _width, _height], [0, 0, 0, 0.35], _radius] call FUNC(uiPanel);
[_display, _layer, [_cardX, _cardY, _width, _height], _borderColor, _radius] call FUNC(uiPanel);
[
    _display, _layer, [_cardX + pixelW, _cardY + pixelH, _width - pixelW * 2, _height - pixelH * 2], _cardColor, (_radius - pixelH) max 0
] call FUNC(uiPanel);

// ----- The top: the title -----

private _headTop = _cardY + _padY;

[_display, _layer, [_cardX + _padX, _headTop, _width - _padX * 2, _headH], LLSTRING(Sound_Title), _size, _text2, _fontBold, 0, "menu"] call FUNC(uiLabel);

[_display, _layer, [_cardX + _padX, _headTop + _headH - pixelH, _width - _padX * 2, pixelH], _line] call FUNC(uiPanel);

// ----- One slider with its percentage, and the hit area that drags it -----

private _fnc_slider = {
    params ["_index", "_rowTop", "_rowHeight"];

    private _trackY = _rowTop + (_rowHeight - _trackH) / 2;

    [_display, _layer, [_cardX + _trackX, _trackY, _trackW, _trackH], [1, 1, 1, 0.12], _trackH / 2] call FUNC(uiPanel);

    private _fill = [_display, "EINV_PanelRect", _layer, [_cardX + _trackX, _trackY, _trackW, _trackH]] call FUNC(uiCreate);
    private _thumbTop = _rowTop + (_rowHeight - _thumbH) / 2;
    private _thumb = [_display, _layer, [_cardX + _trackX - _thumbW / 2, _thumbTop, _thumbW, _thumbH], UI_TEX(circle_ca), _text] call FUNC(uiIcon);

    private _percent = [
        _display, _layer, [_cardX + _width - _padX - _percentW, _rowTop, _percentW, _rowHeight], "", _size * 0.9, _text2, _font, 1, "menu"
    ] call FUNC(uiLabel);

    // The hit area is the slider's whole room, a knob's width beyond the track at each end: a press near an end is that end. The
    // track's place on the screen goes with it, for the mouse's place along it (fnc_soundSlide).
    private _hit = [
        _display, "EINV_Hitbox", _layer, [_cardX + _sliderX, _rowTop, _sliderW, _rowHeight]
    ] call FUNC(uiCreate);

    _hit setVariable [QGVAR(slider), [_index, safezoneX + _cardX + _trackX, _trackW]];

    _hit ctrlAddEventHandler ["MouseButtonDown", {
        params ["_ctrl", "_button"];

        if (_button != 0) exitWith {};

        (_ctrl getVariable [QGVAR(slider), []]) params ["_index", "_left", "_width"];

        ["begin", [ctrlParent _ctrl, _index, _left, _width]] call FUNC(soundSlide);
    }];

    // The track's place relative to the layer, and the knob's, for fnc_updateSoundMenu.
    [_fill, _thumb, _percent, [_cardX + _trackX, _trackY, _trackW, _trackH, _thumbW, _thumbH, _thumbTop]]
};

// ----- A row for each kind of sound -----

private _rows = [];

{
    private _rowTop = _headTop + _headH + _forEachIndex * _rowH;

    // The row under the mouse is lit, a round film in from the card's edge by half the padding; the whole of it but the slider takes
    // the switch's click.
    private _rowInset = _padX / 2;
    private _surface = [
        _display, _layer, [_cardX + _rowInset, _rowTop, _width - _rowInset * 2, _rowH], [0, 0, 0, 0], (_radius * 0.6) min (_rowH / 2)
    ] call FUNC(uiPanel);

    private _boxTop = _rowTop + (_rowH - _boxH) / 2;
    private _box = [_display, _layer, [_cardX + _padX, _boxTop, _boxW, _boxH], [1, 1, 1, 0.14], UNIT * 0.15] call FUNC(uiPanel);
    private _inset = _boxH * 0.14;
    private _check = [
        _display, _layer, [_cardX + _padX + SQUARE(_inset), _boxTop + _inset, _boxW - SQUARE(_inset) * 2, _boxH - _inset * 2],
        UI_TEX(icon_check_ca), _theme getOrDefault ["onAccent", [0.05, 0.05, 0.05, 1]]
    ] call FUNC(uiIcon);

    private _label = [
        _display, _layer, [_cardX + _labelX, _rowTop, _labelW, _rowH], [_names select _forEachIndex, _labelW, _font, _size] call FUNC(fitText), _size, _text, _font, 0, "never"
    ] call FUNC(uiLabel);

    ([_forEachIndex, _rowTop, _rowH] call _fnc_slider) params ["_fill", "_thumb", "_percent", "_geo"];

    private _toggle = [
        _display, "EINV_Hitbox", _layer, [_cardX + _rowInset, _rowTop, _sliderX - _rowInset, _rowH]
    ] call FUNC(uiCreate);

    _toggle setVariable [QGVAR(surface), _surface];
    _toggle setVariable [QGVAR(kind), _forEachIndex];
    _toggle ctrlAddEventHandler ["MouseEnter", {[(_this select 0) getVariable [QGVAR(surface), []], [1, 1, 1, 0.06]] call FUNC(paintSurface)}];
    _toggle ctrlAddEventHandler ["MouseExit", {[(_this select 0) getVariable [QGVAR(surface), []], [0, 0, 0, 0]] call FUNC(paintSurface)}];
    _toggle ctrlAddEventHandler ["ButtonClick", {["toggle", (_this select 0) getVariable [QGVAR(kind), -1]] call FUNC(soundSet)}];

    _rows pushBack [_forEachIndex, _box, _check, _label, _fill, _thumb, _percent, _geo];
} forEach GVAR(soundGroups);

// The focus into the layer, so it is drawn over everything: a button no one sees, one pixel in the card's
// padding. Return and Space press nothing on it (fnc_openMenu).
private _focus = [_display, "EINV_Hitbox", _layer, [_cardX + _padX / 2, _cardY + _padY / 2, pixelW, pixelH]] call FUNC(uiCreate);
ctrlSetFocus _focus;

uiNamespace setVariable [QGVAR(menu), [_layer]];
uiNamespace setVariable [QGVAR(menuFocusBack), _back];
uiNamespace setVariable [QGVAR(menuRect), [_left, _top, _width, _height]];
uiNamespace setVariable [QGVAR(soundRows), _rows];

// What it shows, to make it again on top (fnc_raiseMenu); who it is for, so that closing it is known (fnc_closeMenu).
GVAR(menuState) = ["sound"];
GVAR(menuFor) = ["sound", -1];

[] call FUNC(updateSoundMenu);
[] call FUNC(updateSoundButton);
