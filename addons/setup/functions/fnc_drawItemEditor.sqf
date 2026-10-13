#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The right side of the Items step: the size, shape and stack of the class picked in the list.
 *   - What it is (picture, name, class, family, mod, weight) and what the draft makes of it now, with
 *     where that comes from (fnc_answerText).
 *   - Its width and height in cells (1-8) for a quick rectangle, and how many share a tile (1-999, with
 *     a few common numbers to pick at once). Weapons, uniforms, vests and backpacks never share a tile -
 *     their stack cannot be set.
 *   - Under them the canvas (fnc_uiCanvas), SHAPE_MAX cells each way, always shown: a click makes a place
 *     one of the item's cells or takes it away, so an L or a T is drawn cell by cell. The steppers and the
 *     canvas are one: a stepper lays a rectangle of its size where the cells are - the places that were
 *     in their box keep what they were, the new ones become cells, the rest goes -, and the steppers say
 *     the box of what is drawn. Beside it how it looks as a tile (fnc_drawPreview), its size in words, and
 *     a warning while its cells are not one piece (fnc_canvasBlocks) - then Apply cannot be pressed.
 *   - Apply writes what differs from now as class=X > size=WxH, or size=xx/x- for a shape
 *     (einv_items_fnc_formatMask), and stack=N (fnc_upsertRule) - the rest of that rule stays -, Discard
 *     drops the edits, Back to the preset takes the class's own size and stack away.
 *
 * Edits go into a working copy per class (GVAR(itemWork): lowercase class -> the canvas, with "stack" and
 * "start" - what it held when it was made) and reach the draft only with Apply. A change draws this side
 * again on its own (its place and arguments in uiNamespace QGVAR(editorArgs)) - there are few controls,
 * an 8x8 canvas -; the list stays.
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
private _loss = _theme getOrDefault ["loss", [0.941, 0.333, 0.353, 1]];

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

private _startShape = _info getOrDefault ["shape", format ["%1x%2", _sizeW, _sizeH]];
private _startStack = _info getOrDefault ["stack", 1];
private _canvas = GVAR(itemWork) getOrDefault [_lc, createHashMap];

// No edit yet: a canvas of what it is now, its shape in the top left corner. It becomes the working copy
// with the first change.
if (count _canvas == 0) then {
    _canvas = [[_info getOrDefault ["footprint", [_sizeW, _sizeH, []]]], SHAPE_MAX, SHAPE_MAX, SHAPE_MAX] call FUNC(canvasFromBlocks);
    _canvas set ["start", [_canvas] call FUNC(canvasBlocks)];
    _canvas set ["stack", _startStack];
};

private _blocks = [_canvas] call FUNC(canvasBlocks);
private _workStack = _canvas getOrDefault ["stack", _startStack];
private _dirty = _blocks isNotEqualTo (_canvas getOrDefault ["start", []]) || {_workStack != _startStack};

([_canvas] call FUNC(canvasBox)) params ["", "", "_boxW", "_boxH"];

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

_cursorY = _cursorY + UNIT * 0.3;

// ----- Width, height and stack -----

private _rowH = UNIT * 1.1;
private _labelW = SQUARE(UNIT * 3.6);
private _stepperW = SQUARE(UNIT * 5);
private _gap = SQUARE(UNIT * 0.3);

// Across or down: a rectangle of that size where the cells are. The places that were in their box keep
// what they were - an L stays an L, one column wider -, the new ones become cells, the rest goes. Moved
// in where it would reach past the canvas.
private _resize = {
    params ["_value", "_arguments"];
    _arguments params ["_class", "_canvas", "_axis"];

    private _cols = _canvas get "cols";
    private _rows = _canvas get "rows";
    private _cells = _canvas get "cells";

    ([_canvas] call FUNC(canvasBox)) params ["_boxCol", "_boxRow", "_boxW", "_boxH"];

    private _newW = [_boxW max 1, _value] select (_axis == 0);
    private _newH = [_boxH max 1, _value] select (_axis == 1);
    private _left = _boxCol min (_cols - _newW);
    private _top = _boxRow min (_rows - _newH);

    {
        private _col = _forEachIndex mod _cols;
        private _row = floor (_forEachIndex / _cols);
        private _inside = _col >= _left && {_col < _left + _newW} && {_row >= _top} && {_row < _top + _newH};
        private _before = _boxW > 0 && {_col >= _boxCol} && {_col < _boxCol + _boxW} && {_row >= _boxRow} && {_row < _boxRow + _boxH};

        _cells set [_forEachIndex, _inside && {!_before || {_x}}];
    } forEach +_cells;

    GVAR(itemWork) set [toLowerANSI _class, _canvas];

    [] call FUNC(drawItemEditor);
};

[_display, _box, [_innerX, _cursorY, _labelW, _rowH], LLSTRING(Col_Size), TEXT_SMALL, _colorText2, _fontBold, 0] call EFUNC(gui,uiLabel);

[
    _display, _box, [_innerX + _labelW, _cursorY, _stepperW, _rowH], _boxW max 1, [1, SHAPE_MAX, 1], _theme,
    _resize, [_class, _canvas, 0], LLSTRING(Cont_Cols)
] call FUNC(uiStepper);

[
    _display, _box, [_innerX + _labelW + _stepperW + _gap, _cursorY, _stepperW, _rowH], _boxH max 1, [1, SHAPE_MAX, 1], _theme,
    _resize, [_class, _canvas, 1], LLSTRING(Cont_Rows)
] call FUNC(uiStepper);

_cursorY = _cursorY + _rowH + UNIT * 0.3;

// How many share a tile: into the working copy, and this side drawn again.
private _setStack = {
    params ["_value", "_arguments"];
    _arguments params ["_class", "_canvas"];

    _canvas set ["stack", _value];
    GVAR(itemWork) set [toLowerANSI _class, _canvas];

    [] call FUNC(drawItemEditor);
};

[_display, _box, [_innerX, _cursorY, _labelW, _rowH], LLSTRING(Items_PerTile), TEXT_SMALL, [_colorText2, DISABLED_INK] select _forced, _fontBold, 0] call EFUNC(gui,uiLabel);

[
    _display, _box, [_innerX + _labelW, _cursorY, _stepperW, _rowH], [_workStack, 1] select _forced, [1, EDIT_STACK_MAX, 1], _theme,
    _setStack, [_class, _canvas], "%1", !_forced
] call FUNC(uiStepper);

// A few common stacks at one click - the stepper alone would take long to 100.
private _chipX = _innerX + _labelW + _stepperW + _gap * 2;
private _chipW = SQUARE(UNIT * 1.9);
private _chipH = UNIT * 0.9;

{
    if (_chipX + _chipW > _innerX + _innerW) exitWith {};

    [_display, _box, [_chipX, _cursorY + (_rowH - _chipH) / 2, _chipW, _chipH], str _x, !_forced && {_workStack == _x}, _theme, {
        params ["", "_arguments"];
        _arguments params ["_class", "_canvas", "_value"];

        _canvas set ["stack", _value];
        GVAR(itemWork) set [toLowerANSI _class, _canvas];

        [] call FUNC(drawItemEditor);
    }, [_class, _canvas, _x], !_forced] call FUNC(uiChip);

    _chipX = _chipX + _chipW + _gap;
} forEach [1, 5, 10, 20, 50, 100];

_cursorY = _cursorY + _rowH + UNIT * 0.5;

// ----- The canvas, and beside it how it looks -----

private _buttonH = UNIT * 1.15;
private _buttonsY = _height - CARD_PAD_Y - _buttonH;
private _cellH = ((_buttonsY - UNIT * 0.4 - _cursorY) / SHAPE_MAX) min (UNIT * 1.1);
private _cellW = SQUARE(_cellH);
private _canvasW = SHAPE_MAX * _cellW;
private _canvasH = SHAPE_MAX * _cellH;

[_display, _box, [_innerX, _cursorY, _canvasW, _canvasH], _canvas, _theme, createHashMapFromArray [
    ["cellH", _cellH],
    ["picture", _picture],
    ["scrollId", "itemCanvas"],
    ["arguments", [_class]],
    ["onChange", {
        params ["_canvas", "_arguments"];
        _arguments params ["_class"];

        GVAR(itemWork) set [toLowerANSI _class, _canvas];

        [] call FUNC(drawItemEditor);
    }]
]] call FUNC(uiCanvas);

private _sideX = _innerX + _canvasW + SQUARE(UNIT * 0.6);
private _sideW = _innerX + _innerW - _sideX;
private _sideY = _cursorY;
private _onePiece = count _blocks == 1;

[_display, _box, [_sideX, _sideY, _sideW, UNIT * 0.75], LLSTRING(Preview_Title), TEXT_SMALL, _muted, _fontBold, 0] call EFUNC(gui,uiLabel);

_sideY = _sideY + UNIT * 0.8;

private _previewH = _canvasH * 0.5;

[
    _display, _box, [_sideX, _sideY, _sideW, _previewH], _theme, [[], _blocks] select _onePiece,
    [_picture, _info getOrDefault ["category", CATEGORY_MISC]]
] call FUNC(drawPreview);

_sideY = _sideY + _previewH + UNIT * 0.3;

// Its size in words: the box and its cells, or what keeps it from being one item.
private _cellCount = {_x} count (_canvas get "cells");
private _sizeText = LLSTRING(Items_NoCellsTitle);

if (_onePiece) then {
    (_blocks select 0) params ["_w", "_h", "_holes"];

    _sizeText = [format [LLSTRING(Value_SizeShape), _w, _h, _cellCount], format [LLSTRING(Value_Size), _w, _h]] select (_holes isEqualTo []);
};

if (count _blocks > 1) then {
    _sizeText = format [LLSTRING(Items_Pieces), count _blocks];
};

_sideY = _sideY + ([_display, _box, [_sideX, _sideY, _sideW], _sizeText, TEXT_BODY, [_colorText, _loss] select !_onePiece, _fontBold] call FUNC(uiText)) + UNIT * 0.05;
_sideY = _sideY + ([_display, _box, [_sideX, _sideY, _sideW], format [LLSTRING(Cont_Cells), _cellCount], TEXT_SMALL, _colorText2, _font] call FUNC(uiText)) + UNIT * 0.2;

if (!_onePiece) then {
    _sideY = _sideY + ([
        _display, _box, [_sideX, _sideY, _sideW], [LLSTRING(Items_NotConnected), LLSTRING(Items_NoCells)] select (_blocks isEqualTo []), TEXT_SMALL, _loss, _font
    ] call FUNC(uiText)) + UNIT * 0.2;
};

// Said beside the canvas rather than above it: the canvas must not move under the mouse after the first
// click.
if (_dirty) then {
    _sideY = _sideY + ([_display, _box, [_sideX, _sideY, _sideW], LLSTRING(Items_Unapplied), TEXT_SMALL, _warn, _font] call FUNC(uiText)) + UNIT * 0.2;
};

[_display, _box, [_sideX, _sideY, _sideW], LLSTRING(Items_CanvasHelp), TEXT_SMALL, _muted, _font] call FUNC(uiText);

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
    params ["_class", "_canvas", "_startShape", "_startStack", "_forced"];

    private _lc = toLowerANSI _class;
    private _blocks = [_canvas] call FUNC(canvasBlocks);

    if (count _blocks != 1) exitWith {
        [LLSTRING(Items_NotConnected), "loss"] call FUNC(setHint);
    };

    // Only what differs from now: a size by mass or a stack from the preset stays theirs when untouched.
    // A shape is written as drawn, its edges trimmed; a full box as WxH.
    private _set = createHashMap;
    private _shape = (_blocks select 0) call EFUNC(items,formatMask);
    private _stack = _canvas getOrDefault ["stack", _startStack];

    if (_blocks isNotEqualTo (_canvas getOrDefault ["start", []]) && {_shape isNotEqualTo _startShape}) then {
        _set set ["footprint", _shape];
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
}, [_class, _canvas, _startShape, _startStack, _forced], _onePiece, "accent", LLSTRING(Items_ApplyTip)] call FUNC(uiAction);

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
