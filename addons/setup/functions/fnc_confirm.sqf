#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Asks before something that cannot simply be taken back - closing with changes not saved, resetting,
 * deleting a preset, saving over someone else's save: a card in the middle of the wizard (the wizard's own
 * middle, over the dimmed window), its question centred in it and its answers in a row along the bottom,
 * right-aligned with the same gap between them, the answer that does it last on the right - in the accent
 * colour unless it says otherwise. The card is as wide as the answers need, at least as wide as the question
 * reads well, so the row fills it and the padding is the same on both sides. Any other answer than the one
 * that does nothing (first on the left) can be added; Escape, or a click beside the card, is that first one.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Question <STRING>
 * 2: Label of the answer that does it <STRING>
 * 3: Code of that answer, called with the arguments as _this <CODE>
 * 4: Arguments <ANY> (default: [])
 * 5: Label of the answer that does nothing <STRING> (default: "Cancel")
 * 6: Other answers, [[label, code, style], ...] - called with the same arguments; the style is "", "accent",
 *    "ghost" or "danger" (the loss colour), "" when left out <ARRAY> (default: [])
 * 7: A title above the question, in bold; "" for none <STRING> (default: "")
 * 8: Style of the answer that does it <STRING> (default: "accent")
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, "Close without saving?", "Close", {closeDialog 2}] call einv_setup_fnc_confirm;
 *
 * Public: No
 */

disableSerialization;

params [
    "_display", ["_text", "", [""]], ["_yesLabel", "", [""]], ["_code", {}, [{}]], ["_arguments", []], ["_noLabel", "", [""]], ["_others", [], [[]]],
    ["_title", "", [""]], ["_yesStyle", "accent", [""]]
];

if (_noLabel isEqualTo "") then {
    _noLabel = LLSTRING(Cancel);
};

private _theme = GVAR(theme);
private _font = _theme getOrDefault ["font", "PuristaMedium"];
private _fontBold = _theme getOrDefault ["fontBold", "PuristaSemibold"];
private _buttonH = UNIT * 1.2;
private _gap = SQUARE(UNIT * 0.3);

// Every answer as [label, code, style], the one that does nothing first.
private _answers = [[_noLabel, {}, ""]];
_answers append (_others apply {[_x select 0, _x select 1, _x param [2, ""]]});
_answers pushBack [_yesLabel, _code, _yesStyle];

// As wide as the question reads well, wider when the answers need it.
private _buttonWidths = _answers apply {SQUARE(_buttonH * 1.2) + ((_x select 0) getTextWidth [_font, _buttonH * 0.5]) * TEXT_SLACK};
private _buttonsW = 0;

{_buttonsW = _buttonsW + _x + _gap} forEach _buttonWidths;

private _width = (SQUARE(UNIT * 20)) max (_buttonsW - _gap);

// The words, centred: a title in bold, the question under it.
private _color = [_theme getOrDefault ["text", [1, 1, 1, 1]]] call FUNC(hex);
private _markup = format ["<t align='center' font='%1' color='%2' size='%3'>%4</t>", _font, _color, TEXT_BODY / STRUCTURED_SIZE, [_text] call FUNC(escape)];

if (_title isNotEqualTo "") then {
    _markup = format [
        "<t align='center' font='%1' color='%2' size='%3'>%4</t><br/><t size='0.4'> </t><br/>",
        _fontBold, _color, TEXT_HEAD / STRUCTURED_SIZE, [_title] call FUNC(escape)
    ] + ([_markup, ""] select (_text isEqualTo ""));
};

// Measured in a box of that width before the card is made, so the card is as high as the words.
private _probe = _display ctrlCreate ["EINV_StructuredText", -1];
_probe ctrlSetPosition [safezoneX, safezoneY, _width, UNIT * 10];
_probe ctrlCommit 0;
_probe ctrlSetStructuredText parseText _markup;
private _textH = ceil ((ctrlTextHeight _probe) / pixelH) * pixelH;
ctrlDelete _probe;

[_display, [], [_width, _textH + UNIT * 0.8 + _buttonH], "", {
    params ["_display", "_inner", "_theme", "_arguments"];
    _arguments params ["_markup", "_textH", "_answers", "_buttonWidths", "_gap", "_buttonH", "_payload"];

    (ctrlPosition _inner) params ["", "", "_width", "_height"];

    private _words = [_display, "EINV_StructuredText", _inner, [0, 0, _width, _textH]] call EFUNC(gui,uiCreate);

    _words ctrlSetStructuredText parseText _markup;

    // From the right edge: the answer that does it last in the list, first from the right.
    private _right = _width;

    for "_index" from (count _answers - 1) to 0 step -1 do {
        (_answers select _index) params ["_label", "_code", "_style"];

        private _buttonW = _buttonWidths select _index;
        _right = _right - _buttonW;

        [_display, _inner, [_right, _height - _buttonH, _buttonW, _buttonH], _label, "", _theme, {
            params ["_code", "_payload"];

            call FUNC(closePopover);
            _payload call _code;
        }, [_code, _payload], true, _style] call FUNC(uiAction);

        _right = _right - _gap;
    };
}, [_markup, _textH, _answers, _buttonWidths, _gap, _buttonH, _arguments], [WIZ_X + WIZ_W / 2, WIZ_Y + WIZ_H / 2]] call FUNC(popover);
