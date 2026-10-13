#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Step 1, Start, as the wizard opens: what the mod and this setup are about, in four short cards, and one
 * button on into it - so the first look is not every choice at once.
 *   - What the mod does: items are tiles on grids, and the free cells alone decide what fits.
 *   - What a preset is: what every item and container is sized from; own rules go on top of it.
 *   - What the steps do: Items, Containers, Review.
 *   - Where it goes: where this wizard may save (fnc_canEdit's answer, GVAR(target)), or why it may not,
 *     and that it can be kept as a preset of one's own.
 * "Start setup" shows the Start step's choices instead (GVAR(startSetup), fnc_drawStart); "Review and save"
 * goes straight on to Review, when there are own rules to look at.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: The step's group <CONTROL>
 * 2: Theme <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, _group, _theme] call einv_setup_fnc_drawWelcome;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_group", "_theme"];

(ctrlPosition _group) params ["", "", "_width", "_height"];

private _font = _theme getOrDefault ["font", "PuristaMedium"];
private _fontBold = _theme getOrDefault ["fontBold", "PuristaSemibold"];
private _colorText = _theme getOrDefault ["text", [0.925, 0.933, 0.949, 1]];
private _colorText2 = _theme getOrDefault ["text2", [0.698, 0.734, 0.784, 1]];
private _muted = _theme getOrDefault ["muted", [0.522, 0.553, 0.604, 1]];
private _accent = _theme getOrDefault ["accent", [0.84, 0.54, 0.1, 1]];
private _cardFill = _theme getOrDefault ["card", [1, 1, 1, 0.055]];
private _radius = _theme getOrDefault ["radius", 0];

private _padX = WIZ_PAD_X;
private _innerW = _width - _padX * 2;
private _gapY = UNIT * 0.5;
private _gapX = SQUARE(_gapY);
private _cardW = (_innerW - _gapX) / 2;
private _cardH = UNIT * 4.6;
private _buttonH = UNIT * 1.6;

// Where Save puts it - or why it cannot.
private _target = GVAR(target);
private _whereKey = format ["STR_einv_setup_Welcome_Where_%1", _target getOrDefault ["source", ""]];
private _where = format [LLSTRING(Welcome_WhereReadOnly), _target getOrDefault ["reason", ""]];

if (!GVAR(readOnly) && {isLocalized _whereKey}) then {
    _where = localize _whereKey;
};

// Kept as a preset of one's own (Review) it goes anywhere - also for who may not save here.
_where = format ["%1 %2", _where, LLSTRING(Welcome_WhereOwn)];

private _cards = [
    [UI_TEX(icon_inventory_ca), LLSTRING(Welcome_GridTitle), LLSTRING(Welcome_GridText)],
    [UI_TEX(icon_star_ca), LLSTRING(Welcome_PresetTitle), LLSTRING(Welcome_PresetText)],
    [UI_TEX(icon_setup_ca), LLSTRING(Welcome_StepsTitle), LLSTRING(Welcome_StepsText)],
    [UI_TEX(icon_export_ca), LLSTRING(Welcome_WhereTitle), _where]
];

// All of it in the middle of the step, rather than at its top with half of it empty: the title and the
// line under it, two rows of cards, the buttons and the line under them.
private _blockH = UNIT * 1.4 + UNIT * 1.6 + 2 * _cardH + _gapY + UNIT * 1.0 + _buttonH + UNIT * 1.3;
private _cursorY = ((_height - _blockH) / 2) max (UNIT * 0.4);

// ----- Title -----

[_display, _group, [_padX, _cursorY, _innerW, UNIT * 1.3], LLSTRING(Welcome_Title), TEXT_TITLE, _colorText, _fontBold, 2] call EFUNC(gui,uiLabel);

_cursorY = _cursorY + UNIT * 1.4;

private _introW = _innerW * 0.75;

_cursorY = _cursorY + ([_display, _group, [_padX + (_innerW - _introW) / 2, _cursorY, _introW], LLSTRING(Welcome_Intro), TEXT_BODY, _colorText2, _font] call FUNC(uiText)) + UNIT * 0.8;

// ----- The cards -----

{
    _x params ["_icon", "_title", "_text"];

    private _left = _padX + (_forEachIndex mod 2) * (_cardW + _gapX);
    private _top = _cursorY + floor (_forEachIndex / 2) * (_cardH + _gapY);
    private _iconH = UNIT * 1.5;
    private _textX = _left + CARD_PAD_X + SQUARE(_iconH) + SQUARE(UNIT * 0.6);
    private _textW = _left + _cardW - CARD_PAD_X - _textX;

    [_display, _group, [_left, _top, _cardW, _cardH], _cardFill, _radius] call EFUNC(gui,uiPanel);
    [_display, _group, [_left + CARD_PAD_X, _top + CARD_PAD_Y + UNIT * 0.1, SQUARE(_iconH), _iconH], _icon, _accent] call EFUNC(gui,uiIcon);
    [_display, _group, [_textX, _top + CARD_PAD_Y, _textW, UNIT * 1], _title, TEXT_HEAD, _colorText, _fontBold, 0] call EFUNC(gui,uiLabel);
    [_display, _group, [_textX, _top + CARD_PAD_Y + UNIT * 1.1, _textW], _text, TEXT_BODY, _colorText2, _font] call FUNC(uiText);
} forEach _cards;

_cursorY = _cursorY + 2 * _cardH + _gapY + UNIT * 1.0;

// ----- Start setup, and Review and save when there is something to review -----

private _own = count (GVAR(draft) getOrDefault ["groups", []]) + count (GVAR(draft) getOrDefault ["rules", []]);
private _fnc_buttonW = {
    params ["_text"];

    // Kept off both edges, with room for the icon and the gap after it (fnc_uiAction).
    SQUARE(_buttonH * 1.6) + (_text getTextWidth [_font, _buttonH * 0.5]) * TEXT_SLACK
};

private _startW = [LLSTRING(Welcome_Start)] call _fnc_buttonW;
private _reviewW = [0, [LLSTRING(Start_ToReview)] call _fnc_buttonW] select (_own > 0);
private _buttonsW = _startW + ([0, _reviewW + SQUARE(UNIT * 0.4)] select (_reviewW > 0));
private _buttonX = _padX + (_innerW - _buttonsW) / 2;

[_display, _group, [_buttonX, _cursorY, _startW, _buttonH], LLSTRING(Welcome_Start), UI_TEX(icon_chevron_right_ca), _theme, {
    GVAR(startSetup) = true;

    [0] call FUNC(showStep);
}, [], true, "accent"] call FUNC(uiAction);

if (_reviewW > 0) then {
    [_display, _group, [_buttonX + _startW + SQUARE(UNIT * 0.4), _cursorY, _reviewW, _buttonH], LLSTRING(Start_ToReview), UI_TEX(icon_check_ca), _theme, {
        private _review = GVAR(steps) findIf {(_x select 0) isEqualTo "review"};

        [_review] call FUNC(showStep);
    }, [], true, "ghost"] call FUNC(uiAction);
};

_cursorY = _cursorY + _buttonH + UNIT * 0.4;

// What the draft builds on now, under the buttons.
[
    _display, _group, [_padX, _cursorY, _innerW, UNIT * 0.8],
    format [LLSTRING(Status_Active), [GVAR(draft) getOrDefault ["base", "default"]] call FUNC(presetName), _own], TEXT_SMALL, _muted, _font, 2
] call EFUNC(gui,uiLabel);
