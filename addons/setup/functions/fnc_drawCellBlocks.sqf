#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The Blocks way of the Containers step's editor (fnc_drawCellEditor, GVAR(cellMode) 1): a container's
 * compartments one by one, as the inventory lines them up - side by side, then on the next line -, for
 * those who would rather build it a compartment at a time than paint it.
 *   - A row of tools: which compartment is picked, its width (1 to STORAGE_COLS) and height (1 to
 *     MAX_ROWS), Add and Remove.
 *   - Under it every compartment as a small drawing of its own, its number and size over it: a click on
 *     a cell makes it a hole - a place the compartment does not have - or a cell again, and picks that
 *     compartment; a click on the caption only picks it. The picked one is ringed in the accent.
 * Under the tools of the picked compartment its attributes are set (fnc_drawCellAttrs): the categories it accepts and whether it is a
 * single slot - drawn under its cells as text. Never more places than MAX_CELLS in all, nor more compartments than MAX_BLOCKS.
 *
 * The working copy (GVAR(cellWork), lowercase class -> "blocks", "picked") is made by the first change,
 * which draws the editor again; a later click on a cell of the picked compartment changes only that cell,
 * the total and the preview (fnc_cellChanged). Everything else draws the editor again.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: The editor's group <CONTROL>
 * 2: Where the row of tools goes [x, y, w, h] <ARRAY>
 * 3: Where the compartments go [x, y, w, h] <ARRAY>
 * 4: Theme <HASHMAP>
 * 5: Class <STRING>
 * 6: Compartments shown [[cols, rows, holes], ...] - the working copy's, else what the class has <ARRAY>
 * 7: Index of the picked one <NUMBER>
 * 8: Editable - else only shown, with no tools <BOOL>
 *
 * Return Value:
 * The compartments' scrolling group <CONTROL>
 *
 * Example:
 * [_display, _box, [0, 0.2, 0.4, 0.03], [0, 0.25, 0.2, 0.3], _theme, "B_Carryall_khk", [[4, 3, []]], 0, true] call aio_setup_fnc_drawCellBlocks;
 *
 * Public: No
 */

disableSerialization;

params [
    "_display", "_box", "_toolRect", "_areaRect", ["_theme", createHashMap, [createHashMap]],
    ["_class", "", [""]], ["_shown", [], [[]]], ["_picked", 0, [0]], ["_editable", true, [true]]
];

private _font = _theme getOrDefault ["font", "PuristaMedium"];
private _fontBold = _theme getOrDefault ["fontBold", "PuristaSemibold"];
private _colorText2 = _theme getOrDefault ["text2", [0.78, 0.78, 0.78, 1]];
private _muted = _theme getOrDefault ["muted", [0.56, 0.56, 0.56, 1]];
private _accent = _theme getOrDefault ["accent", [0.84, 0.54, 0.1, 1]];

// The working copy of the class, made from what is shown the first time something changes.
private _fnc_work = {
    params ["_class", "_shown", "_picked"];

    private _lc = toLowerANSI _class;
    private _work = GVAR(cellWork) getOrDefault [_lc, createHashMap];

    if (count _work == 0) then {
        _work = createHashMapFromArray [["blocks", +_shown], ["picked", _picked]];
        GVAR(cellWork) set [_lc, _work];
    };

    _work
};

private _positions = 0;

{
    _positions = _positions + (_x select 0) * (_x select 1);
} forEach _shown;

// ----- The picked compartment: its size, and adding or removing one -----

if (_editable) then {
    _toolRect params ["_toolX", "_toolY", "_toolW", "_toolH"];

    private _gap = SQUARE(UNIT * 0.3);
    private _hasBlock = _shown isNotEqualTo [];

    (_shown param [_picked, [1, 1, []]]) params ["_cols", "_rows"];

    // Never more places, cells and holes, than MAX_CELLS - a control each.
    private _others = _positions - ([0, _cols * _rows] select _hasBlock);
    private _maxCols = ((STORAGE_COLS min floor ((MAX_CELLS - _others) / _rows)) max _cols) max 1;
    private _maxRows = ((MAX_ROWS min floor ((MAX_CELLS - _others) / _cols)) max _rows) max 1;
    private _labelW = SQUARE(UNIT * 5.6);
    private _stepperW = SQUARE(UNIT * 5);

    [
        _display, _box, [_toolX, _toolY, _labelW, _toolH],
        [LLSTRING(Cont_NoBlocks), format [LLSTRING(Cont_Picked), _picked + 1, count _shown]] select _hasBlock, TEXT_SMALL, _colorText2, _fontBold, 0
    ] call EFUNC(gui,uiLabel);

    // Both steppers: the picked compartment gets the new width or height; holes outside it go.
    private _resize = {
        params ["_value", "_arguments"];
        _arguments params ["_class", "_shown", "_block", "_axis", "_fnc_work"];

        private _work = [_class, _shown, _block] call _fnc_work;
        private _blocks = _work get "blocks";

        (_blocks select _block) params ["_cols", "_rows", "_holes"];

        private _was = _blocks select _block;

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

        _blocks set [_block, [[_newCols, _newRows, _kept], _was param [4, []], _was param [5, false]] call FUNC(cellBlock)];
        _work set ["picked", _block];

        [] call FUNC(drawCellEditor);
    };

    private _stepperX = _toolX + _labelW + _gap;

    [
        _display, _box, [_stepperX, _toolY, _stepperW, _toolH], _cols, [1, _maxCols, 1], _theme,
        _resize, [_class, _shown, _picked, 0, _fnc_work], LLSTRING(Cont_Cols), _hasBlock
    ] call FUNC(uiStepper);

    _stepperX = _stepperX + _stepperW + _gap;

    [
        _display, _box, [_stepperX, _toolY, _stepperW, _toolH], _rows, [1, _maxRows, 1], _theme,
        _resize, [_class, _shown, _picked, 1, _fnc_work], LLSTRING(Cont_Rows), _hasBlock
    ] call FUNC(uiStepper);

    _stepperX = _stepperX + _stepperW + SQUARE(UNIT * 0.6);

    // Add and Remove share what is left of the row; too narrow for their names, they keep their icons
    // and say it in the tooltip.
    private _room = (_toolX + _toolW - _stepperX - _gap) / 2;
    private _canAdd = count _shown < MAX_BLOCKS && {_positions < MAX_CELLS};

    [
        _display, _box, [_stepperX, _toolY, _room, _toolH],
        ["", LLSTRING(Cont_Add)] select (ACTION_W(LLSTRING(Cont_Add),_toolH,true,_font) <= _room), UI_TEX(icon_plus_ca), _theme, {
            params ["_class", "_shown", "_picked", "_fnc_work"];

            private _work = [_class, _shown, _picked] call _fnc_work;
            private _blocks = _work get "blocks";
            private _positions = 0;

            {
                _positions = _positions + (_x select 0) * (_x select 1);
            } forEach _blocks;

            _blocks pushBack ([[1, 1, []], [2, 2, []]] select (MAX_CELLS - _positions >= 4));
            _work set ["picked", count _blocks - 1];

            [] call FUNC(drawCellEditor);
        }, [_class, _shown, _picked, _fnc_work], _canAdd, "ghost", LLSTRING(Cont_AddTip)
    ] call FUNC(uiAction);

    [
        _display, _box, [_stepperX + _room + _gap, _toolY, _room, _toolH],
        ["", LLSTRING(Cont_Remove)] select (ACTION_W(LLSTRING(Cont_Remove),_toolH,true,_font) <= _room), UI_TEX(icon_minus_ca), _theme, {
            params ["_class", "_shown", "_picked", "_fnc_work"];

            private _work = [_class, _shown, _picked] call _fnc_work;

            (_work get "blocks") deleteAt _picked;
            _work set ["picked", (_picked - 1) max 0];

            [] call FUNC(drawCellEditor);
        }, [_class, _shown, _picked, _fnc_work], count _shown > 1, "ghost", LLSTRING(Cont_RemoveTip)
    ] call FUNC(uiAction);
};

// ----- The compartments -----

private _area = [_display, "AIO_ScrollGroup", _box, _areaRect] call EFUNC(gui,uiCreate);

_area setVariable [QGVAR(scrollId), "cellCanvas"];

private _areaW = (_areaRect select 2) - SCROLL_W - SQUARE(UNIT * 0.2);
// A whole number of pixels, as the Paint canvas's place is (fnc_drawCellEditor).
private _cellH = floor (UNIT * 0.95 / pixelH + 0.001) * pixelH;
private _cellW = SQUARE(_cellH);
private _captionH = UNIT * 0.8;
private _cellFill = _theme getOrDefault ["buttonHover", [1, 1, 1, 0.16]];
private _flowX = 0;
private _flowY = 0;
private _lineH = 0;

// A click on a cell: a hole, or a cell again. The first change - and one in another compartment, which
// picks it - draws the editor again; any other changes only the cell, the total and the preview.
private _toggle = {
    params ["_class", "_shown", "_block", "_cell", "_panel", "_hit", "_fnc_work"];

    private _first = !(toLowerANSI _class in GVAR(cellWork));
    private _work = [_class, _shown, _block] call _fnc_work;
    private _blocks = _work get "blocks";
    private _holes = (_blocks select _block) select 2;
    private _at = _holes find _cell;

    if (_at >= 0) then {
        _holes deleteAt _at;
    } else {
        _holes pushBack _cell;
        _holes sort true;
    };

    if (_first || {(_work get "picked") != _block}) exitWith {
        _work set ["picked", _block];

        [] call FUNC(drawCellEditor);
    };

    private _fill = [GVAR(theme) getOrDefault ["buttonHover", [1, 1, 1, 0.16]], BLOCK_HOLE] select (_at < 0);

    _panel ctrlSetBackgroundColor _fill;
    _hit setVariable [QGVAR(surface), [[_panel], _fill, BLOCK_HOVER]];

    [_blocks select {(_x select 0) * (_x select 1) > count (_x select 2)}] call FUNC(cellChanged);
};

{
    _x params ["_cols", "_rows", "_holes"];

    private _block = _x;
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
        _display, _area, [_flowX, _flowY, _blockW, _captionH], format ["%1 · %2x%3", _blockIndex + 1, _cols, _rows],
        TEXT_SMALL, [_muted, _accent] select _isPicked, [_font, _fontBold] select _isPicked, 0
    ] call EFUNC(gui,uiLabel);

    if (_editable && {!_isPicked}) then {
        [_display, _area, [_flowX, _flowY, _blockW, _captionH], [], [], [], {
            params ["_class", "_shown", "_block", "_fnc_work"];

            ([_class, _shown, _block] call _fnc_work) set ["picked", _block];

            [] call FUNC(drawCellEditor);
        }, [_class, _shown, _blockIndex, _fnc_work], true, LLSTRING(Cont_PickBlock)] call FUNC(uiHit);
    };

    private _gridY = _flowY + _captionH;

    for "_cellRow" from 0 to (_rows - 1) do {
        for "_cellCol" from 0 to (_cols - 1) do {
            private _cellIndex = _cellRow * _cols + _cellCol;
            private _fill = [_cellFill, BLOCK_HOLE] select (_cellIndex in _holes);
            private _cellRect = [_flowX + _cellCol * _cellW, _gridY + _cellRow * _cellH, _cellW - pixelW, _cellH - pixelH];
            private _panel = [_display, _area, _cellRect, _fill] call EFUNC(gui,uiPanel);

            if (_editable) then {
                private _hit = [_display, _area, _cellRect, _panel, _fill, BLOCK_HOVER] call FUNC(uiHit);

                _hit setVariable [QGVAR(action), [_toggle, [_class, _shown, _blockIndex, _cellIndex, _panel select 0, _hit, _fnc_work]]];
            };
        };
    };

    if (_isPicked) then {
        [_display, _area, [_flowX - pixelW, _gridY - pixelH, _cols * _cellW + pixelW, _rows * _cellH + pixelH], _accent, 0] call EFUNC(gui,uiRing);
    };

    // What it takes, under the cells: its categories and a single slot, nothing for a compartment that takes anything.
    private _attrs = ((_x param [4, []]) apply {(([_x, GVAR(draftRules)] call EFUNC(items,categoryInfo)) get "name")}) joinString "/";

    if (_x param [5, false]) then {
        _attrs = [_attrs + " · " + LLSTRING(Cont_SingleShort), LLSTRING(Cont_SingleShort)] select (_attrs isEqualTo "");
    };

    if (_attrs isNotEqualTo "") then {
        [
            _display, _area, [_flowX, _gridY + _rows * _cellH, _blockW, _captionH],
            [_attrs, _blockW, _font, TEXT_SMALL] call EFUNC(gui,fitText), TEXT_SMALL, _accent, _font, 0
        ] call EFUNC(gui,uiLabel);
    };

    _flowX = _flowX + _blockW + SQUARE(UNIT * 0.7);
    _lineH = _lineH max (_captionH + _rows * _cellH + ([0, _captionH] select (_attrs isNotEqualTo "")));
} forEach _shown;

_area
