#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Asks before something that cannot simply be taken back - closing with changes not saved, resetting,
 * deleting a preset, saving over someone else's save: a question in the middle of the screen with its
 * buttons along the bottom, the answer that does it on the right in the accent colour. Any other answer
 * than Cancel can be added.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Question <STRING>
 * 2: Label of the answer that does it <STRING>
 * 3: Code of that answer, called with the arguments as _this <CODE>
 * 4: Arguments <ANY> (default: [])
 * 5: Label of the answer that does nothing <STRING> (default: "Cancel")
 * 6: Other answers, [[label, code], ...] - called with the same arguments <ARRAY> (default: [])
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

params ["_display", ["_text", "", [""]], ["_yesLabel", "", [""]], ["_code", {}, [{}]], ["_arguments", []], ["_noLabel", "", [""]], ["_others", [], [[]]]];

if (_noLabel isEqualTo "") then {
    _noLabel = LLSTRING(Cancel);
};

private _theme = GVAR(theme);
private _font = _theme getOrDefault ["font", "PuristaMedium"];
private _buttonH = UNIT * 1.2;
private _gap = SQUARE(UNIT * 0.3);

// Every answer as [label, code, style], the one that does nothing first.
private _answers = [[_noLabel, {}, ""]];
_answers append (_others apply {[_x select 0, _x select 1, ""]});
_answers pushBack [_yesLabel, _code, "accent"];

// As wide as the question reads well, wider when the answers need it.
private _buttonWidths = _answers apply {SQUARE(_buttonH * 1.2) + ((_x select 0) getTextWidth [_font, _buttonH * 0.5]) * TEXT_SLACK};
private _buttonsW = 0;

{_buttonsW = _buttonsW + _x + _gap} forEach _buttonWidths;

private _width = (SQUARE(UNIT * 20)) max (_buttonsW - _gap);

// Measured in a box of that width before the card is made, so the card is as high as the question.
private _probe = _display ctrlCreate ["EINV_StructuredText", -1];
_probe ctrlSetPosition [safezoneX, safezoneY, _width, UNIT * 10];
_probe ctrlCommit 0;
_probe ctrlSetStructuredText parseText format [
    "<t font='%1' color='%2' size='%3'>%4</t>",
    _font, [_theme getOrDefault ["text", [0.925, 0.933, 0.949, 1]]] call FUNC(hex), TEXT_BODY / STRUCTURED_SIZE, [_text] call FUNC(escape)
];
private _textH = ctrlTextHeight _probe;
ctrlDelete _probe;

[_display, [], [_width, _textH + UNIT * 0.6 + _buttonH], "", {
    params ["_display", "_inner", "_theme", "_arguments"];
    _arguments params ["_text", "_answers", "_buttonWidths", "_gap", "_buttonH", "_payload"];

    (ctrlPosition _inner) params ["", "", "_width", "_height"];

    [_display, _inner, [0, 0, _width], _text, TEXT_BODY, _theme getOrDefault ["text", [0.925, 0.933, 0.949, 1]], _theme getOrDefault ["font", "PuristaMedium"]] call FUNC(uiText);

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
}, [_text, _answers, _buttonWidths, _gap, _buttonH, _arguments]] call FUNC(popover);
