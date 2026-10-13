#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The right side of the Containers step: the cells of the container picked in the list, to draw.
 *   - What it is (picture, name, class, kind, mod, load) and what the draft makes of it now, with where
 *     that comes from (fnc_answerText) and how many compartments and cells that gives.
 *   - One canvas for all of it (fnc_uiCanvas), STORAGE_COLS wide and as many rows as the stepper says
 *     (up to MAX_ROWS), scrolling when tall: a click on a place makes it a cell or takes the cell away, a
 *     click on the gap between two places puts a divider on that seam or takes it away. Cells that touch
 *     with no divider between them are one compartment (fnc_canvasBlocks). Fill makes every place a cell,
 *     Clear takes every cell and divider away.
 *   - The class's compartments are laid on it as the inventory lays them out (fnc_canvasFromBlocks): side
 *     by side, then on the next line, a divider wherever two meet, their holes places without a cell.
 *   - Beside it how the inventory will show them (fnc_drawPreview), and under it the total of cells and
 *     compartments against the limits (MAX_CELLS, MAX_BLOCKS).
 *   - Apply writes each compartment as the box around its cells, the rest of the box holes, joined with
 *     "+" in reading order: class=X > grid=xxxx/x--x+2x3 (fnc_upsertRule); a full rectangle stays WxH.
 *     Discard drops the edits, Back to the preset takes the class's own grid and like= away. "Like another
 *     class" lets the list pick the class this one takes its cells from (like=Y): the canvas then shows
 *     that class's cells and cannot be drawn on, until Unlink.
 *
 * Edits go into a working copy per class (GVAR(cellWork): lowercase class -> the canvas, with "start" -
 * the compartments it held when it was made) and reach the draft only with Apply. A grid laid out by load
 * or by a pattern (pockets, rig) is shown as the compartments it gives; editing it writes those cells
 * instead, which the editor says.
 *
 * The first click makes the working copy and draws this side again - it then says the edit is not applied
 * and offers Discard -; any later one changes only that place or seam, the total and the preview, at
 * once. Everything else draws this side again on its own (it keeps its place and arguments in uiNamespace
 * QGVAR(editorArgs)) and keeps where the canvas was scrolled; the list stays.
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

// Where the canvas was scrolled: drawn again for the same class, it stays there.
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
private _canvas = GVAR(cellWork) getOrDefault [_lc, createHashMap];
private _useWork = !_linked && {count _canvas > 0};

if (!_useWork) then {
    _canvas = [_resolved] call FUNC(canvasFromBlocks);
    _canvas set ["start", [_canvas] call FUNC(canvasBlocks)];
};

private _blocks = [_canvas] call FUNC(canvasBlocks);
private _dirty = _useWork && {_blocks isNotEqualTo (_canvas getOrDefault ["start", []])};
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

{
    _x params ["_text", "_color"];

    _cursorY = _cursorY + ([_display, _box, [_innerX, _cursorY, _innerW], _text, TEXT_SMALL, _color, _font] call FUNC(uiText)) + UNIT * 0.1;
} forEach _notes;

_cursorY = _cursorY + UNIT * 0.2;

// ----- The canvas's rows, Fill and Clear -----

if (_editable) then {
    private _toolH = UNIT * 1.1;
    private _gap = SQUARE(UNIT * 0.3);
    private _stepperW = SQUARE(UNIT * 5.4);
    private _rows = _canvas get "rows";

    // Fewer rows cut away what lies below; more add rows without a cell.
    [
        _display, _box, [_innerX, _cursorY, _stepperW, _toolH], _rows, [1, MAX_ROWS max _rows, 1], _theme, {
            params ["_value", "_arguments"];
            _arguments params ["_class", "_canvas"];

            private _count = (_canvas get "cols") * _value;

            {
                private _list = _canvas get _x;
                private _old = count _list;

                _list resize _count;

                for "_index" from _old to (_count - 1) do {
                    _list set [_index, false];
                };
            } forEach ["cells", "right", "below"];

            _canvas set ["rows", _value];
            GVAR(cellWork) set [toLowerANSI _class, _canvas];

            [] call FUNC(drawCellEditor);
        }, [_class, _canvas], LLSTRING(Cont_CanvasRows)
    ] call FUNC(uiStepper);

    private _toolX = _innerX + _stepperW + SQUARE(UNIT * 0.6);

    {
        _x params ["_text", "_tip", "_fill"];

        private _buttonW = SQUARE(_toolH * 0.6) + (_text getTextWidth [_font, _toolH * 0.5]) * TEXT_SLACK;

        [_display, _box, [_toolX, _cursorY, _buttonW, _toolH], _text, "", _theme, {
            params ["_class", "_canvas", "_fill"];

            _canvas set ["cells", (_canvas get "cells") apply {_fill}];

            // Clear starts afresh: the dividers go too. Fill keeps them, so compartments drawn stay apart.
            if (!_fill) then {
                _canvas set ["right", (_canvas get "right") apply {false}];
                _canvas set ["below", (_canvas get "below") apply {false}];
            };

            GVAR(cellWork) set [toLowerANSI _class, _canvas];

            [] call FUNC(drawCellEditor);
        }, [_class, _canvas, _fill], true, "ghost", _tip] call FUNC(uiAction);

        _toolX = _toolX + _buttonW + _gap;
    } forEach [[LLSTRING(Cont_Fill), LLSTRING(Cont_FillTip), true], [LLSTRING(Items_Clear), LLSTRING(Cont_ClearTip), false]];

    _cursorY = _cursorY + _toolH + UNIT * 0.25;

    _cursorY = _cursorY + ([_display, _box, [_innerX, _cursorY, _innerW], LLSTRING(Cont_CanvasHelp), TEXT_SMALL, _muted, _font] call FUNC(uiText)) + UNIT * 0.2;
};

// ----- The canvas, and beside it how the inventory shows it -----

private _buttonH = UNIT * 1.15;
private _buttonsY = _height - CARD_PAD_Y - _buttonH;
private _totalsH = UNIT * 0.8;
private _totalsY = _buttonsY - UNIT * 0.25 - _totalsH;
private _areaH = (_totalsY - UNIT * 0.2 - _cursorY) max (UNIT * 2);
private _cellH = UNIT * 1.05;
private _canvasW = STORAGE_COLS * SQUARE(_cellH) + SCROLL_W + SQUARE(UNIT * 0.2);

private _canvasCtrl = [_display, _box, [_innerX, _cursorY, _canvasW, _areaH], _canvas, _theme, createHashMapFromArray [
    ["cellH", _cellH],
    ["dividers", true],
    ["editable", _editable],
    ["scrollId", "cellCanvas"],
    ["arguments", [_class]],
    ["onChange", {
        params ["_canvas", "_arguments"];
        _arguments params ["_class"];

        private _lc = toLowerANSI _class;

        if !(_lc in GVAR(cellWork)) exitWith {
            GVAR(cellWork) set [_lc, _canvas];

            [] call FUNC(drawCellEditor);
        };

        private _blocks = [_canvas] call FUNC(canvasBlocks);
        private _cells = 0;

        {
            _cells = _cells + (_x select 0) * (_x select 1) - count (_x select 2);
        } forEach _blocks;

        private _totals = uiNamespace getVariable [QGVAR(cellTotals), controlNull];

        _totals ctrlSetText format [LLSTRING(Cont_Totals), _cells, MAX_CELLS, count _blocks, MAX_BLOCKS];
        _totals ctrlSetTextColor ([
            GVAR(theme) getOrDefault ["text2", [0.698, 0.734, 0.784, 1]], GVAR(theme) getOrDefault ["loss", [0.941, 0.333, 0.353, 1]]
        ] select (_cells < 1 || {_cells > MAX_CELLS} || {count _blocks > MAX_BLOCKS}));

        (uiNamespace getVariable [QGVAR(previewArgs), []]) params [["_display", displayNull], ["_box", controlNull], ["_rect", []]];

        if (!isNull _box) then {
            [_display, _box, _rect, GVAR(theme), _blocks] call FUNC(drawPreview);
        };
    }]
]] call FUNC(uiCanvas);

uiNamespace setVariable [QGVAR(cellCanvas), _canvasCtrl];
uiNamespace setVariable [QGVAR(cellCanvasClass), _lc];

if ((_scroll select 0) isEqualTo _lc && {(_scroll select 1) > 0}) then {
    [{
        params ["_ctrl", "_value"];

        if (!isNull _ctrl) then {
            _ctrl ctrlSetScrollValues [_value, -1];
        };
    }, [_canvasCtrl, _scroll select 1]] call FUNC(defer);
};

private _sideX = _innerX + _canvasW + SQUARE(UNIT * 0.5);
private _sideW = _innerX + _innerW - _sideX;

[_display, _box, [_sideX, _cursorY, _sideW, UNIT * 0.75], LLSTRING(Preview_Title), TEXT_SMALL, _muted, _fontBold, 0] call EFUNC(gui,uiLabel);

private _previewRect = [_sideX, _cursorY + UNIT * 0.8, _sideW, _areaH - UNIT * 0.8];

uiNamespace setVariable [QGVAR(previewArgs), [_display, _box, _previewRect]];

[_display, _box, _previewRect, _theme, _blocks] call FUNC(drawPreview);

// ----- The total, against the limits; whether it is applied -----

private _cells = 0;

{
    _cells = _cells + (_x select 0) * (_x select 1) - count (_x select 2);
} forEach _blocks;

private _totals = [
    _display, _box, [_innerX, _totalsY, _innerW, _totalsH], format [LLSTRING(Cont_Totals), _cells, MAX_CELLS, count _blocks, MAX_BLOCKS],
    TEXT_SMALL, [_colorText2, _loss] select (_cells < 1 || {_cells > MAX_CELLS} || {count _blocks > MAX_BLOCKS}), _font, 0
] call EFUNC(gui,uiLabel);

uiNamespace setVariable [QGVAR(cellTotals), _totals];

// Beside the total rather than above the canvas: the canvas must not move under the mouse after the
// first click.
if (_dirty) then {
    [_display, _box, [_innerX, _totalsY, _innerW, _totalsH], LLSTRING(Cont_Unapplied), TEXT_SMALL, _warn, _font, 1] call EFUNC(gui,uiLabel);
};

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
        params ["_class", "_canvas"];

        private _lc = toLowerANSI _class;
        private _blocks = [_canvas] call FUNC(canvasBlocks);
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

        // Only a canvas loaded taller than MAX_ROWS can hold one this tall.
        if (_blocks findIf {(_x select 1) > MAX_ROWS} >= 0) exitWith {
            [format [LLSTRING(Hint_TooTall), MAX_ROWS], "loss"] call FUNC(setHint);
        };

        GVAR(cellWork) deleteAt _lc;

        [format [LLSTRING(Hint_CellsApplied), _class], "text2"] call FUNC(setHint);
        [_class, createHashMapFromArray [["grid", [["blocks", _blocks]] call EFUNC(items,formatGrid)]]] call FUNC(upsertRule);
    }, [_class, _canvas], true, "accent", LLSTRING(Cont_ApplyTip)] call FUNC(uiAction);

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
