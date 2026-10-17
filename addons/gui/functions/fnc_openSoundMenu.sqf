#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Opens the sound dropdown under the speaker in the header: a card with a row for each kind of sound
 * (fnc_soundGroup) - a switch, its name by what the player hears, a volume slider and the percentage - the
 * master volume at the bottom, and "Mute all" / "Unmute all" at the top. Turning a switch off sets its
 * volume to 0 and silences the kind; turning it on brings the volume back to what it was; dragging a slider up
 * from 0 turns the kind on (fnc_soundSet, fnc_soundSlide). Right-aligned under the speaker. Closes on a click
 * beside it, on Escape and on a click on the speaker again (which the hit area over the screen takes): what was
 * set is written to the profile then (fnc_soundSettle).
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
private _accent = _theme getOrDefault ["accent", [0.84, 0.54, 0.1, 1]];
private _line = _theme getOrDefault ["line", [1, 1, 1, 0.08]];

private _names = [LLSTRING(Sound_Moves), LLSTRING(Sound_Magazines), LLSTRING(Sound_Containers), LLSTRING(Sound_Search), LLSTRING(Sound_Other)];
private _count = count GVAR(soundGroups);

// ----- Sizes -----

private _size = UNIT * 0.66;
private _rowH = UNIT * 1.2;
private _headH = UNIT * 1.3;
private _masterH = UNIT * 1.4;
private _gapH = UNIT * 0.2;
private _padX = SQUARE(UNIT * 0.5);
private _padY = UNIT * 0.25;
private _width = SQUARE(UNIT * 16.5);
private _height = _padY * 2 + _headH + _count * _rowH + _gapH + _masterH;

private _boxH = UNIT * 0.8;
private _boxW = SQUARE(_boxH);
private _labelX = _padX + _boxW + SQUARE(UNIT * 0.45);
private _labelW = SQUARE(UNIT * 6.3);
private _sliderX = _labelX + _labelW + SQUARE(UNIT * 0.4);
private _percentW = SQUARE(UNIT * 1.8);
private _sliderW = _width - _padX - _percentW - _sliderX - SQUARE(UNIT * 0.2);
private _trackH = UNIT * 0.22;
private _thumbH = UNIT * 0.66;
private _thumbW = SQUARE(_thumbH);

// Right-aligned under the speaker, kept on the screen.
private _anchor = uiNamespace getVariable [QGVAR(soundAnchor), []];

if (_anchor isEqualTo []) then {
    _anchor = [safezoneX + safezoneW - MARGIN_X - SQUARE(HEAD_H), HEAD_Y, SQUARE(HEAD_H), HEAD_H];
};

private _left = (((_anchor select 0) + (_anchor select 2) - _width) min (safezoneX + safezoneW - _width)) max safezoneX;
private _top = (((_anchor select 1) + (_anchor select 3) + UNIT * 0.4) min (safezoneY + safezoneH - _height)) max safezoneY;
private _cardX = _left - safezoneX;
private _cardY = _top - safezoneY;

// ----- The layer, the hit area beside the card, the card -----

private _layer = [_display, "EINV_Group", controlNull, [safezoneX, safezoneY, safezoneW, safezoneH]] call FUNC(uiCreate);

// A group keeps the mouse's buttons from the display's own handlers: it reports them as the columns do (fnc_build)
// and so does the hit area over the screen in it (fnc_openMenu).
_layer setVariable [QGVAR(hooked), true];
_layer ctrlAddEventHandler ["MouseButtonDown", {[true, _this] call FUNC(onMouseButton); false}];
_layer ctrlAddEventHandler ["MouseButtonUp", {[false, _this] call FUNC(onMouseButton); false}];

private _catcher = [_display, "EINV_Hitbox", _layer, [0, 0, safezoneW, safezoneH]] call FUNC(uiCreate);
_catcher ctrlAddEventHandler ["MouseButtonDown", {[true, _this] call FUNC(onMouseButton); false}];
_catcher ctrlAddEventHandler ["MouseButtonUp", {[false, _this] call FUNC(onMouseButton); false}];
_catcher ctrlAddEventHandler ["ButtonClick", {[{call FUNC(closeMenu)}] call FUNC(later)}];

[
    _display, _layer, [_cardX, _cardY, _width, _height],
    _theme getOrDefault ["inspectBg", [0.06, 0.06, 0.06, 0.98]], _theme getOrDefault ["radius", 0]
] call FUNC(uiPanel);

// ----- The top: the title, and Mute all -----

private _headTop = _cardY + _padY;
private _allW = SQUARE(UNIT * 5);

[_display, _layer, [_cardX + _padX, _headTop, _width - _padX * 2 - _allW, _headH], LLSTRING(Sound_Title), _size * 1.05, _text2, _fontBold, 0] call FUNC(uiLabel);

private _allLabel = [_display, _layer, [_cardX + _width - _padX - _allW, _headTop, _allW, _headH], "", _size, _accent, _font, 1] call FUNC(uiLabel);

private _allHit = [
    _display, "EINV_Hitbox", _layer, [_cardX + _width - _padX - _allW - SQUARE(UNIT * 0.5), _headTop, _allW + SQUARE(UNIT * 1), _headH]
] call FUNC(uiCreate);
_allHit ctrlAddEventHandler ["ButtonClick", {["all"] call FUNC(soundSet)}];

[_display, _layer, [_cardX + _padX * 0.3, _headTop + _headH, _width - _padX * 0.6, pixelH], _line] call FUNC(uiPanel);

// ----- One slider with its percentage, and the hit area that drags it -----

private _fnc_slider = {
    params ["_index", "_rowTop", "_rowHeight"];

    private _trackY = _rowTop + (_rowHeight - _trackH) / 2;

    [_display, _layer, [_cardX + _sliderX, _trackY, _sliderW, _trackH], _theme getOrDefault ["barTrack", [1, 1, 1, 0.1]], _trackH / 2] call FUNC(uiPanel);

    private _fill = [_display, "EINV_PanelRect", _layer, [_cardX + _sliderX, _trackY, _sliderW, _trackH]] call FUNC(uiCreate);
    private _thumbTop = _rowTop + (_rowHeight - _thumbH) / 2;
    private _thumb = [_display, _layer, [_cardX + _sliderX, _thumbTop, _thumbW, _thumbH], UI_TEX(circle_ca), _text] call FUNC(uiIcon);

    private _percent = [
        _display, _layer, [_cardX + _width - _padX - _percentW, _rowTop, _percentW, _rowHeight], "", _size * 0.92, _text2, _font, 1
    ] call FUNC(uiLabel);

    private _hit = [
        _display, "EINV_Hitbox", _layer, [_cardX + _sliderX - _thumbW, _rowTop, _sliderW + _thumbW * 2, _rowHeight]
    ] call FUNC(uiCreate);

    _hit setVariable [QGVAR(slider), [_index, safezoneX + _cardX + _sliderX, _sliderW]];

    _hit ctrlAddEventHandler ["MouseButtonDown", {
        params ["_ctrl", "_button", "_mouseX"];

        if (_button != 0) exitWith {};

        (_ctrl getVariable [QGVAR(slider), []]) params ["_index", "_left", "_width"];

        ["begin", [ctrlParent _ctrl, _index, _left, _width, _mouseX]] call FUNC(soundSlide);
    }];

    // The slider's place relative to the layer, and the knob's, for fnc_updateSoundMenu.
    [_fill, _thumb, _percent, [_cardX + _sliderX, _trackY, _sliderW, _trackH, _thumbW, _thumbH, _thumbTop]]
};

// ----- A row for each kind of sound -----

private _rows = [];

{
    private _rowTop = _headTop + _headH + _forEachIndex * _rowH;

    // The row under the mouse is lit; the whole of it but the slider takes the switch's click.
    private _surface = [_display, "EINV_PanelRect", _layer, [_cardX + _padX * 0.3, _rowTop, _width - _padX * 0.6, _rowH]] call FUNC(uiCreate);
    _surface ctrlSetBackgroundColor [0, 0, 0, 0];

    private _boxTop = _rowTop + (_rowH - _boxH) / 2;
    private _box = [_display, _layer, [_cardX + _padX, _boxTop, _boxW, _boxH], [1, 1, 1, 0.16], UNIT * 0.2] call FUNC(uiPanel);
    private _inset = _boxH * 0.14;
    private _check = [
        _display, _layer, [_cardX + _padX + SQUARE(_inset), _boxTop + _inset, _boxW - SQUARE(_inset) * 2, _boxH - _inset * 2],
        UI_TEX(icon_check_ca), _theme getOrDefault ["onAccent", [0.05, 0.05, 0.05, 1]]
    ] call FUNC(uiIcon);

    private _label = [_display, _layer, [_cardX + _labelX, _rowTop, _labelW, _rowH], _names select _forEachIndex, _size, _text, _font, 0] call FUNC(uiLabel);

    ([_forEachIndex, _rowTop, _rowH] call _fnc_slider) params ["_fill", "_thumb", "_percent", "_geo"];

    private _toggle = [
        _display, "EINV_Hitbox", _layer, [_cardX + _padX * 0.3, _rowTop, _sliderX - _thumbW - _padX * 0.3, _rowH]
    ] call FUNC(uiCreate);

    _toggle setVariable [QGVAR(surface), _surface];
    _toggle setVariable [QGVAR(kind), _forEachIndex];
    _toggle ctrlAddEventHandler ["MouseEnter", {((_this select 0) getVariable [QGVAR(surface), controlNull]) ctrlSetBackgroundColor [1, 1, 1, 0.08]}];
    _toggle ctrlAddEventHandler ["MouseExit", {((_this select 0) getVariable [QGVAR(surface), controlNull]) ctrlSetBackgroundColor [0, 0, 0, 0]}];
    _toggle ctrlAddEventHandler ["ButtonClick", {["toggle", (_this select 0) getVariable [QGVAR(kind), -1]] call FUNC(soundSet)}];

    _rows pushBack [_forEachIndex, _box, _check, _label, _fill, _thumb, _percent, _geo];
} forEach GVAR(soundGroups);

// ----- The master volume -----

private _masterTop = _headTop + _headH + _count * _rowH + _gapH;

[_display, _layer, [_cardX + _padX * 0.3, _masterTop - _gapH / 2, _width - _padX * 0.6, pixelH], _line] call FUNC(uiPanel);

private _masterLabel = [
    _display, _layer, [_cardX + _padX, _masterTop, _sliderX - _padX - SQUARE(UNIT * 0.2), _masterH], LLSTRING(Sound_Master), _size, _text, _fontBold, 0
] call FUNC(uiLabel);

([-1, _masterTop, _masterH] call _fnc_slider) params ["_masterFill", "_masterThumb", "_masterPercent", "_masterGeo"];

_rows pushBack [-1, [], controlNull, _masterLabel, _masterFill, _masterThumb, _masterPercent, _masterGeo];

// The focus into the layer, so it is drawn over everything: a button no one sees, one pixel in the card's
// padding. Return and Space press nothing on it (fnc_openMenu).
private _focus = [_display, "EINV_Hitbox", _layer, [_cardX + _padX / 2, _cardY + _padY / 2, pixelW, pixelH]] call FUNC(uiCreate);
ctrlSetFocus _focus;

uiNamespace setVariable [QGVAR(menu), [_layer]];
uiNamespace setVariable [QGVAR(menuFocusBack), _back];
uiNamespace setVariable [QGVAR(menuRect), [_left, _top, _width, _height]];
uiNamespace setVariable [QGVAR(soundRows), [_allLabel, _rows]];

// What it shows, to make it again on top (fnc_raiseMenu); who it is for, so that closing it is known (fnc_closeMenu).
GVAR(menuState) = ["sound"];
GVAR(menuFor) = ["sound", -1];

[] call FUNC(updateSoundMenu);
[] call FUNC(updateSoundButton);
