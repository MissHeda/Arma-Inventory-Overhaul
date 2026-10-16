#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * A card listing what the draft changes, each change one line in words (fnc_changeRows) - the same list
 * on both pages, so a player learns to read it once:
 *   - "default", Start's "What you changed": against the Default preset - the preset picked, the cell
 *     size, every own rule.
 *   - "saved", Review's "What changes": against what is saved, each line marked new, changed or removed,
 *     and under the list how many there are against the Default preset, for the whole of it.
 * A rule for one class shows the class's picture and display name - "Adenosine Vial: 2×1 cells, 10 per
 * tile" -, anything else its sentence. A click on a line opens it where it is set: a rule for exactly one
 * class at the step that lists its kind: the Containers step for a uniform, vest, backpack, crate, vehicle or kit -
 * a crate or vehicle always (the Items step has none), the others when the rule sets grid= or like=, or sets
 * nothing of an item's own (size, stack, weight, name), a picture alone say -, else the Items step. The preset and
 * cell size open Start; anything else (a group, a rule for many classes, a class this game does not have) opens
 * Review's text. The cross takes that one change back.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: The step's group <CONTROL>
 * 2: Position [x, y, w, h], relative to the group <ARRAY>
 * 3: Theme <HASHMAP>
 * 4: Against "default" or "saved" <STRING> (default: "default")
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, _group, [0.5, 0.2, 0.3, 0.3], _theme, "saved"] call einv_setup_fnc_drawChanges;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_group", "_rect", "_theme", ["_against", "default", [""]]];

_rect params ["_left", "_top", "_width", "_height"];

private _font = _theme getOrDefault ["font", "PuristaMedium"];
private _colorText = _theme getOrDefault ["text", [0.925, 0.933, 0.949, 1]];
private _muted = _theme getOrDefault ["muted", [0.522, 0.553, 0.604, 1]];
private _accent = _theme getOrDefault ["accent", [0.84, 0.54, 0.1, 1]];

private _saved = _against isEqualTo "saved";
private _rows = [_against] call FUNC(changeRows);
private _count = count _rows;
private _innerX = _left + CARD_PAD_X;
private _innerW = _width - CARD_PAD_X * 2;
private _bottom = _top + _height - CARD_PAD_Y;
private _cursorY = [_display, _group, _rect, [LLSTRING(Changes_Title), LLSTRING(Review_Changes)] select _saved, _theme] call FUNC(uiCard);

private _fnc_count = {
    params ["_count", "_none", "_one", "_many"];

    switch (_count) do {
        case 0: {_none};
        case 1: {_one};
        default {format [_many, _count]};
    };
};

private _summary = if (_saved) then {
    [_count, LLSTRING(Review_None), LLSTRING(Review_CountOne), LLSTRING(Review_Count)] call _fnc_count
} else {
    [_count, LLSTRING(Changes_None), LLSTRING(Changes_CountOne), LLSTRING(Changes_Count)] call _fnc_count
};

_cursorY = _cursorY + ([_display, _group, [_innerX, _cursorY, _innerW], _summary, TEXT_BODY, [_muted, _colorText] select (_count > 0), _font] call FUNC(uiText)) + UNIT * 0.15;

// Taken from the setup in effect but not stored where Save goes: nothing to list, and Save is offered all
// the same (fnc_sourceEmpty) - said here, or the enabled Save would look like a mistake.
if (_saved && {_count == 0} && {!GVAR(readOnly)} && {GVAR(sourceEmpty)}) then {
    _cursorY = _cursorY + ([_display, _group, [_innerX, _cursorY, _innerW], LLSTRING(Review_NotStored), TEXT_SMALL, _accent, _font] call FUNC(uiText)) + UNIT * 0.15;
};

// Review: the whole of it under the list, against the Default preset - Start's count.
if (_saved) then {
    private _total = count (["default", false] call FUNC(changeRows));
    private _totalH = UNIT * 0.8;

    _bottom = _bottom - _totalH;

    [
        _display, _group, [_innerX, _bottom + UNIT * 0.05, _innerW, _totalH],
        [[_total, LLSTRING(Changes_None), LLSTRING(Changes_CountOne), LLSTRING(Changes_Count)] call _fnc_count, _innerW, _font, TEXT_SMALL] call EFUNC(gui,fitText),
        TEXT_SMALL, _muted, _font, 0
    ] call EFUNC(gui,uiLabel);
};

if (_count == 0) exitWith {};

_cursorY = _cursorY + ([_display, _group, [_innerX, _cursorY, _innerW], LLSTRING(Changes_Help), TEXT_SMALL, _muted, _font] call FUNC(uiText)) + UNIT * 0.3;

private _list = [_display, "EINV_ScrollGroup", _group, [_innerX, _cursorY, _innerW, (_bottom - _cursorY) max (UNIT * 1.2)]] call EFUNC(gui,uiCreate);

_list setVariable [QGVAR(scrollId), ["startChanges", "reviewChanges"] select _saved];

// A click on a line: the step and class it belongs to.
private _open = {
    params ["_kind", "_class", "_statement"];

    private _review = GVAR(steps) findIf {(_x select 0) isEqualTo "review"};

    if (_kind in ["preset", "cell"]) exitWith {
        GVAR(startAdvanced) = GVAR(startAdvanced) || {_kind isEqualTo "cell"};

        [0] call FUNC(showStep);
    };

    private _facts = if (_class isEqualTo "") then {createHashMap} else {[_class] call EFUNC(items,getFacts)};

    // Nothing to open it at: Review, its text unfolded.
    if ((_facts getOrDefault ["root", ""]) isEqualTo "") exitWith {
        GVAR(reviewText) = _kind isNotEqualTo "override";

        [_review] call FUNC(showStep);
    };

    // By the class's kind: a container at Containers - a crate or vehicle always, any other when its rule has grid=
    // or like=, or sets nothing an item has of its own -, anything else, and a container's own size, stack, weight
    // and name, as any item's, at Items.
    private _values = _statement param [1, createHashMap];
    private _classKind = _facts getOrDefault ["kind", ""];
    private _container = (_classKind in CONTAINER_KINDS) && {
        _classKind in ["crate", "vehicle"] || {"grid" in _values} || {"like" in _values}
        || {!("footprint" in _values) && {!("stack" in _values)} && {!("weight" in _values)} && {!("name" in _values)}}
    };
    private _stepId = ["items", "containers"] select _container;

    GVAR(selection) set [_stepId, _class];
    GVAR(editScope) set [_stepId, "class"];
    GVAR(listState) set [_stepId, [_class, "all", false, 0]];

    [GVAR(steps) findIf {(_x select 0) isEqualTo _stepId}] call FUNC(showStep);
};

(ctrlPosition _list) params ["", "", "_listW"];

private _rowW = _listW - SCROLL_W - SQUARE(UNIT * 0.3);
private _rowH = UNIT * 1.15;
private _removeH = UNIT * 0.95;
private _removeW = SQUARE(_removeH);
private _pictureH = _rowH - UNIT * 0.2;
private _pictureW = [0, SQUARE(_pictureH) + SQUARE(UNIT * 0.2)] select ((_rows findIf {(_x select 4) isNotEqualTo ""}) >= 0);
private _textX = SQUARE(UNIT * 0.3) + _pictureW;
private _tags = [["new", LLSTRING(Change_New), "gain"], ["changed", LLSTRING(Change_Changed), "accent"], ["removed", LLSTRING(Change_Removed), "loss"]];
private _tagW = 0;

// Against the Default preset everything is new: only Review marks them.
if (_saved) then {
    {
        _tagW = _tagW max (((_x select 1) getTextWidth [_font, TEXT_SMALL]) * TEXT_SLACK);
    } forEach _tags;
};

private _tagX = _rowW - _removeW - SQUARE(UNIT * 0.3) - _tagW;
private _textW = _tagX - _textX - SQUARE(UNIT * 0.3);
private _rowFill = [1, 1, 1, 0.035];
private _rowHover = [1, 1, 1, 0.085];
private _rowRadius = (_theme getOrDefault ["radius", 0]) min (UNIT * 0.3);
private _cursor = 0;

{
    _x params ["_kind", "_status", "_label", "_words", "_picture", "_before", "_class", "_statement", "_undo"];

    private _removed = _status isEqualTo "removed";
    private _text = [_label, format ["%1: %2", _label, _words]] select (_words isNotEqualTo "");
    private _tooltip = [_text, format [LLSTRING(Change_Before), _text, _before]] select (_before isNotEqualTo "");
    private _rowRect = [0, _cursor, _rowW, _rowH];
    private _surface = [_display, _list, _rowRect, _rowFill, _rowRadius] call EFUNC(gui,uiPanel);

    if (_picture isNotEqualTo "") then {
        [_display, _list, [SQUARE(UNIT * 0.2), _cursor + (_rowH - _pictureH) / 2, SQUARE(_pictureH), _pictureH], _picture, [[1, 1, 1, 1], [1, 1, 1, 0.45]] select _removed] call EFUNC(gui,uiPicture);
    };

    [
        _display, _list, [_textX, _cursor, _textW, _rowH],
        [_text, _textW, _font, TEXT_BODY] call EFUNC(gui,fitText), TEXT_BODY,
        [[_colorText, _accent] select (_kind isEqualTo "group"), _muted] select _removed, _font, 0
    ] call EFUNC(gui,uiLabel);

    if (_saved) then {
        private _tag = _tags select (_tags findIf {(_x select 0) isEqualTo _status});

        [_display, _list, [_tagX, _cursor, _tagW, _rowH], _tag select 1, TEXT_SMALL, _theme getOrDefault [_tag select 2, _muted], _font, 1] call EFUNC(gui,uiLabel);
    };

    // The line opens it; the cross on top of it takes the change back.
    [_display, _list, _rowRect, _surface, _rowFill, _rowHover, _open, [_kind, _class, _statement], true, _tooltip] call FUNC(uiHit);

    [
        _display, _list, [_rowW - _removeW - SQUARE(UNIT * 0.1), _cursor + (_rowH - _removeH) / 2, _removeW, _removeH], "", UI_TEX(icon_close_ca), _theme, {
            params ["_code", "_arguments"];

            _arguments call _code;
        }, _undo, true, "ghost", LLSTRING(Change_Undo)
    ] call FUNC(uiAction);

    _cursor = _cursor + _rowH + UNIT * 0.15;
} forEach _rows;
