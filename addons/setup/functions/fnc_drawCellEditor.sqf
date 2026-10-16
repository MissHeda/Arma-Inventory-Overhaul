#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The right side of the Containers step: the cells of the container picked in the list, to draw.
 *   - What it is (picture, name, class, kind, mod, load) and what the draft makes of it now, with where
 *     that comes from (fnc_answerText) and how many compartments and cells that gives.
 *   - Two ways to draw them, picked above the drawing and kept for the session (GVAR(cellMode)):
 *     Paint (0) - one drawing STORAGE_COLS wide (fnc_uiCanvas with a palette): eight colours and "none"
 *       as chips, the one picked the brush (GVAR(cellBrush)); a click paints a place or takes the colour
 *       away, a stroke with the button held paints every place it passes. Cells of one colour that touch
 *       are one compartment, another colour beside them another one, a place without colour no cell
 *       (fnc_canvasBlocks). Rows 1 to MAX_ROWS, Fill paints every empty place in the brush's colour,
 *       Clear takes every colour away. Apply writes the compartments exactly where they were painted.
 *     Blocks (1) - the compartments one by one, side by side as the inventory lines them up
 *       (fnc_drawCellBlocks): each its own small drawing, a click making a cell a hole; the one picked
 *       gets its width and height; Add and Remove. Apply writes them one after the other (+).
 *     Switching turns a working copy into the other way: painted compartments become blocks in reading
 *     order, blocks are laid out as the inventory flows them and coloured (fnc_canvasFromBlocks).
 *   - Beside it how the inventory will show them (fnc_drawPreview), and under it the total of cells and
 *     compartments against the limits (fnc_cellChanged).
 *   - Under that preview the container's picture, as in the Items step: the Picture row (fnc_drawPictureRow, with
 *     the picture picker), and beside the box as the window draws it (fnc_drawBoxPreview) the zoom and shift
 *     (fnc_drawIconBlock). The edits are the class's own working copy (GVAR(boxWork): "iconPercent",
 *     "pictureText"), apart from the cells', and Apply writes icon= and picture= with the grid.
 *   - In the corner Export and Import (fnc_editorTools): the config lines of the class, and a pasted
 *     setup of them.
 *   - Picked in the tree view (fnc_editScope), the edit is for the class and every class built on it: a
 *     line says so, with how many, and Apply, Back to the preset and Export work on the whole tree - one
 *     rule class=X+ with the cells instead of one per class, and a class with a rule of its own further
 *     down keeps it. "Same as another class" is for one class and is not offered then. A chip returns to the
 *     class alone.
 *   - Apply, once something changed since the cells were loaded (an untouched class is never rewritten:
 *     a mask like x-x loads as one block and would be written back as two): class=X > grid=..., painted
 *     as one canvas with a letter per compartment in reading order of its first cell
 *     (einv_items_fnc_formatGrid: abbbbbc/abbbbbc/-bbbbb-; a single compartment stays xxxx/x--x or WxH),
 *     blocks as 6x4+xxx/x-x (fnc_upsertRule), and - once the picture was changed - icon=ZOOM@ACROSS:DOWN and
 *     picture=PATH, which Apply also writes alone. Discard drops the edits, Back to the preset takes the
 *     class's own grid, like=, icon and picture away.
 *   - "Same as another class..." picks a class in a popover (fnc_drawSameAs) to follow (like=) or to copy
 *     the cells of. Following, the drawing shows that class's cells and cannot be changed; a chip says so
 *     and unlinks.
 *   - A kit of Enhanced First Aid Kits (kind "kit") is edited like any container, always with the instance
 *     classes that mod makes of it (fnc_editScope: class=X+). Until a rule or its config gives it a grid
 *     its room is that mod's capacity (fnc_kitRoom): "Now" says "capacity 35 (EFAK)" and a note says what
 *     Apply changes - the cells drawn here, by its capacity, are only a start. With a grid, "Now" shows it
 *     and a note says the capacity no longer counts; Back to the preset returns it to the capacity.
 *
 * Edits go into a working copy per class (GVAR(cellWork), lowercase class -> a painted canvas, or
 * "blocks" and "picked" for the Blocks way; "unlink" when Apply is to take like= away too, after cells
 * were copied) and reach the draft only with Apply. A grid laid out by load or by a pattern (pockets,
 * rig) is shown as the compartments it gives; editing it writes those cells instead, which the editor
 * says.
 *
 * The first change makes the working copy and draws this side again - it then says the edit is not
 * applied and offers Discard -; any later one changes only that place, the total and the preview, at
 * once. Everything else draws this side again on its own (it keeps its place and arguments in uiNamespace
 * QGVAR(editorArgs)) and keeps where the drawing was scrolled; the list stays.
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
uiNamespace setVariable [QGVAR(previewArgs), []];

// Where the drawing was scrolled: drawn again for the same class, it stays there.
private _oldCanvas = uiNamespace getVariable [QGVAR(cellCanvas), controlNull];
private _scroll = [uiNamespace getVariable [QGVAR(cellCanvasClass), ""], -1];

if (!isNull _oldCanvas) then {
    _scroll set [1, (ctrlScrollValues _oldCanvas) select 0];
};

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

([_class] call FUNC(classBlocks)) params ["_info", "_resolved"];

private _kind = _info getOrDefault ["kind", ""];

if !(_kind in CONTAINER_KINDS) exitWith {
    [_display, _box, [_innerX, _cursorY, _innerW], format [LLSTRING(Cont_NotContainer), _class], TEXT_BODY, _loss, _font] call FUNC(uiText);
};

_class = _info get "class";

private _lc = toLowerANSI _class;
([] call FUNC(ownClassRules)) params ["_exactRules", "", "_treeRules"];
private _own = _exactRules getOrDefault [_lc, createHashMap];

// For the class alone, or for it and everything built on it (the tree view picked it) - a kit always with
// its instances.
(["containers", _class] call FUNC(editScope)) params ["_tree", "_below"];

// A kit: "capacity" while that mod's capacity is its room, "cells" once a grid of its own is.
private _kitRoom = [_info] call FUNC(kitRoom);

private _like = _own getOrDefault ["like", ""];
private _spec = _info getOrDefault ["grid", ["auto"]];
private _src = (_info getOrDefault ["src", createHashMap]) getOrDefault ["grid", "builtin"];
private _maxLoad = _info getOrDefault ["maxLoad", 0];
private _blocksMode = GVAR(cellMode) == 1;
private _work = GVAR(cellWork) getOrDefault [_lc, createHashMap];
private _hasWork = count _work > 0;

// Following another class with no cells of its own: that class's cells, shown as they are. Cells
// copied in (a working copy) can be drawn on even so - Apply then unlinks.
private _linked = _like isNotEqualTo "" && {!("grid" in _own)} && {!_hasWork};
private _editable = !_linked;

// A working copy made the other way is turned into this one.
if (_hasWork && {("blocks" in _work) isNotEqualTo _blocksMode}) then {
    private _unlink = _work getOrDefault ["unlink", false];

    if (_blocksMode) then {
        _work = createHashMapFromArray [
            ["blocks", ([_work] call FUNC(canvasBlocks)) apply {[_x select 0, _x select 1, _x select 2]}], ["picked", 0]
        ];
    } else {
        _work = [_work get "blocks", 1, CANVAS_ROWS_LOADED, STORAGE_COLS, true] call FUNC(canvasFromBlocks);
    };

    _work set ["unlink", _unlink];
    GVAR(cellWork) set [_lc, _work];
};

// What is drawn, and the compartments it gives: the working copy, else what it has now.
private _canvas = createHashMap;
private _shown = [];
private _picked = 0;
private _blocks = [];
private _start = [];

if (_blocksMode) then {
    _start = _resolved apply {[_x select 0, _x select 1, _x select 2]};
    _shown = [_start, _work getOrDefault ["blocks", []]] select _hasWork;
    _picked = (_work getOrDefault ["picked", 0]) min ((count _shown - 1) max 0);
    _blocks = _shown select {(_x select 0) * (_x select 1) > count (_x select 2)};
} else {
    private _loaded = [_resolved, 1, CANVAS_ROWS_LOADED, STORAGE_COLS, true] call FUNC(canvasFromBlocks);

    _start = [_loaded] call FUNC(canvasBlocks);
    _canvas = [_loaded, _work] select _hasWork;
    _blocks = [_canvas] call FUNC(canvasBlocks);
};

// Both ways give the preview (fnc_drawPreview, through fnc_cellChanged) the same kind of thing. While
// nothing is changed, the class's own compartments as the inventory has them, places included. Once it is,
// what the working copy would write: painted compartments that lie as the inventory would flow them come
// back from fnc_canvasBlocks as flowed blocks, so one configuration looks alike whichever way it is drawn.
if (!_hasWork) then {
    _blocks = _resolved select {(_x select 0) * (_x select 1) > count (_x select 2)};
};

private _dirty = _hasWork && {(_blocksMode && {_shown isNotEqualTo _start}) || {!_blocksMode && {_blocks isNotEqualTo _start}}};

// The picture of the box: how it is drawn (icon=, in whole per cent) and which one (picture=), their working copy
// apart from the cells'.
private _boxWork = GVAR(boxWork) getOrDefault [_lc, createHashMap];
private _startIcon = (_info getOrDefault ["icon", ICON_PLAIN]) apply {round (_x * 100)};
private _startPicture = _info getOrDefault ["pictureOverride", ""];
private _configPicture = _info getOrDefault ["configPicture", ""];
private _workIcon = _boxWork getOrDefault ["iconPercent", _startIcon];
private _workPicture = _boxWork getOrDefault ["pictureText", _startPicture];
private _pictureDirty = _workIcon isNotEqualTo _startIcon || {_workPicture isNotEqualTo _startPicture};
private _ownIcon = "icon" in _own || {_tree && {"icon" in (_treeRules getOrDefault [_lc, createHashMap])}};
private _ownPicture = "picture" in _own || {_tree && {"picture" in (_treeRules getOrDefault [_lc, createHashMap])}};

// ----- What it is -----

private _picH = UNIT * 2.2;
private _picW = SQUARE(_picH);
// A placeholder word or a missing file in the class's config is no picture (einv_gui_fnc_safePicture).
private _picture = [_info getOrDefault ["picture", ""]] call EFUNC(gui,safePicture);

if (_picture isNotEqualTo "") then {
    [_display, _box, [_innerX, _cursorY, _picW, _picH], _picture] call EFUNC(gui,uiPicture);
};

private _textX = _innerX + _picW + SQUARE(UNIT * 0.4);
private _textW = _innerX + _innerW - _textX;
private _byClass = (uiNamespace getVariable [QGVAR(index), createHashMap]) getOrDefault ["byClass", createHashMap];
private _row = _byClass getOrDefault [_lc, []];
private _about = format ["%1 · %2 · %3", _class, localize format ["STR_einv_setup_Kind_%1", _kind], _row param [ROW_MOD, _info getOrDefault ["addon", ""]]];

[
    _display, _box, [_textX, _cursorY, _textW, UNIT * 0.85],
    [_info getOrDefault ["name", _class], _textW, _fontBold, TEXT_HEAD] call EFUNC(gui,fitText), TEXT_HEAD, _colorText, _fontBold, 0
] call EFUNC(gui,uiLabel);

// Export and Import in the corner, beside the lines under the name.
private _toolsW = [_display, _box, [_innerX + _innerW, _cursorY + UNIT * 1.05, UNIT * 1], _theme, "containers", _class, _tree] call FUNC(editorTools);
private _aboutW = _textW - _toolsW - SQUARE(UNIT * 0.3);

[
    _display, _box, [_textX, _cursorY + UNIT * 0.85, _aboutW, UNIT * 0.65],
    [_about, _aboutW, _font, TEXT_SMALL] call EFUNC(gui,fitText), TEXT_SMALL, _muted, _font, 0
] call EFUNC(gui,uiLabel);

[
    _display, _box, [_textX, _cursorY + UNIT * 1.45, _aboutW, UNIT * 0.65],
    format [LLSTRING(Cont_Load), round _maxLoad, (_maxLoad * MASS_TO_KG) toFixed 1], TEXT_SMALL, _colorText2, _font, 0
] call EFUNC(gui,uiLabel);

_cursorY = _cursorY + _picH + UNIT * 0.3;

// ----- For the tree: one rule for the class and everything built on it -----

// A kit's tree is the instances of it that are carried: no class alone to go back to.
if (_tree && {_kitRoom isNotEqualTo ""}) then {
    _cursorY = _cursorY + ([
        _display, _box, [_innerX, _cursorY, _innerW], format [LLSTRING(Scope_KitNote), _info getOrDefault ["name", _class], _below, _class],
        TEXT_SMALL, _accent, _font
    ] call FUNC(uiText)) + UNIT * 0.3;
};

if (_tree && {_kitRoom isEqualTo ""}) then {
    private _chipText = LLSTRING(Scope_OnlyThis);
    private _chipH = UNIT * 0.95;
    private _chipW = SQUARE(_chipH * 0.9) + (_chipText getTextWidth [_fontBold, _chipH * 0.52]) * TEXT_SLACK;

    [_display, _box, [_innerX + _innerW - _chipW, _cursorY, _chipW, _chipH], _chipText, false, _theme, {
        // The edit goes back to the class alone; what was drawn stays.
        GVAR(editScope) set ["containers", "class"];

        [] call FUNC(drawCellEditor);
    }] call FUNC(uiChip);

    _cursorY = _cursorY + (([
        _display, _box, [_innerX, _cursorY, _innerW - _chipW - SQUARE(UNIT * 0.4)], format [LLSTRING(Scope_TreeNote), _info getOrDefault ["name", _class], _below, _class],
        TEXT_SMALL, _accent, _font
    ] call FUNC(uiText)) max _chipH) + UNIT * 0.3;
};

// ----- What the draft makes of it now -----

([_info, "grid", _own] call FUNC(answerText)) params ["_words", "_from"];

private _cellsNow = 0;

{
    _cellsNow = _cellsNow + (_x select 0) * (_x select 1) - count (_x select 2);
} forEach _resolved;

// A kit by its capacity has no compartments yet: its window's grid grows with what it holds.
private _now = if (_kitRoom isEqualTo "capacity") then {
    format ["%1: %2", LLSTRING(Items_Now), format [LLSTRING(Answer_Line), _words, _from]]
} else {
    format [
        "%1: %2 · %3", LLSTRING(Items_Now), format [LLSTRING(Answer_Line), _words, _from], format [LLSTRING(Cont_Blocks), count _resolved, _cellsNow]
    ]
};

_cursorY = _cursorY + ([
    _display, _box, [_innerX, _cursorY, _innerW], _now, TEXT_BODY, [_colorText, _accent] select ((_src select [0, 4]) isEqualTo "own:"), _font
] call FUNC(uiText)) + UNIT * 0.15;

private _likeName = ((_byClass getOrDefault [toLowerANSI _like, []]) param [ROW_NAME, _like]);
private _notes = [];

if (_linked) then {
    _notes pushBack [format [LLSTRING(Cont_LinkedNote), _likeName], _accent];
};

if (!_linked && {_like isNotEqualTo ""}) then {
    _notes pushBack [format [LLSTRING(Cont_LikeRest), _likeName], _muted];
};

switch (true) do {
    // A kit by its capacity: what Apply would change.
    case (_kitRoom isEqualTo "capacity"): {
        _notes pushBack [LLSTRING(Cont_KitNote), _muted];
    };
    case (_editable && {(_spec param [0, ""]) isNotEqualTo "blocks"}): {
        _notes pushBack [LLSTRING(Cont_PatternNote), _muted];
    };
};

if (_kitRoom isEqualTo "cells") then {
    _notes pushBack [LLSTRING(Cont_KitCellsNote), _muted];
};

if (_editable && {_blocksMode} && {_resolved findIf {(_x select 3) isNotEqualTo []} >= 0}) then {
    _notes pushBack [LLSTRING(Cont_BlocksFlowNote), _muted];
};

if ((_src select [0, 7]) isEqualTo "legacy:") then {
    _notes pushBack [LLSTRING(Cont_LegacyNote), _loss];
};

{
    _x params ["_text", "_color"];

    _cursorY = _cursorY + ([_display, _box, [_innerX, _cursorY, _innerW], _text, TEXT_SMALL, _color, _font] call FUNC(uiText)) + UNIT * 0.1;
} forEach _notes;

_cursorY = _cursorY + UNIT * 0.2;

// ----- Paint or Blocks; the class it follows -----

private _modeH = UNIT * 1;
private _modeW = SQUARE(UNIT * 8);

[
    _display, _box, [_innerX, _cursorY, _modeW, _modeH], [LLSTRING(Cont_ModePaint), LLSTRING(Cont_ModeBlocks)], GVAR(cellMode), _theme, {
        params ["_index"];

        // The working copy is turned into the other way when the editor is drawn.
        GVAR(cellMode) = _index;

        [] call FUNC(drawCellEditor);
    }
] call FUNC(uiSegmented);

if (_like isNotEqualTo "") then {
    private _chipText = format [LLSTRING(Cont_SameChip), _likeName];
    private _chipW = (SQUARE(_modeH * 0.9) + (_chipText getTextWidth [_fontBold, _modeH * 0.52]) * TEXT_SLACK) min (_innerW - _modeW - SQUARE(UNIT * 0.5));

    [_display, _box, [_innerX + _innerW - _chipW, _cursorY, _chipW, _modeH], _chipText, true, _theme, {
        params ["", "_class"];

        // Only like= goes: cells being drawn stay.
        [format [LLSTRING(Hint_Unlinked), _class], "text2"] call FUNC(setHint);
        [_class, createHashMap, ["like"]] call FUNC(upsertRule);
    }, _class] call FUNC(uiChip);
};

_cursorY = _cursorY + _modeH + UNIT * 0.3;

// ----- Where the drawing, the preview, the total and the buttons go -----

private _toolH = UNIT * 1.1;
private _buttonH = UNIT * 1.15;
private _buttonsY = _height - CARD_PAD_Y - _buttonH;
private _totalsH = UNIT * 0.8;
private _totalsY = _buttonsY - UNIT * 0.25 - _totalsH;
// The same cell as the Blocks way draws (fnc_drawCellBlocks), so switching the way never resizes the places.
// A whole number of pixels: every place then has the same size and the same gap to the next.
private _cellH = floor (UNIT * 0.95 / pixelH + 0.001) * pixelH;
private _canvasW = STORAGE_COLS * SQUARE(_cellH) + SCROLL_W + SQUARE(UNIT * 0.2);
private _areaY = _cursorY;

if (_editable) then {
    _areaY = _cursorY + _toolH + UNIT * 0.25;
    _areaY = _areaY + ([
        _display, _box, [_innerX, _areaY, _innerW], [LLSTRING(Cont_PaintHelp), LLSTRING(Cont_BlocksHelp)] select _blocksMode, TEXT_SMALL, _muted, _font
    ] call FUNC(uiText)) + UNIT * 0.2;
};

private _areaH = (_totalsY - UNIT * 0.2 - _areaY) max (UNIT * 2);
private _area = controlNull;

if (_blocksMode) then {
    _area = [
        _display, _box, [_innerX, _cursorY, _innerW, _toolH], [_innerX, _areaY, _canvasW, _areaH], _theme, _class, _shown, _picked, _editable
    ] call FUNC(drawCellBlocks);
} else {
    // ----- Paint: the brushes, the rows, Fill and Clear -----

    if (_editable) then {
        private _dotH = UNIT * 0.95;
        private _dotW = SQUARE(_dotH);
        private _dotGap = SQUARE(UNIT * 0.2);
        private _dotY = _cursorY + (_toolH - _dotH) / 2;
        private _toolX = _innerX;

        // The eight colours, then none - a ring round the brush.
        {
            private _value = _x;
            private _colors = if (_value > 0) then {[PAINT_COLORS select (_value - 1), PAINT_HOVER select (_value - 1)]} else {[CANVAS_OFF, CANVAS_OFF_HOVER]};
            private _dot = [_toolX, _dotY, _dotW, _dotH];
            private _surface = [_display, _box, _dot, _colors select 0, _dotH / 2] call EFUNC(gui,uiPanel);

            if (_value == 0) then {
                [_display, _box, [_toolX + _dotW * 0.2, _dotY + _dotH * 0.2, _dotW * 0.6, _dotH * 0.6], UI_TEX(icon_close_ca), _colorText] call EFUNC(gui,uiIcon);
            };

            if (_value == GVAR(cellBrush)) then {
                [
                    _display, _box, [_toolX - pixelW * 2, _dotY - pixelH * 2, _dotW + pixelW * 4, _dotH + pixelH * 4], _colorText, _dotH / 2 + pixelH * 2
                ] call EFUNC(gui,uiRing);
            };

            [_display, _box, _dot, _surface, _colors select 0, _colors select 1, {
                params ["_value"];

                GVAR(cellBrush) = _value;

                [] call FUNC(drawCellEditor);
            }, [_value], true, if (_value == 0) then {LLSTRING(Paint_None)} else {localize format ["STR_einv_setup_Paint_%1", _value]}] call FUNC(uiHit);

            _toolX = _toolX + _dotW + _dotGap;
        } forEach [1, 2, 3, 4, 5, 6, 7, 8, 0];

        _toolX = _toolX + SQUARE(UNIT * 0.4);

        // Fewer rows cut away what lies below; more add rows without colour.
        private _stepperW = SQUARE(UNIT * 5.4);

        [
            _display, _box, [_toolX, _cursorY, _stepperW, _toolH], _canvas get "rows", [1, MAX_ROWS max (_canvas get "rows"), 1], _theme, {
                params ["_value", "_arguments"];
                _arguments params ["_class", "_canvas"];

                private _paint = _canvas get "paint";
                private _old = count _paint;

                _paint resize ((_canvas get "cols") * _value);

                for "_index" from _old to (count _paint - 1) do {
                    _paint set [_index, 0];
                };

                _canvas set ["rows", _value];
                GVAR(cellWork) set [toLowerANSI _class, _canvas];

                [] call FUNC(drawCellEditor);
            }, [_class, _canvas], LLSTRING(Cont_CanvasRows)
        ] call FUNC(uiStepper);

        _toolX = _toolX + _stepperW + SQUARE(UNIT * 0.4);

        {
            _x params ["_text", "_tip", "_fill", "_enabled"];

            private _buttonW = ACTION_W(_text,_toolH,false,_font);

            [_display, _box, [_toolX, _cursorY, _buttonW, _toolH], _text, "", _theme, {
                params ["_class", "_canvas", "_fill"];

                // Fill paints only the empty places: what is painted stays as it is.
                _canvas set ["paint", (_canvas get "paint") apply {[0, [_x, GVAR(cellBrush)] select (_x == 0)] select _fill}];
                GVAR(cellWork) set [toLowerANSI _class, _canvas];

                [] call FUNC(drawCellEditor);
            }, [_class, _canvas, _fill], _enabled, "ghost", _tip] call FUNC(uiAction);

            _toolX = _toolX + _buttonW + SQUARE(UNIT * 0.2);
        } forEach [
            [LLSTRING(Cont_Fill), LLSTRING(Cont_FillTip), true, GVAR(cellBrush) > 0],
            [LLSTRING(Items_Clear), LLSTRING(Cont_ClearTip), false, true]
        ];
    };

    // ----- Paint: the drawing -----

    _area = [_display, _box, [_innerX, _areaY, _canvasW, _areaH], _canvas, _theme, createHashMapFromArray [
        ["cellH", _cellH],
        ["palette", true],
        ["editable", _editable],
        ["scrollId", "cellCanvas"],
        ["arguments", [_class]],
        ["onChange", {
            params ["_canvas", "_arguments"];
            _arguments params ["_class"];

            private _lc = toLowerANSI _class;

            // The first change: the working copy, and the editor drawn again to say so.
            if !(_lc in GVAR(cellWork)) exitWith {
                GVAR(cellWork) set [_lc, _canvas];

                [] call FUNC(drawCellEditor);
            };

            [[_canvas] call FUNC(canvasBlocks)] call FUNC(cellChanged);
        }]
    ]] call FUNC(uiCanvas);
};

uiNamespace setVariable [QGVAR(cellCanvas), _area];
uiNamespace setVariable [QGVAR(cellCanvasClass), _lc];

if ((_scroll select 0) isEqualTo _lc && {(_scroll select 1) > 0} && {!isNull _area}) then {
    [{
        params ["_ctrl", "_value"];

        if (!isNull _ctrl) then {
            _ctrl ctrlSetScrollValues [_value, -1];
        };
    }, [_area, _scroll select 1]] call FUNC(defer);
};

// ----- Beside it how the inventory shows it; under it the total -----

private _sideX = _innerX + _canvasW + SQUARE(UNIT * 0.5);
private _sideW = _innerX + _innerW - _sideX;

[_display, _box, [_sideX, _areaY, _sideW, UNIT * 0.75], LLSTRING(Preview_Title), TEXT_SMALL, _muted, _fontBold, 0] call EFUNC(gui,uiLabel);

// Under the preview of the cells: the picture row, and the box as the window draws it with its zoom and shift.
private _rowH = UNIT * 1.1;
private _pictureBlockH = _rowH + UNIT * 0.3 + ICON_BLOCK_H;
private _previewH = (_areaH - UNIT * 0.8 - _pictureBlockH - UNIT * 0.3) max (UNIT * 3);
private _blockY = _areaY + UNIT * 0.8 + _previewH + UNIT * 0.3;

uiNamespace setVariable [QGVAR(previewArgs), [_display, _box, [_sideX, _areaY + UNIT * 0.8, _sideW, _previewH]]];

[
    _display, _box, [_sideX, _blockY, _sideW, _rowH], _theme, SQUARE(UNIT * 3), _workPicture, _configPicture, {
        params ["_path", "_arguments"];
        _arguments params ["_class", "_boxWork"];

        _boxWork set ["pictureText", _path];
        GVAR(boxWork) set [toLowerANSI _class, _boxWork];

        [] call FUNC(drawCellEditor);
    }, [_class, _boxWork]
] call FUNC(drawPictureRow);

// What the box shows: the picture set in the working copy while the game has the file; a uniform, vest or backpack
// config's own otherwise, a crate or vehicle the editor's picture.
private _boxOwn = "";

if (_workPicture isNotEqualTo "") then {
    _boxOwn = [_workPicture] call EFUNC(gui,safePicture);
};

if (_boxOwn isEqualTo "" && {!(_kind in ["crate", "vehicle"])}) then {
    _boxOwn = [_configPicture] call EFUNC(gui,safePicture);
};

private _boxSide = ICON_BLOCK_H;
private _boxY = _blockY + _rowH + UNIT * 0.3;

[_display, _box, [_sideX, _boxY, SQUARE(_boxSide), _boxSide], _theme, _class, _boxOwn, _workIcon apply {_x / 100}] call FUNC(drawBoxPreview);

private _iconX = _sideX + SQUARE(_boxSide) + SQUARE(UNIT * 0.6);

[
    _display, _box, [_iconX, _boxY, _sideX + _sideW - _iconX], _theme, _workIcon, {
        params ["_icon", "_arguments"];
        _arguments params ["_class", "_boxWork"];

        _boxWork set ["iconPercent", _icon];
        GVAR(boxWork) set [toLowerANSI _class, _boxWork];

        [] call FUNC(drawCellEditor);
    }, [_class, _boxWork]
] call FUNC(drawIconBlock);

private _totals = [_display, _box, [_innerX, _totalsY, _innerW, _totalsH], "", TEXT_SMALL, _colorText2, _font, 0] call EFUNC(gui,uiLabel);

uiNamespace setVariable [QGVAR(cellTotals), _totals];

[_blocks] call FUNC(cellChanged);

// Beside the total rather than above the drawing: the drawing must not move under the mouse after the
// first click.
if (_dirty || _pictureDirty) then {
    [_display, _box, [_innerX, _totalsY, _innerW, _totalsH], LLSTRING(Cont_Unapplied), TEXT_SMALL, _warn, _font, 1] call EFUNC(gui,uiLabel);
};

// ----- Apply, Discard, Back to the preset; Same as another class -----

private _gap = SQUARE(UNIT * 0.3);
private _buttonX = _innerX;

if (_editable || _pictureDirty) then {
    private _buttonW = ACTION_W(LLSTRING(Cont_Apply),_buttonH,true,_font);

    [_display, _box, [_buttonX, _buttonsY, _buttonW, _buttonH], LLSTRING(Cont_Apply), UI_TEX(icon_check_ca), _theme, {
        params ["_class", "_tree", "_below", "_gridDirty", "_startIcon", "_startPicture", "_ownIcon", "_ownPicture"];

        private _lc = toLowerANSI _class;
        private _work = GVAR(cellWork) getOrDefault [_lc, createHashMap];
        private _set = createHashMap;
        private _remove = [];

        // The cells, when they were changed.
        if (_gridDirty) then {
            private _blocks = if ("blocks" in _work) then {
                // A compartment left without a single cell cannot be written (einv_items_fnc_parseGrid): it goes.
                (_work get "blocks") select {(_x select 0) * (_x select 1) > count (_x select 2)}
            } else {
                [_work] call FUNC(canvasBlocks)
            };
            private _cells = 0;

            {
                _cells = _cells + (_x select 0) * (_x select 1) - count (_x select 2);
            } forEach _blocks;

            if (_blocks isEqualTo []) exitWith {
                [LLSTRING(Hint_NoCells), "loss"] call FUNC(setHint);
            };

            if (_cells > MAX_CELLS || {count _blocks > MAX_BLOCKS}) exitWith {
                [format [LLSTRING(Hint_TooMany), MAX_CELLS, MAX_BLOCKS], "loss"] call FUNC(setHint);
            };

            // Only a drawing loaded taller than MAX_ROWS can hold one this tall. Painted compartments are
            // written as one canvas where they lie (einv_items_fnc_formatGrid), so it is the drawing that must fit.
            if (_blocks findIf {((_x param [3, []]) param [1, 0]) + (_x select 1) > MAX_ROWS} >= 0) exitWith {
                [format [LLSTRING(Hint_TooTall), MAX_ROWS], "loss"] call FUNC(setHint);
            };

            _set set ["grid", [["blocks", _blocks]] call EFUNC(items,formatGrid)];

            if (_work getOrDefault ["unlink", false]) then {
                _remove pushBack "like";
            };
        };

        if (_gridDirty && {!("grid" in _set)}) exitWith {};

        // The picture of the box (icon=, picture=), in per cent: only what differs from now, as the Items step
        // writes it.
        private _boxWork = GVAR(boxWork) getOrDefault [_lc, createHashMap];
        private _icon = _boxWork getOrDefault ["iconPercent", _startIcon];

        if (_icon isNotEqualTo _startIcon) then {
            private _modIcon = ((([_class] call EFUNC(items,getFacts)) get "mod") getOrDefault ["icon", ICON_PLAIN]) isNotEqualTo ICON_PLAIN;

            if (_icon isEqualTo ICON_PERCENT_PLAIN && {_ownIcon} && {!_modIcon}) then {
                _remove pushBack "icon";
            } else {
                _set set ["icon", _icon apply {_x / 100}];
            };
        };

        private _picture = _boxWork getOrDefault ["pictureText", _startPicture];

        if (_picture isNotEqualTo _startPicture) then {
            if (_picture isNotEqualTo "") then {
                _set set ["picture", _picture];
            } else {
                private _facts = [_class] call EFUNC(items,getFacts);
                private _modPicture = ((_facts get "mod") getOrDefault ["picture", ""]) isNotEqualTo "";
                private _configPath = ([_facts getOrDefault ["picture", ""], false] call EFUNC(items,parsePicture)) select 0;

                if (_modPicture && {_configPath isNotEqualTo ""}) then {
                    _set set ["picture", _configPath];
                } else {
                    if (_ownPicture) then {
                        _remove pushBack "picture";
                    };
                };
            };
        };

        GVAR(cellWork) deleteAt _lc;
        GVAR(boxWork) deleteAt _lc;

        if (count _set == 0 && {_remove isEqualTo []}) exitWith {
            [LLSTRING(Hint_NothingToApply), "text2"] call FUNC(setHint);
            [] call FUNC(drawCellEditor);
        };

        [[
            format [[LLSTRING(Hint_PictureApplied), LLSTRING(Hint_CellsApplied)] select _gridDirty, _class],
            format [LLSTRING(Hint_TreeApplied), _class, _below]
        ] select _tree, "text2"] call FUNC(setHint);
        [_class, _set, _remove, _tree] call FUNC(upsertRule);
    // Greyed while nothing is painted: Apply would only refuse (Hint_NoCells), and the tooltip says what it is for.
    }, [_class, _tree, _below, _dirty, _startIcon, _startPicture, _ownIcon, _ownPicture], (_dirty && {_blocks isNotEqualTo []}) || _pictureDirty, "accent", [LLSTRING(Cont_ApplyTip), LLSTRING(Cont_ApplyTipTree)] select _tree] call FUNC(uiAction);

    _buttonX = _buttonX + _buttonW + _gap;
};

if (_dirty || _pictureDirty) then {
    private _buttonW = ACTION_W(LLSTRING(Cont_Discard),_buttonH,false,_font);

    [_display, _box, [_buttonX, _buttonsY, _buttonW, _buttonH], LLSTRING(Cont_Discard), "", _theme, {
        params ["_class"];

        GVAR(cellWork) deleteAt (toLowerANSI _class);
        GVAR(boxWork) deleteAt (toLowerANSI _class);

        [] call FUNC(drawCellEditor);
    }, [_class], true, "ghost"] call FUNC(uiAction);

    _buttonX = _buttonX + _buttonW + _gap;
};

// Something of its own to take away: its own rule, or - for the tree - the tree's.
private _ownFields = ["grid", "like", "icon", "picture"];
private _hasOwn = (_ownFields findIf {_x in _own}) >= 0;

if (_tree) then {
    private _treeOwn = _treeRules getOrDefault [_lc, createHashMap];

    _hasOwn = _hasOwn || {(_ownFields findIf {_x in _treeOwn}) >= 0};
};

if (_hasOwn) then {
    private _buttonW = ACTION_W(LLSTRING(Groups_Reset),_buttonH,true,_font);

    [_display, _box, [_buttonX, _buttonsY, _buttonW, _buttonH], LLSTRING(Groups_Reset), UI_TEX(icon_reset_ca), _theme, {
        params ["_class", "_tree", "_below", "_ownFields"];

        GVAR(cellWork) deleteAt (toLowerANSI _class);
        GVAR(boxWork) deleteAt (toLowerANSI _class);

        [[format [LLSTRING(Hint_Reset), _class], format [LLSTRING(Hint_TreeReset), _class, _below]] select _tree, "text2"] call FUNC(setHint);
        [_class, createHashMap, _ownFields, _tree] call FUNC(upsertRule);
    }, [_class, _tree, _below, _ownFields], true, "ghost", [LLSTRING(Cont_ResetTip), LLSTRING(Cont_ResetTipTree)] select _tree] call FUNC(uiAction);

    _buttonX = _buttonX + _buttonW + _gap;
};

// Same as another class: a popover picks it (fnc_drawSameAs). For one class: a tree has no single class to
// follow or copy for.
if (!_tree) then {
    // The long label where it fits, else the short one.
    private _sameText = LLSTRING(Cont_SameAs);
    private _sameW = ACTION_W(_sameText,_buttonH,true,_font);

    if (_sameW > _innerX + _innerW - _buttonX) then {
        _sameText = LLSTRING(Cont_SameAsShort);
        _sameW = ACTION_W(_sameText,_buttonH,true,_font);
    };

    private _same = [
        _display, _box, [_innerX + _innerW - _sameW, _buttonsY, _sameW, _buttonH], _sameText, UI_TEX(icon_swap_ca), _theme, {}, [], true, "", LLSTRING(Cont_SameAsTip)
    ] call FUNC(uiAction);
    private _sameHit = _same select (count _same - 1);

    _sameHit setVariable [QGVAR(action), [{
        params ["_hit", "_class"];

        GVAR(sameAs) = createHashMapFromArray [["target", _class], ["text", ""], ["page", 0], ["picked", ""]];

        [
            uiNamespace getVariable [QGVAR(display), displayNull], [_hit] call FUNC(screenRect), [SQUARE(UNIT * 19), UNIT * 13.4], LLSTRING(Same_Title), {
                params ["_display", "_inner", "_theme"];

                uiNamespace setVariable [QGVAR(sameAsArgs), [_display, _inner, _theme]];

                ["all"] call FUNC(drawSameAs);
            }
        ] call FUNC(popover);
    }, [_sameHit, _class]]];
};
