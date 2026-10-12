#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Draws what stays around every step, anew each time a step is drawn (fnc_showStep):
 *   - the header: the title; where it saves and how many changes wait ("Server · forced · 4 changes", or
 *     "Read-only"); Undo, Redo and Close; under it the steps - the open one in the accent, a dot on a step
 *     with changes, the steps not built yet greyed out with "Coming in the next version"; then, after
 *     someone else changed the setup, a banner to reload or keep the own changes.
 *   - the footer: the keys on the left, the last message in the middle (fnc_setHint), Back, Next and Save
 *     on the right - Apply in CBA's menu, where CBA's own OK saves.
 * Each in a group of its own inside the wizard's pane, so the step between them never lies under either.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 *
 * Return Value:
 * Where the step goes, [x, y, w, h] in the pane <ARRAY>
 *
 * Example:
 * private _rect = [_display] call einv_setup_fnc_drawFrame;
 *
 * Public: No
 */

disableSerialization;

params ["_display"];

private _root = uiNamespace getVariable [QGVAR(root), controlNull];

{ctrlDelete _x} forEach (uiNamespace getVariable [QGVAR(frame), []]);

(ctrlPosition _root) params ["", "", "_width", "_height"];

private _theme = GVAR(theme);
private _font = _theme getOrDefault ["font", "PuristaMedium"];
private _fontBold = _theme getOrDefault ["fontBold", "PuristaSemibold"];
private _colorText = _theme getOrDefault ["text", [0.925, 0.933, 0.949, 1]];
private _colorText2 = _theme getOrDefault ["text2", [0.698, 0.734, 0.784, 1]];
private _accent = _theme getOrDefault ["accent", [0.84, 0.54, 0.1, 1]];
private _line = _theme getOrDefault ["line", [1, 1, 1, 0.09]];

private _padX = WIZ_PAD_X;
private _padY = WIZ_PAD_Y;
private _innerW = _width - _padX * 2;
private _stepsY = _padY + WIZ_TITLE_H + UNIT * 0.45;
private _lineY = _stepsY + WIZ_STEPS_H + UNIT * 0.5;
private _headerH = _lineY + UNIT * 0.05 + ([0, WIZ_BANNER_H + UNIT * 0.3] select GVAR(banner));

(call FUNC(countChanges)) params ["_changes", "_headChanged", "_statementsChanged"];

// ----- Header -----

private _header = [_display, "EINV_Group", _root, [0, 0, _width, _headerH]] call EFUNC(gui,uiCreate);
private _iconH = UNIT * 1.05;

[_display, _header, [_padX, _padY + (WIZ_TITLE_H - _iconH) / 2, SQUARE(_iconH), _iconH], ICON(icon_setup_ca,icon_inventory_ca), _accent] call EFUNC(gui,uiIcon);

private _titleX = _padX + SQUARE(_iconH * 1.4);
private _title = [LLSTRING(Title), _theme] call EFUNC(gui,caption);
private _titleW = (_title getTextWidth [_fontBold, TEXT_TITLE]) * TEXT_SLACK;

[_display, _header, [_titleX, _padY, _titleW, WIZ_TITLE_H], _title, TEXT_TITLE, _colorText, _fontBold, 0] call EFUNC(gui,uiLabel);

// From the right edge inwards: Close, Redo, Undo, then where it saves.
private _buttonH = UNIT * 1.25;
private _buttonY = _padY + (WIZ_TITLE_H - _buttonH) / 2;
private _nextRight = _width - _padX;

private _fnc_place = {
    params ["_buttonW"];

    _nextRight = _nextRight - _buttonW;

    private _rect = [_nextRight, _buttonY, _buttonW, _buttonH];
    _nextRight = _nextRight - SQUARE(UNIT * 0.25);

    _rect
};

[_display, _header, [SQUARE(_buttonH)] call _fnc_place, "", UI_TEX(icon_close_ca), _theme, {call FUNC(close)}, [], true, "ghost", LLSTRING(Close)] call FUNC(uiAction);

[
    _display, _header, [SQUARE(_buttonH)] call _fnc_place, "", ICON(icon_redo_ca,icon_chevrons_right_ca), _theme,
    {[-1] call FUNC(undo)}, [], GVAR(redo) isNotEqualTo [], "ghost", format ["%1 (%2)", LLSTRING(Redo), LLSTRING(Key_Redo)]
] call FUNC(uiAction);

[
    _display, _header, [SQUARE(_buttonH)] call _fnc_place, "", ICON(icon_undo_ca,icon_chevrons_left_ca), _theme,
    {[1] call FUNC(undo)}, [], GVAR(undo) isNotEqualTo [], "ghost", format ["%1 (%2)", LLSTRING(Undo), LLSTRING(Key_Undo)]
] call FUNC(uiAction);

// Where it saves, how firmly, and how much waits to be saved - or why it cannot save. Nothing changed but
// not stored there yet (fnc_sourceEmpty) says so: Save is there for it.
private _notStored = _changes == 0 && {!GVAR(readOnly)} && {GVAR(sourceEmpty)};
private _changesText = switch (true) do {
    case (_notStored): {LLSTRING(Chip_NotStored)};
    case (_changes == 0): {LLSTRING(Chip_NoChanges)};
    case (_changes == 1): {LLSTRING(Chip_OneChange)};
    default {format [LLSTRING(Chip_Changes), _changes]};
};

private _chipText = if (GVAR(readOnly)) then {
    format ["%1 · %2", LLSTRING(Chip_ReadOnly), _changesText]
} else {
    private _source = GVAR(target) getOrDefault ["source", ""];
    private _sourceName = localize format ["STR_einv_setup_Source_%1", _source];
    private _forced = [LLSTRING(Chip_Forced), LLSTRING(Chip_Override)] select (GVAR(override) && {GVAR(target) getOrDefault ["override", false]});

    if (GVAR(mode) isEqualTo "menu") then {
        _sourceName = format [LLSTRING(Chip_Menu), _sourceName];
    };

    format ["%1 · %2 · %3", _sourceName, _forced, _changesText]
};

private _chipH = UNIT * 0.95;
private _chipSize = _chipH * 0.6;
private _chipW = (_chipText getTextWidth [_font, _chipSize]) * TEXT_SLACK + SQUARE(_chipH);
private _chipRoom = _nextRight - (_titleX + _titleW + SQUARE(UNIT * 0.5));

_chipW = _chipW min _chipRoom;

if (_chipW > SQUARE(UNIT * 2)) then {
    private _chipRect = [_nextRight - _chipW, _padY + (WIZ_TITLE_H - _chipH) / 2, _chipW, _chipH];
    private _chipInk = [_colorText2, _theme getOrDefault ["accent", _colorText2]] select (_changes > 0 || {_notStored});

    [_display, _header, _chipRect, _theme getOrDefault ["button", [1, 1, 1, 0.08]], _chipH / 2] call EFUNC(gui,uiPanel);

    private _chip = [
        _display, _header, _chipRect, [_chipText, _chipW - SQUARE(_chipH * 0.6), _font, _chipSize] call EFUNC(gui,fitText), _chipSize,
        _chipInk, _font, 2
    ] call EFUNC(gui,uiLabel);

    _chip ctrlSetTooltip ([format [LLSTRING(Save_ReadOnly), GVAR(target) getOrDefault ["reason", ""]], _chipText] select !GVAR(readOnly));
};

// ----- The steps -----

private _steps = GVAR(steps);
private _gap = SQUARE(UNIT * 0.3);
private _pillW = (_innerW - _gap * (count _steps - 1)) / count _steps;

{
    _x params ["", "_nameKey", "_function"];

    private _available = !isNil {missionNamespace getVariable _function};
    private _current = _forEachIndex == GVAR(step);
    private _rect = [_padX + _forEachIndex * (_pillW + _gap), _stepsY, _pillW, WIZ_STEPS_H];
    private _label = format ["%1   %2", _forEachIndex + 1, localize _nameKey];
    private _tooltip = ["", LLSTRING(Step_Soon)] select !_available;

    // The open step in the accent; a click on it only draws it again.
    [
        _display, _header, _rect, _label, "", _theme, {
            params ["_step"];

            [_step] call FUNC(showStep);
        }, [_forEachIndex], _available, ["", "accent"] select _current, _tooltip
    ] call FUNC(uiAction);

    // A dot on a step holding changes: Start for the preset and the cell size, Review for the statements.
    private _changed = [false, _headChanged, false, false, _statementsChanged] param [_forEachIndex, false];

    if (_changed) then {
        private _dotH = WIZ_STEPS_H * 0.26;

        [
            _display, _header, [(_rect select 0) + _pillW - SQUARE(WIZ_STEPS_H * 0.5), _stepsY + (WIZ_STEPS_H - _dotH) / 2, SQUARE(_dotH), _dotH],
            UI_TEX(circle_ca), [_accent, _theme getOrDefault ["onAccent", [0.086, 0.094, 0.114, 1]]] select _current
        ] call EFUNC(gui,uiIcon);
    };
} forEach _steps;

[_display, _header, [_padX, _lineY, _innerW, pixelH], _line] call EFUNC(gui,uiPanel);

// ----- After someone else changed the setup -----

if (GVAR(banner)) then {
    private _bannerY = _lineY + UNIT * 0.3;
    private _bannerButtonH = UNIT * 1.05;
    private _bannerButtonW = SQUARE(UNIT * 5);

    [_display, _header, [_padX, _bannerY, _innerW, WIZ_BANNER_H], _theme getOrDefault ["accentSoft", [0.84, 0.54, 0.1, 0.2]], (_theme getOrDefault ["radius", 0]) min (WIZ_BANNER_H / 2)] call EFUNC(gui,uiPanel);

    private _textW = _innerW - CARD_PAD_X * 2 - _bannerButtonW * 2 - SQUARE(UNIT * 0.6);

    [
        _display, _header, [_padX + CARD_PAD_X, _bannerY, _textW, WIZ_BANNER_H],
        [LLSTRING(Banner_Changed), _textW, _font, TEXT_BODY] call EFUNC(gui,fitText), TEXT_BODY, _colorText, _font, 0
    ] call EFUNC(gui,uiLabel);

    private _buttonTop = _bannerY + (WIZ_BANNER_H - _bannerButtonH) / 2;
    private _keepX = _padX + _innerW - CARD_PAD_X - _bannerButtonW;

    [_display, _header, [_keepX, _buttonTop, _bannerButtonW, _bannerButtonH], LLSTRING(Banner_Keep), "", _theme, {
        GVAR(banner) = false;
        [GVAR(step)] call FUNC(showStep);
    }] call FUNC(uiAction);

    [_display, _header, [_keepX - SQUARE(UNIT * 0.3) - _bannerButtonW, _buttonTop, _bannerButtonW, _bannerButtonH], LLSTRING(Banner_Reload), "", _theme, {
        call FUNC(reload);
        [GVAR(step)] call FUNC(showStep);
    }, [], true, "accent"] call FUNC(uiAction);
};

// ----- Footer -----

private _footer = [_display, "EINV_Group", _root, [0, _height - WIZ_FOOT_H, _width, WIZ_FOOT_H]] call EFUNC(gui,uiCreate);
private _rowH = UNIT * 1.25;
private _rowY = (WIZ_FOOT_H - _rowH) / 2;
private _keyH = UNIT * 0.9;

[_display, _footer, [_padX, 0, _innerW, pixelH], _line] call EFUNC(gui,uiPanel);

// The keys, from the left.
private _keyX = _padX;

{
    _x params ["_key", "_text"];

    private _taken = [_display, _footer, [_keyX, _rowY + (_rowH - _keyH) / 2], _key, _text, _theme, _keyH] call EFUNC(gui,uiKeyHint);

    if (isNil "_taken") then {
        _taken = 0;
    };

    _keyX = _keyX + _taken;
} forEach [
    [LLSTRING(Key_Escape), LLSTRING(Close)],
    [LLSTRING(Key_Undo), LLSTRING(Undo)],
    [LLSTRING(Key_Redo), LLSTRING(Redo)]
];

// Save, Next and Back, from the right edge inwards. Back and Next skip the steps not built yet.
private _available = _steps apply {!isNil {missionNamespace getVariable (_x select 2)}};
private _back = -1;
private _next = -1;

for "_index" from (GVAR(step) - 1) to 0 step -1 do {
    if (_available select _index) exitWith {
        _back = _index;
    };
};

for "_index" from (GVAR(step) + 1) to (count _steps - 1) do {
    if (_available select _index) exitWith {
        _next = _index;
    };
};

private _fnc_buttonW = {
    params ["_text"];

    (SQUARE(UNIT * 4.5)) max (SQUARE(_rowH * 1.4) + (_text getTextWidth [_font, _rowH * 0.5]) * TEXT_SLACK)
};

private _right = _width - _padX;
private _saveLabel = [LLSTRING(Save), LLSTRING(Apply)] select (GVAR(mode) isEqualTo "menu");
private _saveW = [_saveLabel] call _fnc_buttonW;
private _canSave = !GVAR(readOnly) && {(call FUNC(isDirty)) || {GVAR(sourceEmpty)}};
private _saveTooltip = [
    [LLSTRING(Save_NothingYet), LLSTRING(Save_Tooltip)] select _canSave,
    format [LLSTRING(Save_ReadOnly), GVAR(target) getOrDefault ["reason", ""]]
] select GVAR(readOnly);

_right = _right - _saveW;

[_display, _footer, [_right, _rowY, _saveW, _rowH], _saveLabel, "", _theme, {[] call FUNC(save)}, [], _canSave, "accent", _saveTooltip] call FUNC(uiAction);

private _nextW = [LLSTRING(Next)] call _fnc_buttonW;
_right = _right - SQUARE(UNIT * 0.3) - _nextW;

[_display, _footer, [_right, _rowY, _nextW, _rowH], LLSTRING(Next), "", _theme, {
    params ["_step"];

    [_step] call FUNC(showStep);
}, [_next], _next >= 0] call FUNC(uiAction);

private _backW = [LLSTRING(Back)] call _fnc_buttonW;
_right = _right - SQUARE(UNIT * 0.3) - _backW;

[_display, _footer, [_right, _rowY, _backW, _rowH], LLSTRING(Back), "", _theme, {
    params ["_step"];

    [_step] call FUNC(showStep);
}, [_back], _back >= 0] call FUNC(uiAction);

// The last message, between the keys and the buttons.
private _hintX = _keyX + SQUARE(UNIT * 0.4);
private _hintW = _right - SQUARE(UNIT * 0.6) - _hintX;

GVAR(hint) params [["_hintText", ""], ["_hintColor", "text2"]];

private _hint = [_display, _footer, [_hintX, _rowY, _hintW max 0, _rowH], "", TEXT_SMALL, _colorText2, _font, 2] call EFUNC(gui,uiLabel);

uiNamespace setVariable [QGVAR(hintCtrl), _hint];
uiNamespace setVariable [QGVAR(frame), [_header, _footer]];

[_hintText, _hintColor] call FUNC(setHint);

[0, _headerH, _width, _height - _headerH - WIZ_FOOT_H]
