#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The header (the "header" hook): the Arsenal's title and the name of the box, the search field, the button
 * for ACE's own window, the buttons that hide the panels and change the view (normal, night vision,
 * thermal) and the close button - in the Eden editor Cancel and Apply instead of the close button. Each place on the right lies on a piece of the window's glass, as the inventory's header does
 * (einv_gui_fnc_drawHeader); the line under it is the same.
 *
 * Left: the Arsenal's icon in the accent colour, "Arsenal", and in muted text what it is the arsenal of -
 * the box's name, "Full arsenal" when the session ignores the box's list, "Virtual Arsenal" for a vanilla
 * box -, then "Editing <name>" when the unit dressed is not the player (Zeus, the editor, a script's other
 * unit). The text gives way to the buttons: it is cut where they begin.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Theme <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, _theme] call einv_arsenal_fnc_drawHeader;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_theme"];

private _font = _theme getOrDefault ["font", "RobotoCondensed"];
private _fontBold = _theme getOrDefault ["fontBold", "RobotoCondensedBold"];
private _gap = SQUARE(UNIT * 0.3);
private _square = SQUARE(HEAD_H);

// Room for the icon, the gaps and the label the way fnc_uiButton lays them out, and some slack on the label.
private _fnc_buttonW = {
    params ["_text"];

    private _caption = [_text, _theme] call EFUNC(gui,caption);

    SQUARE(HEAD_H * 1.4) + (_caption getTextWidth [_font, HEAD_H * 0.48]) * 1.15
};

private _nextRight = CONTENT_X + CONTENT_W;

// A place for something on the right, on its own piece of glass; the next one lies left of it.
private _fnc_place = {
    params ["_width"];

    private _rect = [_nextRight - _width, HEAD_Y, _width, HEAD_H];
    _nextRight = _nextRight - _width - _gap;

    [_display, controlNull, _rect, _theme getOrDefault ["panel", []], (_theme getOrDefault ["radius", 0]) min (HEAD_H / 2)] call EFUNC(gui,uiPanel);

    _rect
};

// The hit area is the last of a button's controls.
private _fnc_tooltip = {
    params ["_controls", "_text"];

    if (_controls isNotEqualTo []) then {
        (_controls select -1) ctrlSetTooltip _text;
    };
};

// ----- Buttons, from the right edge inwards -----

if (is3DEN) then {
    // Apply puts the copy's loadout on the selected units, Cancel leaves them as they are.
    private _applyTheme = createHashMap;
    _applyTheme merge _theme;
    _applyTheme set ["buttonText", _theme get "accent"];

    private _apply = [
        _display, controlNull, [[LLSTRING(Button_Apply)] call _fnc_buttonW] call _fnc_place, "apply", LLSTRING(Button_Apply), "", _applyTheme,
        {[1] call FUNC(close)}
    ] call EFUNC(gui,uiButton);
    [_apply, LLSTRING(Button_Apply_Tooltip)] call _fnc_tooltip;

    private _cancel = [
        _display, controlNull, [[LLSTRING(Button_Cancel)] call _fnc_buttonW] call _fnc_place, "cancel", LLSTRING(Button_Cancel), "", _theme,
        {[2] call FUNC(close)}
    ] call EFUNC(gui,uiButton);
    [_cancel, LLSTRING(Button_Cancel_Tooltip)] call _fnc_tooltip;
} else {
    private _close = [
        _display, controlNull, [_square] call _fnc_place, "close", "", UI_TEX(icon_close_ca), _theme,
        {[2] call FUNC(close)}
    ] call EFUNC(gui,uiButton);
    [_close, LELSTRING(gui,Close)] call _fnc_tooltip;
};

// The search field: the catalog, and the soldier's own tiles fade for what does not match.
[_display, [SQUARE(UNIT * 11)] call _fnc_place, _theme, LLSTRING(Filter_Placeholder)] call EFUNC(gui,drawFilter);

// ACE's own window shows what a box holds; a vanilla box's cargo it cannot show.
if !(GVAR(source) isEqualTo "bi" && {!GVAR(full)}) then {
    private _ace = [
        _display, controlNull, [[LLSTRING(Button_AceArsenal)] call _fnc_buttonW] call _fnc_place, "ace", LLSTRING(Button_AceArsenal), "", _theme,
        {call FUNC(openAce)}
    ] call EFUNC(gui,uiButton);
    [_ace, LLSTRING(Button_AceArsenal_Tooltip)] call _fnc_tooltip;
};

// Hide: every panel goes and the soldier has the screen (Backspace does the same).
private _hide = [
    _display, controlNull, [_square] call _fnc_place, "hide", "", ICON(icon_eye_ca,icon_search_ca), _theme,
    {call FUNC(toggleHidden)}
] call EFUNC(gui,uiButton);
[_hide, LLSTRING(Button_Hide_Tooltip)] call _fnc_tooltip;

// The view the soldier is seen through: normal, night vision, thermal (the game's night vision key does the same).
private _vision = [
    _display, controlNull, [_square] call _fnc_place, "vision", "", ICON(icon_vision_ca,icon_search_ca), _theme,
    {[] call FUNC(cycleVision)}
] call EFUNC(gui,uiButton);
[_vision, LLSTRING(Button_Vision_Tooltip)] call _fnc_tooltip;

// ----- Title -----

private _iconH = UNIT * 1.1;
private _left = CONTENT_X;

[_display, controlNull, [_left, HEAD_Y + (HEAD_H - _iconH) / 2, SQUARE(_iconH), _iconH], UI_TEX(icon_arsenal_ca), _theme get "accent"] call EFUNC(gui,uiIcon);

private _titleSize = UNIT * 0.95;
private _title = [LLSTRING(Title), _theme] call EFUNC(gui,caption);
private _titleX = _left + SQUARE(_iconH * 1.4);
private _titleW = (_title getTextWidth [_fontBold, _titleSize]) * TEXT_SLACK;

[_display, controlNull, [_titleX, HEAD_Y, _titleW, HEAD_H], _title, _titleSize, _theme get "text", _fontBold, 0] call EFUNC(gui,uiLabel);

// What it is the arsenal of.
private _of = if (GVAR(full)) then {
    LLSTRING(Title_Full)
} else {
    if (GVAR(source) isEqualTo "bi") then {
        LLSTRING(Title_Vanilla)
    } else {
        private _name = getText (configOf GVAR(box) >> "displayName");

        [_name, typeOf GVAR(box)] select (_name isEqualTo "")
    }
};

private _unit = [GVAR(center), GVAR(edenOrigin)] select (is3DEN && {!isNull GVAR(edenOrigin)});
private _text = format ["· %1", _of];

if (!isNull _unit && {_unit isNotEqualTo player}) then {
    _text = format ["%1 · %2", _text, format [LLSTRING(Editing), [_unit] call ACEFUNC(common,getName)]];
};

private _textX = _titleX + _titleW + SQUARE(UNIT * 0.4);
private _textW = (_nextRight - _textX) max 0;
private _size = UNIT * 0.62;

[
    _display, controlNull, [_textX, HEAD_Y, _textW, HEAD_H],
    [_text, _textW, _font, _size] call EFUNC(gui,fitText), _size, _theme get "muted", _font, 0
] call EFUNC(gui,uiLabel);

// ----- Under the header -----

[_display, controlNull, [CONTENT_X, safezoneY + UNIT * 2.6, CONTENT_W, pixelH], _theme get "line"] call EFUNC(gui,uiPanel);
