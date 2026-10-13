#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The right side of the Containers step: the cells of the container picked in the list, to draw.
 *   - What it is (picture, name, class, kind, mod, load) and what the draft makes of it now, with where
 *     that comes from (fnc_answerText) and how many compartments and cells that gives.
 *   - Its compartments as they are laid out in the inventory (einv_storage_fnc_blocksFor), one canvas each:
 *     a click on a cell makes it a hole - a cell the compartment does not have - or a cell again. The
 *     compartment clicked last is the picked one: its width (1-8) and height (1-40) step up and down, it
 *     can be removed, and another one added. The total of cells and compartments against the limits
 *     (MAX_CELLS, MAX_BLOCKS) is under the canvases.
 *   - Apply writes the canvases as class=X > grid=xxxx/x--x+2x3 (fnc_upsertRule), Discard drops the
 *     edits, Back to the preset takes the class's own grid and like= away. "Like another class" lets the
 *     list pick the class this one takes its cells from (like=Y): the canvases then show that class's cells
 *     and cannot be drawn on, until Unlink.
 *
 * Edits go into a working copy per class (GVAR(cellWork): lowercase class -> [compartments, picked]) and
 * reach the draft only with Apply. A grid laid out by load or by a pattern (pockets, rig) is shown as the
 * compartments it gives; editing it writes those cells instead, which the editor says.
 *
 * A click on a cell changes only that cell and the total, at once; everything else draws this side again
 * on its own (it keeps its place and arguments in uiNamespace QGVAR(editorArgs)), the list stays.
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
 * [_display, _group, [0.3, 0, 0.4, 0.5], _theme] call einv_setup_fnc_drawCellEditor;
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
uiNamespace setVariable [QGVAR(cellTotals), controlNull];
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
private _loss = _theme getOrDefault ["loss", [0.941, 0.333, 0.353, 1]];
private _warn = _theme getOrDefault ["warn", [0.93, 0.75, 0.2, 1]];

[_display, _box, [0, 0, _width, _height], "", _theme] call FUNC(uiCard);

private _innerX = CARD_PAD_X;
private _innerW = _width - CARD_PAD_X * 2;
private _cursorY = CARD_PAD_Y;
private _class = GVAR(selection) getOrDefault ["containers", ""];

if (_class isEqualTo "") exitWith {
    [_display, _box, [_innerX, _cursorY, _innerW], LLSTRING(Cont_PickHint), TEXT_BODY, _colorText2, _font] call FUNC(uiText);
};

private _info = [_class, GVAR(draftRules), GVAR(draftCache)] call EFUNC(items,getInfo);
private _kind = _info getOrDefault ["kind", ""];

if !(_kind in CONTAINER_KINDS) exitWith {
    [_display, _box, [_innerX, _cursorY, _innerW], format [LLSTRING(Cont_NotContainer), _class], TEXT_BODY, _loss, _font] call FUNC(uiText);
};

_class = _info get "class";

private _lc = toLowerANSI _class;
private _own = ((call FUNC(ownClassRules)) select 0) getOrDefault [_lc, createHashMap];
private _like = _own getOrDefault ["like", ""];
private _linked = _like isNotEqualTo "" && {!("grid" in _own)};
private _spec = _info getOrDefault ["grid", ["auto"]];
private _src = (_info getOrDefault ["src", createHashMap]) getOrDefault ["grid", "builtin"];
private _maxLoad = _info getOrDefault ["maxLoad", 0];

// The compartments it has now, as the inventory lays them out: a grid by load or a pattern becomes the
// compartments it gives this class. One with no cells at all has none to show.
private _resolved = [];

if (!isNil QEFUNC(storage,blocksFor)) then {
    _resolved = [
        _class, [_kind, "crate"] select (_kind in ["crate", "vehicle"]), _maxLoad, _spec, (GVAR(draftRules) getOrDefault ["cell", 5]) max 1
    ] call EFUNC(storage,blocksFor);
};

_resolved = (_resolved select {(_x select 1) > 0}) apply {[_x select 0, _x select 1, +(_x param [2, []])]};

// What is drawn: the working copy, else what it has now. Linked to another class, always what it has -
// that class's cells.
private _work = GVAR(cellWork) getOrDefault [_lc, []];
private _useWork = !_linked && {_work isNotEqualTo []};
private _blocks = [_resolved, _work param [0, []]] select _useWork;
private _dirty = _useWork && {_blocks isNotEqualTo _resolved};
private _picked = (([0, _work param [1, 0]] select _useWork) min (count _blocks - 1)) max 0;
private _editable = !_linked;

// ----- What it is -----

private _picH = UNIT * 2.2;
private _picW = SQUARE(_picH);
private _picture = _info getOrDefault ["picture", ""];

if (_picture isNotEqualTo "") then {
    [_display, _box, [_innerX, _cursorY, _picW, _picH], _picture] call EFUNC(gui,uiPicture);
};

private _textX = _innerX + _picW + SQUARE(UNIT * 0.4);
private _textW = _innerX + _innerW - _textX;
private _row = ((uiNamespace getVariable [QGVAR(index), createHashMap]) getOrDefault ["byClass", createHashMap]) getOrDefault [_lc, []];
private _about = format ["%1 · %2 · %3", _class, localize format ["STR_einv_setup_Kind_%1", _kind], _row param [ROW_MOD, _info getOrDefault ["addon", ""]]];

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
    format [LLSTRING(Cont_Load), round _maxLoad, (_maxLoad * MASS_TO_KG) toFixed 1], TEXT_SMALL, _colorText2, _font, 0
] call EFUNC(gui,uiLabel);

_cursorY = _cursorY + _picH + UNIT * 0.3;

// ----- What the draft makes of it now -----

([_info, "grid", _own] call FUNC(answerText)) params ["_words", "_from"];

private _cellsNow = 0;

{
    _cellsNow = _cellsNow + (_x select 0) * (_x select 1) - count (_x select 2);
} forEach _resolved;

private _now = format ["%1: %2 · %3 · %4", LLSTRING(Items_Now), _words, _from, format [LLSTRING(Cont_Blocks), count _resolved, _cellsNow]];

_cursorY = _cursorY + ([
    _display, _box, [_innerX, _cursorY, _innerW], _now, TEXT_BODY, [_colorText, _accent] select ((_src select [0, 4]) isEqualTo "own:"), _font
] call FUNC(uiText)) + UNIT * 0.15;

private _notes = [];

if (_linked) then {
    _notes pushBack [format [LLSTRING(Cont_LinkedNote), _like], _accent];
};

if (!_linked && {_like isNotEqualTo ""}) then {
    _notes pushBack [format [LLSTRING(Cont_LikeRest), _like], _muted];
};

if (_editable && {(_spec param [0, ""]) isNotEqualTo "blocks"}) then {
    _notes pushBack [LLSTRING(Cont_PatternNote), _muted];
};

if ((_src select [0, 7]) isEqualTo "legacy:") then {
    _notes pushBack [LLSTRING(Cont_LegacyNote), _loss];
};

if (_dirty) then {
    _notes pushBack [LLSTRING(Cont_Unapplied), _warn];
};

{
    _x params ["_text", "_color"];

    _cursorY = _cursorY + ([_display, _box, [_innerX, _cursorY, _innerW], _text, TEXT_SMALL, _color, _font] call FUNC(uiText)) + UNIT * 0.1;
} forEach _notes;

_cursorY = _cursorY + UNIT * 0.2;

// ----- The picked compartment: its size, and adding or removing one -----

private _positions = 0;

{
    _positions = _positions + (_x select 0) * (_x select 1);
} forEach _blocks;

if (_editable) then {
    private _toolH = UNIT * 1.1;
    private _gap = SQUARE(UNIT * 0.3);
    private _hasBlock = _blocks isNotEqualTo [];

    (_blocks param [_picked, [1, 1, []]]) params ["_cols", "_rows"];

    // The canvases never hold more places, cells and holes, than MAX_CELLS - a control each.
    private _others = _positions - ([0, _cols * _rows] select _hasBlock);
    private _maxCols = ((STORAGE_COLS min floor ((MAX_CELLS - _others) / _rows)) max _cols) max 1;
    private _maxRows = ((MAX_ROWS min floor ((MAX_CELLS - _others) / _cols)) max _rows) max 1;
    private _labelW = SQUARE(UNIT * 5.4);
    private _stepperW = SQUARE(UNIT * 5);

    [
        _display, _box, [_innerX, _cursorY, _labelW, _toolH],
        [LLSTRING(Cont_NoBlocks), format [LLSTRING(Cont_Picked), _picked + 1, count _blocks]] select _hasBlock, TEXT_SMALL, _colorText2, _fontBold, 0
    ] call EFUNC(gui,uiLabel);

    // Both steppers: the picked compartment gets the new width or height; holes outside it go.
    private _resize = {
        params ["_value", "_arguments"];
        _arguments params ["_class", "_shown", "_block", "_axis"];

        private _lc = toLowerANSI _class;
        private _work = GVAR(cellWork) getOrDefault [_lc, []];

        if (_work isEqualTo []) then {
            _work = [+_shown, _block];
            GVAR(cellWork) set [_lc, _work];
        };

        private _blocks = _work select 0;

        (_blocks select _block) params ["_cols", "_rows", "_holes"];

        private _newCols = [_cols, _value] select (_axis == 0);
        private _newRows = [_rows, _value] select (_axis == 1);
        private _kept = [];

        {
            private _holeRow = floor (_x / _cols);
            private _holeCol = _x mod _cols;

            if (_holeRow < _newRows && {_holeCol < _newCols}) then {
                _kept pushBack (_holeRow * _newCols + _holeCol);
            };
        } forEach _holes;

        _blocks set [_block, [_newCols, _newRows, _kept]];
        _work set [1, _block];

        [] call FUNC(drawCellEditor);
    };

    private _stepperX = _innerX + _labelW + _gap;

    [
        _display, _box, [_stepperX, _cursorY, _stepperW, _toolH], _cols, [1, _maxCols, 1], _theme,
        _resize, [_class, _blocks, _picked, 0], LLSTRING(Cont_Cols), _hasBlock
    ] call FUNC(uiStepper);

    _stepperX = _stepperX + _stepperW + _gap;

    [
        _display, _box, [_stepperX, _cursorY, _stepperW, _toolH], _rows, [1, _maxRows, 1], _theme,
        _resize, [_class, _blocks, _picked, 1], LLSTRING(Cont_Rows), _hasBlock
    ] call FUNC(uiStepper);

    _stepperX = _stepperX + _stepperW + SQUARE(UNIT * 0.6);

    // Add and Remove share what is left of the row; too narrow for their names, they keep their icons
    // and say it in the tooltip.
    private _room = (_innerX + _innerW - _stepperX - _gap) / 2;
    private _fnc_fits = {
        params ["_text"];

        (SQUARE(_toolH * 1.38) + (_text getTextWidth [_font, _toolH * 0.5]) * TEXT_SLACK) <= _room
    };

    private _canAdd = count _blocks < MAX_BLOCKS && {_positions < MAX_CELLS};

    [
        _display, _box, [_stepperX, _cursorY, _room, _toolH], ["", LLSTRING(Cont_Add)] select ([LLSTRING(Cont_Add)] call _fnc_fits), UI_TEX(icon_plus_ca), _theme, {
            params ["_class", "_shown"];

            private _lc = toLowerANSI _class;
            private _work = GVAR(cellWork) getOrDefault [_lc, []];

            if (_work isEqualTo []) then {
                _work = [+_shown, 0];
                GVAR(cellWork) set [_lc, _work];
            };

            private _blocks = _work select 0;
            private _positions = 0;

            {
                _positions = _positions + (_x select 0) * (_x select 1);
            } forEach _blocks;

            _blocks pushBack ([[1, 1, []], [2, 2, []]] select (MAX_CELLS - _positions >= 4));
            _work set [1, count _blocks - 1];

            [] call FUNC(drawCellEditor);
        }, [_class, _blocks], _canAdd, "ghost", LLSTRING(Cont_Add)
    ] call FUNC(uiAction);

    [
        _display, _box, [_stepperX + _room + _gap, _cursorY, _room, _toolH], ["", LLSTRING(Cont_Remove)] select ([LLSTRING(Cont_Remove)] call _fnc_fits), UI_TEX(icon_minus_ca), _theme, {
            params ["_class", "_shown", "_block"];

            private _lc = toLowerANSI _class;
            private _work = GVAR(cellWork) getOrDefault [_lc, []];

            if (_work isEqualTo []) then {
                _work = [+_shown, _block];
                GVAR(cellWork) set [_lc, _work];
            };

            (_work select 0) deleteAt _block;
            _work set [1, (_block - 1) max 0];

            [] call FUNC(drawCellEditor);
        }, [_class, _blocks, _picked], count _blocks > 1, "ghost", LLSTRING(Cont_Remove)
    ] call FUNC(uiAction);

    _cursorY = _cursorY + _toolH + UNIT * 0.25;

    _cursorY = _cursorY + ([_display, _box, [_innerX, _cursorY, _innerW], LLSTRING(Cont_CanvasHelp), TEXT_SMALL, _muted, _font] call FUNC(uiText)) + UNIT * 0.2;
};

// ----- The canvases -----

private _buttonH = UNIT * 1.15;
private _buttonsY = _height - CARD_PAD_Y - _buttonH;
private _totalsH = UNIT * 0.8;
private _totalsY = _buttonsY - UNIT * 0.25 - _totalsH;

private _canvas = [_display, "EINV_ScrollGroup", _box, [_innerX, _cursorY, _innerW, (_totalsY - UNIT * 0.2 - _cursorY) max (UNIT * 2)]] call EFUNC(gui,uiCreate);

_canvas setVariable [QGVAR(scrollId), "cellCanvas"];

private _areaW = _innerW - SCROLL_W - SQUARE(UNIT * 0.25);
private _cellH = UNIT * 0.95;
private _cellW = SQUARE(_cellH);
private _captionH = UNIT * 0.8;
private _cellFill = _theme getOrDefault ["buttonHover", [1, 1, 1, 0.16]];
private _flowX = 0;
private _flowY = 0;
private _lineH = 0;

// A click on a cell: a hole, or a cell again. The first change - and one in another compartment, which
// picks it - draws the editor again; any other changes only the cell and the total, at once.
private _toggle = {
    params ["_class", "_shown", "_block", "_cell", "_panel", "_hit", "_dirty"];

    private _lc = toLowerANSI _class;
    private _work = GVAR(cellWork) getOrDefault [_lc, []];

    if (_work isEqualTo []) then {
        _work = [+_shown, _block];
        GVAR(cellWork) set [_lc, _work];
    };

    private _blocks = _work select 0;
    private _holes = (_blocks select _block) select 2;
    private _at = _holes find _cell;

    if (_at >= 0) then {
        _holes deleteAt _at;
    } else {
        _holes pushBack _cell;
        _holes sort true;
    };

    if (!_dirty || {(_work select 1) != _block}) exitWith {
        _work set [1, _block];

        [] call FUNC(drawCellEditor);
    };

    private _fill = [GVAR(theme) getOrDefault ["buttonHover", [1, 1, 1, 0.16]], EDIT_HOLE] select (_at < 0);

    _panel ctrlSetBackgroundColor _fill;
    _hit setVariable [QGVAR(surface), [[_panel], _fill, EDIT_HOVER]];

    private _totals = uiNamespace getVariable [QGVAR(cellTotals), controlNull];
    private _cells = 0;

    {
        _cells = _cells + (_x select 0) * (_x select 1) - count (_x select 2);
    } forEach _blocks;

    _totals ctrlSetText format [LLSTRING(Cont_Totals), _cells, MAX_CELLS, count _blocks, MAX_BLOCKS];
    _totals ctrlSetTextColor ([GVAR(theme) getOrDefault ["text2", [0.698, 0.734, 0.784, 1]], GVAR(theme) getOrDefault ["loss", [0.941, 0.333, 0.353, 1]]] select (_cells < 1 || {_cells > MAX_CELLS}));
};

{
    _x params ["_cols", "_rows", "_holes"];

    private _blockIndex = _forEachIndex;
    private _blockW = (_cols * _cellW) max SQUARE(UNIT * 3);
    private _isPicked = _editable && {_blockIndex == _picked};

    if (_flowX > 0 && {_flowX + _blockW > _areaW}) then {
        _flowX = 0;
        _flowY = _flowY + _lineH + UNIT * 0.5;
        _lineH = 0;
    };

    // Its number and size; a click on it picks it without changing a cell.
    [
        _display, _canvas, [_flowX, _flowY, _blockW, _captionH], format ["%1 · %2x%3", _blockIndex + 1, _cols, _rows],
        TEXT_SMALL, [_muted, _accent] select _isPicked, [_font, _fontBold] select _isPicked, 0
    ] call EFUNC(gui,uiLabel);

    if (_editable && {!_isPicked}) then {
        [_display, _canvas, [_flowX, _flowY, _blockW, _captionH], [], [], [], {
            params ["_class", "_shown", "_block"];

            private _lc = toLowerANSI _class;
            private _work = GVAR(cellWork) getOrDefault [_lc, []];

            if (_work isEqualTo []) then {
                _work = [+_shown, _block];
                GVAR(cellWork) set [_lc, _work];
            };

            _work set [1, _block];

            [] call FUNC(drawCellEditor);
        }, [_class, _blocks, _blockIndex], true, LLSTRING(Cont_PickBlock)] call FUNC(uiHit);
    };

    private _gridY = _flowY + _captionH;

    for "_cellRow" from 0 to (_rows - 1) do {
        for "_cellCol" from 0 to (_cols - 1) do {
            private _cellIndex = _cellRow * _cols + _cellCol;
            private _fill = [_cellFill, EDIT_HOLE] select (_cellIndex in _holes);
            private _cellRect = [_flowX + _cellCol * _cellW, _gridY + _cellRow * _cellH, _cellW - pixelW, _cellH - pixelH];
            private _panel = [_display, _canvas, _cellRect, _fill] call EFUNC(gui,uiPanel);

            if (_editable) then {
                private _hit = [_display, _canvas, _cellRect, _panel, _fill, EDIT_HOVER] call FUNC(uiHit);

                _hit setVariable [QGVAR(action), [_toggle, [_class, _blocks, _blockIndex, _cellIndex, _panel select 0, _hit, _dirty]]];
            };
        };
    };

    if (_isPicked) then {
        [_display, _canvas, [_flowX - pixelW, _gridY - pixelH, _cols * _cellW + pixelW, _rows * _cellH + pixelH], _accent, 0] call EFUNC(gui,uiRing);
    };

    _flowX = _flowX + _blockW + SQUARE(UNIT * 0.7);
    _lineH = _lineH max (_captionH + _rows * _cellH);
} forEach _blocks;

// ----- The total, against the limits -----

private _cells = 0;

{
    _cells = _cells + (_x select 0) * (_x select 1) - count (_x select 2);
} forEach _blocks;

private _totals = [
    _display, _box, [_innerX, _totalsY, _innerW, _totalsH], format [LLSTRING(Cont_Totals), _cells, MAX_CELLS, count _blocks, MAX_BLOCKS],
    TEXT_SMALL, [_colorText2, _loss] select (_cells < 1 || {_cells > MAX_CELLS}), _font, 0
] call EFUNC(gui,uiLabel);

uiNamespace setVariable [QGVAR(cellTotals), _totals];

// ----- Apply, Discard, Back to the preset; Like another class or Unlink -----

private _gap = SQUARE(UNIT * 0.3);
private _buttonX = _innerX;
private _fnc_buttonW = {
    params ["_text", ["_icon", false]];

    // Kept off both edges, and with an icon room for it and the gap after it (fnc_uiAction).
    private _padding = _buttonH * ([0.6, 1.38] select _icon);

    SQUARE(_padding) + (_text getTextWidth [_font, _buttonH * 0.5]) * TEXT_SLACK
};

if (_editable) then {
    private _buttonW = [LLSTRING(Cont_Apply), true] call _fnc_buttonW;

    [_display, _box, [_buttonX, _buttonsY, _buttonW, _buttonH], LLSTRING(Cont_Apply), UI_TEX(icon_check_ca), _theme, {
        params ["_class", "_shown"];

        private _lc = toLowerANSI _class;
        private _blocks = (GVAR(cellWork) getOrDefault [_lc, [_shown]]) select 0;

        // A compartment left without a single cell cannot be written (einv_items_fnc_parseGrid): it goes.
        private _kept = _blocks select {(_x select 0) * (_x select 1) > count (_x select 2)};
        private _cells = 0;

        {
            _cells = _cells + (_x select 0) * (_x select 1) - count (_x select 2);
        } forEach _kept;

        if (_kept isEqualTo []) exitWith {
            [LLSTRING(Hint_NoCells), "loss"] call FUNC(setHint);
        };

        if (_cells > MAX_CELLS || {count _kept > MAX_BLOCKS}) exitWith {
            [format [LLSTRING(Hint_TooMany), MAX_CELLS, MAX_BLOCKS], "loss"] call FUNC(setHint);
        };

        GVAR(cellWork) deleteAt _lc;

        [format [LLSTRING(Hint_CellsApplied), _class], "text2"] call FUNC(setHint);
        [_class, createHashMapFromArray [["grid", [["blocks", _kept]] call EFUNC(items,formatGrid)]]] call FUNC(upsertRule);
    }, [_class, _blocks], true, "accent", LLSTRING(Cont_ApplyTip)] call FUNC(uiAction);

    _buttonX = _buttonX + _buttonW + _gap;
};

if (_dirty) then {
    private _buttonW = [LLSTRING(Cont_Discard)] call _fnc_buttonW;

    [_display, _box, [_buttonX, _buttonsY, _buttonW, _buttonH], LLSTRING(Cont_Discard), "", _theme, {
        params ["_class"];

        GVAR(cellWork) deleteAt (toLowerANSI _class);

        [] call FUNC(drawCellEditor);
    }, [_class], true, "ghost"] call FUNC(uiAction);

    _buttonX = _buttonX + _buttonW + _gap;
};

if ("grid" in _own || {"like" in _own}) then {
    private _buttonW = [LLSTRING(Groups_Reset), true] call _fnc_buttonW;

    [_display, _box, [_buttonX, _buttonsY, _buttonW, _buttonH], LLSTRING(Groups_Reset), UI_TEX(icon_reset_ca), _theme, {
        params ["_class"];

        GVAR(cellWork) deleteAt (toLowerANSI _class);

        [format [LLSTRING(Hint_Reset), _class], "text2"] call FUNC(setHint);
        [_class, createHashMap, ["grid", "like"]] call FUNC(upsertRule);
    }, [_class], true, "ghost", LLSTRING(Cont_ResetTip)] call FUNC(uiAction);
};

// Like another class: the list picks it (fnc_drawResults). Unlink takes like= away again.
private _linkText = [LLSTRING(Cont_Like), LLSTRING(Cont_Unlink)] select (_like isNotEqualTo "");
private _linkW = [_linkText, true] call _fnc_buttonW;

[_display, _box, [_innerX + _innerW - _linkW, _buttonsY, _linkW, _buttonH], _linkText, UI_TEX(icon_swap_ca), _theme, {
    params ["_class", "_linked"];

    if (_linked) exitWith {
        [format [LLSTRING(Hint_Unlinked), _class], "text2"] call FUNC(setHint);
        [_class, createHashMap, ["like"]] call FUNC(upsertRule);
    };

    GVAR(likePick) = _class;

    [format [LLSTRING(List_PickLike), _class], "accent"] call FUNC(setHint);
    [GVAR(step)] call FUNC(showStep);
}, [_class, _like isNotEqualTo ""], true, "", [LLSTRING(Cont_LikeTip), LLSTRING(Cont_UnlinkTip)] select (_like isNotEqualTo "")] call FUNC(uiAction);
