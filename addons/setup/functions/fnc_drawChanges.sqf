#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The Start step's card "What you changed": how many rules of its own the draft has on top of its preset,
 * and each of them as a sentence (fnc_describeRule) - "Class ACM_Vial_Adenosine: 2×1 cells, 10 per tile".
 *   - A click on one opens it where it is set, that class picked and found in the list: a rule for
 *     exactly one class in the Items step, or - for a uniform, vest, backpack, crate or vehicle whose
 *     cells or like= it sets - in the Containers step. Any other (a group, a rule for many classes, a
 *     class this game does not have) at Review, which shows them all as text.
 *   - The cross takes it away, as at Review.
 *   - "Nothing changed yet" without any.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: The step's group <CONTROL>
 * 2: Position [x, y, w, h], relative to the group <ARRAY>
 * 3: Theme <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, _group, [0.5, 0.2, 0.3, 0.3], _theme] call einv_setup_fnc_drawChanges;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_group", "_rect", "_theme"];

_rect params ["_left", "_top", "_width", "_height"];

private _font = _theme getOrDefault ["font", "PuristaMedium"];
private _colorText = _theme getOrDefault ["text", [0.925, 0.933, 0.949, 1]];
private _muted = _theme getOrDefault ["muted", [0.522, 0.553, 0.604, 1]];
private _accent = _theme getOrDefault ["accent", [0.84, 0.54, 0.1, 1]];

private _groups = GVAR(draft) getOrDefault ["groups", []];
private _rules = GVAR(draft) getOrDefault ["rules", []];
private _count = count _groups + count _rules;
private _innerX = _left + CARD_PAD_X;
private _innerW = _width - CARD_PAD_X * 2;
private _bottom = _top + _height - CARD_PAD_Y;
private _cursorY = [_display, _group, _rect, LLSTRING(Changes_Title), _theme] call FUNC(uiCard);

private _summary = [
    LLSTRING(Changes_None),
    format [LLSTRING(Changes_Count), _count, [GVAR(draft) getOrDefault ["base", "default"]] call FUNC(presetName)]
] select (_count > 0);

_cursorY = _cursorY + ([_display, _group, [_innerX, _cursorY, _innerW], _summary, TEXT_BODY, [_muted, _colorText] select (_count > 0), _font] call FUNC(uiText)) + UNIT * 0.15;

if (_count == 0) exitWith {};

_cursorY = _cursorY + ([_display, _group, [_innerX, _cursorY, _innerW], LLSTRING(Changes_Help), TEXT_SMALL, _muted, _font] call FUNC(uiText)) + UNIT * 0.3;

private _list = [_display, "EINV_ScrollGroup", _group, [_innerX, _cursorY, _innerW, (_bottom - _cursorY) max (UNIT * 1.2)]] call EFUNC(gui,uiCreate);

_list setVariable [QGVAR(scrollId), "startChanges"];

// A click on a rule: the step and class it belongs to.
private _open = {
    params ["_isGroup", "_statement"];

    private _review = GVAR(steps) findIf {(_x select 0) isEqualTo "review"};

    if (_isGroup) exitWith {
        [_review] call FUNC(showStep);
    };

    _statement params ["_conds", "_values"];

    // Only a rule for exactly one class (class=X, not X+) has a class to open; the engine reads it the same.
    private _class = "";

    if (count _conds == 1) then {
        (_conds select 0) params ["_negated", "_key", "_op", "_names"];

        if (!_negated && {_key isEqualTo "class"} && {_op isEqualTo "="} && {count _names == 1} && {((_names select 0) find "+") < 0}) then {
            _class = _names select 0;
        };
    };

    if (_class isEqualTo "") exitWith {
        [_review] call FUNC(showStep);
    };

    private _facts = [_class] call EFUNC(items,getFacts);

    if ((_facts getOrDefault ["root", ""]) isEqualTo "") exitWith {
        [_review] call FUNC(showStep);
    };

    // A container's cells and like= are drawn at Containers; its own size and stack, as any item's, at Items.
    private _container = ((_facts getOrDefault ["kind", ""]) in CONTAINER_KINDS) && {
        "grid" in _values || {"like" in _values} || {!("footprint" in _values) && {!("stack" in _values)}}
    };
    private _stepId = ["items", "containers"] select _container;

    _class = _facts get "class";

    GVAR(selection) set [_stepId, _class];
    GVAR(listState) set [_stepId, [_class, "all", false, 0]];

    [GVAR(steps) findIf {(_x select 0) isEqualTo _stepId}] call FUNC(showStep);
};

(ctrlPosition _list) params ["", "", "_listW"];

private _rowW = _listW - SCROLL_W - SQUARE(UNIT * 0.3);
private _rowH = UNIT * 1.15;
private _removeH = UNIT * 0.95;
private _removeW = SQUARE(_removeH);
private _textX = SQUARE(UNIT * 0.3);
private _textW = _rowW - _textX - _removeW - SQUARE(UNIT * 0.4);
private _rowFill = [1, 1, 1, 0.035];
private _rowHover = [1, 1, 1, 0.085];
private _rowRadius = (_theme getOrDefault ["radius", 0]) min (UNIT * 0.3);
private _cursor = 0;

// In the order the engine writes them, its groups first: the same rows as at Review.
([GVAR(draftText)] call FUNC(statements)) params ["", "_statements"];

private _entries = [];

{_entries pushBack [true, _x, _forEachIndex]} forEach _groups;
{_entries pushBack [false, _x, _forEachIndex]} forEach _rules;

{
    _x params ["_isGroup", "_statement", "_index"];

    private _sentence = [_statement, GVAR(draft), _isGroup] call FUNC(describeRule);
    private _rowRect = [0, _cursor, _rowW, _rowH];
    private _surface = [_display, _list, _rowRect, _rowFill, _rowRadius] call EFUNC(gui,uiPanel);

    [
        _display, _list, [_textX, _cursor, _textW, _rowH],
        [_sentence, _textW, _font, TEXT_BODY] call EFUNC(gui,fitText), TEXT_BODY, [_colorText, _accent] select _isGroup, _font, 0
    ] call EFUNC(gui,uiLabel);

    // The row opens it; the cross on top of it takes it away.
    [
        _display, _list, _rowRect, _surface, _rowFill, _rowHover, _open, [_isGroup, _statement], true,
        format ["%1 - %2", _sentence, _statements param [_forEachIndex, ""]]
    ] call FUNC(uiHit);

    [
        _display, _list, [_rowW - _removeW - SQUARE(UNIT * 0.1), _cursor + (_rowH - _removeH) / 2, _removeW, _removeH], "", UI_TEX(icon_close_ca), _theme, {
            params ["_isGroup", "_index"];

            private _ast = [GVAR(draftText)] call EFUNC(items,parseRules);
            (_ast getOrDefault [["rules", "groups"] select _isGroup, []]) deleteAt _index;

            [_ast] call FUNC(commit);
        }, [_isGroup, _index], true, "ghost", LLSTRING(Review_Remove)
    ] call FUNC(uiAction);

    _cursor = _cursor + _rowH + UNIT * 0.15;
} forEach _entries;
