#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The right side of the Items step: the size and stack of the class picked in the list.
 *   - What it is (picture, name, class, family, mod, weight) and what the draft makes of it now, with
 *     where that comes from (fnc_answerText).
 *   - Its width (1-8) and height (1-8) in cells and how many share a tile (1-999, with a few common
 *     numbers to pick at once), and the cells it would take drawn with its picture on them. Weapons,
 *     uniforms, vests and backpacks never share a tile - their stack cannot be set.
 *   - Apply writes what differs from now as class=X > size=WxH stack=N (fnc_upsertRule) - the rest of
 *     that rule stays -, Discard drops the edits, Back to the preset takes the class's own size and stack
 *     away.
 *
 * Edits go into a working copy per class (GVAR(itemWork): lowercase class -> [w, h, stack]) and reach the
 * draft only with Apply. A change draws this side again on its own (its place and arguments in uiNamespace
 * QGVAR(editorArgs)); the list stays.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: The step's group <CONTROL>
 * 2: Position [x, y, w, h], relative to the group <ARRAY>
 * 3: Theme <HASHMAP>
 * None of them to draw it again where it was.
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, _group, [0.3, 0, 0.4, 0.5], _theme] call einv_setup_fnc_drawItemEditor;
 *
 * Public: No
 */

disableSerialization;

private _args = _this;

if (_args isEqualTo []) then {
    _args = uiNamespace getVariable [QGVAR(editorArgs), []];
};

_args params [["_display", displayNull, [displayNull]], ["_parent", controlNull, [controlNull]], ["_rect", [], [[]]], ["_theme", createHashMap, [createHashMap]]];

if (isNull _display || {isNull _parent}) exitWith {};

uiNamespace setVariable [QGVAR(editorArgs), _args];
ctrlDelete (uiNamespace getVariable [QGVAR(editor), controlNull]);

_rect params ["", "", "_width", "_height"];

private _box = [_display, "EINV_Group", _parent, _rect] call EFUNC(gui,uiCreate);

uiNamespace setVariable [QGVAR(editor), _box];

private _font = _theme getOrDefault ["font", "PuristaMedium"];
private _fontBold = _theme getOrDefault ["fontBold", "PuristaSemibold"];
private _colorText = _theme getOrDefault ["text", [0.925, 0.933, 0.949, 1]];
private _colorText2 = _theme getOrDefault ["text2", [0.698, 0.734, 0.784, 1]];
private _muted = _theme getOrDefault ["muted", [0.522, 0.553, 0.604, 1]];
private _accent = _theme getOrDefault ["accent", [0.84, 0.54, 0.1, 1]];
private _warn = _theme getOrDefault ["warn", [0.93, 0.75, 0.2, 1]];

[_display, _box, [0, 0, _width, _height], "", _theme] call FUNC(uiCard);

private _innerX = CARD_PAD_X;
private _innerW = _width - CARD_PAD_X * 2;
private _cursorY = CARD_PAD_Y;
private _class = GVAR(selection) getOrDefault ["items", ""];

if (_class isEqualTo "") exitWith {
    [_display, _box, [_innerX, _cursorY, _innerW], LLSTRING(Items_PickHint), TEXT_BODY, _colorText2, _font] call FUNC(uiText);
};

private _info = [_class, GVAR(draftRules), GVAR(draftCache)] call EFUNC(items,getInfo);

_class = _info get "class";

private _lc = toLowerANSI _class;
private _own = ((call FUNC(ownClassRules)) select 0) getOrDefault [_lc, createHashMap];
private _src = _info getOrDefault ["src", createHashMap];
private _forced = (_src getOrDefault ["stack", ""]) isEqualTo "forced";

(_info getOrDefault ["size", [1, 1]]) params ["_sizeW", "_sizeH"];

private _start = [_sizeW, _sizeH, _info getOrDefault ["stack", 1]];
private _work = GVAR(itemWork) getOrDefault [_lc, +_start];
private _dirty = _work isNotEqualTo _start;

_work params ["_workW", "_workH", "_workStack"];

// ----- What it is -----

private _picH = UNIT * 2.2;
private _picW = SQUARE(_picH * 2);
private _picture = _info getOrDefault ["picture", ""];

if (_picture isNotEqualTo "") then {
    [_display, _box, [_innerX, _cursorY, _picW, _picH], _picture] call EFUNC(gui,uiPicture);
};

private _textX = _innerX + _picW + SQUARE(UNIT * 0.4);
private _textW = _innerX + _innerW - _textX;
private _row = ((uiNamespace getVariable [QGVAR(index), createHashMap]) getOrDefault ["byClass", createHashMap]) getOrDefault [_lc, []];
private _family = _row param [ROW_FAMILY, ""];
private _about = format ["%1 · %2", _class, _row param [ROW_MOD, _info getOrDefault ["addon", ""]]];

if (_family isNotEqualTo "") then {
    _about = format ["%1 · %2 · %3", _class, localize format ["STR_einv_setup_Family_%1", _family], _row select ROW_MOD];
};

[
    _display, _box, [_textX, _cursorY, _textW, UNIT * 0.85],
    [_info getOrDefault ["name", _class], _textW, _fontBold, TEXT_HEAD] call EFUNC(gui,fitText), TEXT_HEAD, _colorText, _fontBold, 0
] call EFUNC(gui,uiLabel);

[
    _display, _box, [_textX, _cursorY + UNIT * 0.85, _textW, UNIT * 0.65],
    [_about, _textW, _font, TEXT_SMALL] call EFUNC(gui,fitText), TEXT_SMALL, _muted, _font, 0
] call EFUNC(gui,uiLabel);

[
    _display, _box, [_textX, _cursorY + UNIT * 1.45, _textW, UNIT * 0.65],
    format [LLSTRING(Items_Weight), ((_info getOrDefault ["mass", 0]) * MASS_TO_KG) toFixed 2], TEXT_SMALL, _colorText2, _font, 0
] call EFUNC(gui,uiLabel);

_cursorY = _cursorY + _picH + UNIT * 0.3;

// ----- What the draft makes of it now -----

{
    _x params ["_field", "_show"];

    if (_show) then {
        ([_info, _field, _own] call FUNC(answerText)) params ["_words", "_from"];

        private _isOwn = ((_src getOrDefault [["footprint", _field] select (_field isEqualTo "stack"), ""]) select [0, 4]) isEqualTo "own:";

        _cursorY = _cursorY + ([
            _display, _box, [_innerX, _cursorY, _innerW], format ["%1: %2 · %3", LLSTRING(Items_Now), _words, _from],
            TEXT_BODY, [_colorText, _accent] select _isOwn, _font
        ] call FUNC(uiText)) + UNIT * 0.1;
    };
} forEach [["size", true], ["stack", !_forced]];

if (_forced) then {
    _cursorY = _cursorY + ([_display, _box, [_innerX, _cursorY, _innerW], LLSTRING(Items_Forced), TEXT_SMALL, _muted, _font] call FUNC(uiText)) + UNIT * 0.1;
};

if (_dirty) then {
    _cursorY = _cursorY + ([_display, _box, [_innerX, _cursorY, _innerW], LLSTRING(Items_Unapplied), TEXT_SMALL, _warn, _font] call FUNC(uiText)) + UNIT * 0.1;
};

_cursorY = _cursorY + UNIT * 0.3;

// ----- Width, height and stack -----

private _rowH = UNIT * 1.1;
private _labelW = SQUARE(UNIT * 3.6);
private _stepperW = SQUARE(UNIT * 5);
private _gap = SQUARE(UNIT * 0.3);

// Every number: into the working copy, and this side drawn again.
private _setValue = {
    params ["_value", "_arguments"];
    _arguments params ["_class", "_start", "_index"];

    private _lc = toLowerANSI _class;
    private _work = GVAR(itemWork) getOrDefault [_lc, +_start];

    _work set [_index, _value];
    GVAR(itemWork) set [_lc, _work];

    [] call FUNC(drawItemEditor);
};

[_display, _box, [_innerX, _cursorY, _labelW, _rowH], LLSTRING(Col_Size), TEXT_SMALL, _colorText2, _fontBold, 0] call EFUNC(gui,uiLabel);

[
    _display, _box, [_innerX + _labelW, _cursorY, _stepperW, _rowH], _workW, [1, STORAGE_COLS max _workW, 1], _theme,
    _setValue, [_class, _start, 0], LLSTRING(Cont_Cols)
] call FUNC(uiStepper);

[
    _display, _box, [_innerX + _labelW + _stepperW + _gap, _cursorY, _stepperW, _rowH], _workH, [1, EDIT_ITEM_ROWS max _workH, 1], _theme,
    _setValue, [_class, _start, 1], LLSTRING(Cont_Rows)
] call FUNC(uiStepper);

_cursorY = _cursorY + _rowH + UNIT * 0.3;

[_display, _box, [_innerX, _cursorY, _labelW, _rowH], LLSTRING(Items_PerTile), TEXT_SMALL, [_colorText2, DISABLED_INK] select _forced, _fontBold, 0] call EFUNC(gui,uiLabel);

[
    _display, _box, [_innerX + _labelW, _cursorY, _stepperW, _rowH], [_workStack, 1] select _forced, [1, EDIT_STACK_MAX, 1], _theme,
    _setValue, [_class, _start, 2], "%1", !_forced
] call FUNC(uiStepper);

// A few common stacks at one click - the stepper alone would take long to 100.
private _chipX = _innerX + _labelW + _stepperW + _gap * 2;
private _chipW = SQUARE(UNIT * 1.9);
private _chipH = UNIT * 0.9;

{
    if (_chipX + _chipW > _innerX + _innerW) exitWith {};

    [_display, _box, [_chipX, _cursorY + (_rowH - _chipH) / 2, _chipW, _chipH], str _x, !_forced && {_workStack == _x}, _theme, {
        params ["", "_arguments"];
        _arguments params ["_class", "_start", "_value"];

        private _lc = toLowerANSI _class;
        private _work = GVAR(itemWork) getOrDefault [_lc, +_start];

        _work set [2, _value];
        GVAR(itemWork) set [_lc, _work];

        [] call FUNC(drawItemEditor);
    }, [_class, _start, _x], !_forced] call FUNC(uiChip);

    _chipX = _chipX + _chipW + _gap;
} forEach [1, 5, 10, 20, 50, 100];

_cursorY = _cursorY + _rowH + UNIT * 0.5;

// ----- The cells it would take, its picture on them -----

private _buttonH = UNIT * 1.15;
private _buttonsY = _height - CARD_PAD_Y - _buttonH;
private _cellH = ((_buttonsY - UNIT * 0.4 - _cursorY) / (_workH max 1)) min (UNIT * 1.2);
private _cellW = SQUARE(_cellH);

if (_cellH > UNIT * 0.3) then {
    for "_cellRow" from 0 to (_workH - 1) do {
        for "_cellCol" from 0 to (_workW - 1) do {
            [
                _display, _box, [_innerX + _cellCol * _cellW, _cursorY + _cellRow * _cellH, _cellW - pixelW, _cellH - pixelH],
                _theme getOrDefault ["buttonHover", [1, 1, 1, 0.16]]
            ] call EFUNC(gui,uiPanel);
        };
    };

    if (_picture isNotEqualTo "") then {
        [_display, _box, [_innerX, _cursorY, _workW * _cellW - pixelW, _workH * _cellH - pixelH], _picture] call EFUNC(gui,uiPicture);
    };

    [
        _display, _box, [_innerX + _workW * _cellW + SQUARE(UNIT * 0.4), _cursorY, _innerW - _workW * _cellW - SQUARE(UNIT * 0.4), UNIT * 0.75],
        format [LLSTRING(Items_Takes), _workW * _workH], TEXT_SMALL, _muted, _font, 0
    ] call EFUNC(gui,uiLabel);
};

// ----- Apply, Discard, Back to the preset -----

private _buttonX = _innerX;
private _fnc_buttonW = {
    params ["_text", ["_icon", false]];

    // Kept off both edges, and with an icon room for it and the gap after it (fnc_uiAction).
    private _padding = _buttonH * ([0.6, 1.38] select _icon);

    SQUARE(_padding) + (_text getTextWidth [_font, _buttonH * 0.5]) * TEXT_SLACK
};

private _applyW = [LLSTRING(Items_Apply), true] call _fnc_buttonW;

[_display, _box, [_buttonX, _buttonsY, _applyW, _buttonH], LLSTRING(Items_Apply), UI_TEX(icon_check_ca), _theme, {
    params ["_class", "_start", "_forced"];

    private _lc = toLowerANSI _class;

    (GVAR(itemWork) getOrDefault [_lc, _start]) params ["_w", "_h", "_stack"];
    _start params ["_startW", "_startH", "_startStack"];

    // Only what differs from now: a size by mass or a stack from the preset stays theirs when untouched.
    private _set = createHashMap;

    if (_w != _startW || {_h != _startH}) then {
        _set set ["footprint", format ["%1x%2", _w, _h]];
    };

    if (!_forced && {_stack != _startStack}) then {
        _set set ["stack", _stack];
    };

    GVAR(itemWork) deleteAt _lc;

    if (count _set == 0) exitWith {
        [LLSTRING(Hint_NothingToApply), "text2"] call FUNC(setHint);
        [] call FUNC(drawItemEditor);
    };

    [format [LLSTRING(Hint_SizeApplied), _class], "text2"] call FUNC(setHint);
    [_class, _set] call FUNC(upsertRule);
}, [_class, _start, _forced], true, "accent", LLSTRING(Items_ApplyTip)] call FUNC(uiAction);

_buttonX = _buttonX + _applyW + _gap;

if (_dirty) then {
    private _buttonW = [LLSTRING(Cont_Discard)] call _fnc_buttonW;

    [_display, _box, [_buttonX, _buttonsY, _buttonW, _buttonH], LLSTRING(Cont_Discard), "", _theme, {
        params ["_class"];

        GVAR(itemWork) deleteAt (toLowerANSI _class);

        [] call FUNC(drawItemEditor);
    }, [_class], true, "ghost"] call FUNC(uiAction);

    _buttonX = _buttonX + _buttonW + _gap;
};

if ("footprint" in _own || {"stack" in _own}) then {
    private _buttonW = [LLSTRING(Groups_Reset), true] call _fnc_buttonW;

    [_display, _box, [_buttonX, _buttonsY, _buttonW, _buttonH], LLSTRING(Groups_Reset), UI_TEX(icon_reset_ca), _theme, {
        params ["_class"];

        GVAR(itemWork) deleteAt (toLowerANSI _class);

        [format [LLSTRING(Hint_Reset), _class], "text2"] call FUNC(setHint);
        [_class, createHashMap, ["footprint", "stack"]] call FUNC(upsertRule);
    }, [_class], true, "ghost", LLSTRING(Items_ResetTip)] call FUNC(uiAction);
};
