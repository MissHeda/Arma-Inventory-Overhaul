#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The right side of the Items step: the size, shape, stack, weight, name, picture and picture zoom of the class
 * picked in the list.
 *   - What it is (picture, name, class, family, mod, weight) and what the draft makes of it now, with
 *     where that comes from (fnc_answerText). In the corner Export and Import (fnc_editorTools).
 *   - Its width and height in cells (1-8) for a quick rectangle, and how many share a tile (1-999, with
 *     a few common numbers to pick at once). Weapons, uniforms, vests and backpacks never share a tile -
 *     their stack cannot be set.
 *   - Its weight in kg and its name, two fields (empty: config's own stays): typing changes the working
 *     copy at once and Return draws this side again.
 *   - Under the name a Picture row (fnc_drawPictureRow): the texture the item shows - the one set for it, else
 *     config's, greyed - with "Pick..." (the picture picker, fnc_openPicturePicker: every picture of the game's
 *     items to search and click, or any texture path typed in) and Reset. What is picked goes into the working
 *     copy as "pictureText", the tile preview and the canvas show it at once, and Apply writes picture=PATH.
 *   - Beside the size, the stack, the weight, the name and the use a small reset button (fnc_uiReset), there only
 *     while the value differs from what the draft would make of the class without its own rule for it
 *     (fnc_classDefault): a click takes that field back at once (fnc_resetField).
 *   - Under the picture a Use from row (fnc_drawUseRow): a chip each for the uniform, vest and backpack, on for the
 *     containers the item is whitelisted for (use=, aio_use) - it may be used from them even where the settings
 *     "Use items from ..." (aio_storage) close them - and a line of what those settings limit now. The working
 *     copy keeps the list as "useList"; Apply writes use=uniform+backpack (use=none for an emptied one).
 *   - Under it a Category row (fnc_drawCatRow): a chip each for the categories (the eight of ITEM_GROUPS and the draft's own), on for the ones the item is in
 *     (cats=, aio_cat, else the built-in one), at least one on; a reset button back to the built-in one. The working copy keeps
 *     the list as "catsList"; Apply writes cats=medical+misc, and takes the class's own cats away when it is the built-in one again.
 *   - Under them the canvas (fnc_uiCanvas), SHAPE_MAX cells each way, always shown: a click makes a place
 *     one of the item's cells or takes it away, so an L or a T is drawn cell by cell. The steppers and the
 *     canvas are one: a stepper lays a rectangle of its size where the cells are - the places that were
 *     in their box keep what they were, the new ones become cells, the rest goes -, and the steppers say
 *     the box of what is drawn. Beside it how it looks as a tile (fnc_drawPreview, which draws the tile with
 *     the inventory's own routine, aio_gui_fnc_createTile, at the inventory's cell size where there is room),
 *     its size in words, and a warning while its cells are not one piece (fnc_canvasBlocks) - then Apply
 *     cannot be pressed.
 *   - Beside that tile its picture (fnc_drawIconBlock): a zoom stepper (25 to 400 %, 1 per click, 10 with
 *     Shift, with 50, 100, 150 and 200 % at one click) and two shift steppers, across and down (-100 to 100 % of
 *     the tile, the same steps), each with a small box to type the number in, with Reset back to the plain picture. The tile follows every click: it is drawn by the working copy, so what is
 *     seen is what Apply writes (icon=, aio_items_fnc_parseIcon). The inventory cuts a picture that would
 *     reach out of its tile at the tile's edge.
 *   - Apply writes what differs from now as class=X > size=WxH, or size=xx/x- for a shape
 *     (aio_items_fnc_formatMask), stack=N, weight=KG, name=..., picture=PATH, use=LIST and icon=ZOOM@ACROSS:DOWN (fnc_upsertRule) - the
 *     rest of that rule stays -, Discard drops the edits, Back to the default takes the class's own size, stack,
 *     weight, name, picture, use and icon away. A field emptied takes its own value away; Reset and Apply take a class's own
 *     icon away, or write the plain picture where the item's config draws it otherwise, and a class's own
 *     picture away, or write config's own picture path where the item's config (aio_picture) sets another.
 *   - Picked in the tree view (fnc_editScope), the edit is for the class and every class built on it: a
 *     line says so, with how many, and Apply, Back to the default and Export work on the whole tree - one
 *     rule class=X+ instead of one per class. A chip returns to the class alone.
 *
 * Edits go into a working copy per class (GVAR(itemWork): lowercase class -> the canvas, with "stack",
 * "weightText", "nameText", "pictureText", "useList", "iconPercent" ([zoom, across, down] in whole per cent) and "start" - what the
 * shape held when it was made) and reach the draft only
 * with Apply. A change draws this side again on its own (its place and arguments in uiNamespace
 * QGVAR(editorArgs)) - there are few controls, an 8x8 canvas -; the list stays.
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
 * [_display, _group, [0.3, 0, 0.4, 0.5], _theme] call aio_setup_fnc_drawItemEditor;
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

private _box = [_display, "AIO_Group", _parent, _rect] call EFUNC(gui,uiCreate);

uiNamespace setVariable [QGVAR(editor), _box];

private _font = _theme getOrDefault ["font", "PuristaMedium"];
private _fontBold = _theme getOrDefault ["fontBold", "PuristaSemibold"];
private _colorText = _theme getOrDefault ["text", [1, 1, 1, 1]];
private _colorText2 = _theme getOrDefault ["text2", [0.78, 0.78, 0.78, 1]];
private _muted = _theme getOrDefault ["muted", [0.56, 0.56, 0.56, 1]];
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
([] call FUNC(ownClassRules)) params ["_exactRules", "", "_treeRules"];
private _own = _exactRules getOrDefault [_lc, createHashMap];
private _src = _info getOrDefault ["src", createHashMap];
private _forced = (_src getOrDefault ["stack", ""]) isEqualTo "forced";

// For the class alone, or for it and everything built on it (the tree view picked it).
(["items", _class] call FUNC(editScope)) params ["_tree", "_below"];

(_info getOrDefault ["size", [1, 1]]) params ["_sizeW", "_sizeH"];

private _startShape = _info getOrDefault ["shape", format ["%1x%2", _sizeW, _sizeH]];
private _startStack = _info getOrDefault ["stack", 1];

// The weight and the name its own rules give it, as the fields write them: nothing for config's own.
private _startWeight = _info getOrDefault ["weightOverride", -1];
private _startWeightText = ["", [_startWeight] call FUNC(weightText)] select (_startWeight >= 0);
private _startName = _info getOrDefault ["nameOverride", ""];

// How its picture is drawn now (icon=), in whole per cent as the steppers count them: [zoom, across, down].
private _startIcon = (_info getOrDefault ["icon", ICON_PLAIN]) apply {round (_x * 100)};

// Whether a rule of the class's own (or the tree's) draws it, which Apply may then take away.
private _ownIcon = "icon" in _own || {_tree && {"icon" in (_treeRules getOrDefault [_lc, createHashMap])}};

// The picture it shows instead of config's (picture=, or the item's own aio_picture): the path, "" for none.
private _startPicture = _info getOrDefault ["pictureOverride", ""];
private _configPicture = _info getOrDefault ["configPicture", ""];
private _ownPicture = "picture" in _own || {_tree && {"picture" in (_treeRules getOrDefault [_lc, createHashMap])}};

// The containers it may be used from where a setting closes them (use=, aio_use): any of uniform, vest, backpack.
private _startUse = _info getOrDefault ["use", []];

// The categories it is in now (cats=, aio_cat, else the built-in one): any category of the draft.
private _startGroups = _info getOrDefault ["groups", ["misc"]];
private _canvas = GVAR(itemWork) getOrDefault [_lc, createHashMap];

// What it would be without its own size, stack, weight, name and use - the values the small reset buttons take a
// field back to. Only worked out where a rule of its own (or its tree's) has any of them: else it is what it is now.
private _resetFields = ["footprint", "stack", "weight", "name", "use", "cats", "tint"];
private _hasOwnField = (_resetFields findIf {_x in _own}) >= 0 || {_tree && {(_resetFields findIf {_x in (_treeRules getOrDefault [_lc, createHashMap])}) >= 0}};
private _default = [_info, [_class, _resetFields] call FUNC(classDefault)] select _hasOwnField;
private _defaultWeight = _default getOrDefault ["weightOverride", -1];
private _defaultWeightText = ["", [_defaultWeight] call FUNC(weightText)] select (_defaultWeight >= 0);

// No edit yet: a canvas of what it is now, its shape in the top left corner. It becomes the working copy
// with the first change.
if (count _canvas == 0) then {
    _canvas = [[_info getOrDefault ["footprint", [_sizeW, _sizeH, []]]], SHAPE_MAX, SHAPE_MAX, SHAPE_MAX] call FUNC(canvasFromBlocks);
    _canvas set ["start", [_canvas] call FUNC(canvasBlocks)];
    _canvas set ["stack", _startStack];
};

private _blocks = [_canvas] call FUNC(canvasBlocks);
private _workStack = _canvas getOrDefault ["stack", _startStack];
private _workWeight = _canvas getOrDefault ["weightText", _startWeightText];
private _workName = _canvas getOrDefault ["nameText", _startName];
private _workIcon = _canvas getOrDefault ["iconPercent", _startIcon];
private _workPicture = _canvas getOrDefault ["pictureText", _startPicture];
private _workUse = _canvas getOrDefault ["useList", _startUse];
private _workCats = _canvas getOrDefault ["catsList", _startGroups];
// The colour of a tile in several categories (tint=): one of them, split, or "" for the first.
if !("tintStart" in _canvas) then {
    _canvas set ["tintStart", _info getOrDefault ["tint", ""]];
};

private _startTint = _canvas get "tintStart";
private _workTint = _canvas getOrDefault ["tintPick", _startTint];

private _dirty = _blocks isNotEqualTo (_canvas getOrDefault ["start", []]) || {_workStack != _startStack}
    || {_workWeight isNotEqualTo _startWeightText} || {_workName isNotEqualTo _startName} || {_workIcon isNotEqualTo _startIcon}
    || {_workPicture isNotEqualTo _startPicture} || {_workUse isNotEqualTo _startUse} || {_workCats isNotEqualTo _startGroups}
    || {_workTint isNotEqualTo _startTint};

([_canvas] call FUNC(canvasBox)) params ["", "", "_boxW", "_boxH"];

// ----- What it is -----

private _picH = UNIT * 2.2;
private _picW = SQUARE(_picH * 2);
// A placeholder word or a missing file in the class's config is no picture (aio_gui_fnc_safePicture).
private _picture = [_info getOrDefault ["picture", ""]] call EFUNC(gui,safePicture);

if (_picture isNotEqualTo "") then {
    [_display, _box, [_innerX, _cursorY, _picW, _picH], _picture] call EFUNC(gui,uiPicture);
};

// The picture the tile and the canvas show: the one set in the working copy while the game has the file, else
// config's.
private _workShown = "";

if (_workPicture isNotEqualTo "") then {
    _workShown = [_workPicture] call EFUNC(gui,safePicture);
};

if (_workShown isEqualTo "") then {
    _workShown = [_configPicture] call EFUNC(gui,safePicture);
};

private _textX = _innerX + _picW + SQUARE(UNIT * 0.4);
private _textW = _innerX + _innerW - _textX;
private _row = ((uiNamespace getVariable [QGVAR(index), createHashMap]) getOrDefault ["byClass", createHashMap]) getOrDefault [_lc, []];
private _family = _row param [ROW_FAMILY, ""];
private _about = format ["%1 · %2", _class, _row param [ROW_MOD, _info getOrDefault ["addon", ""]]];

if (_family isNotEqualTo "") then {
    _about = format ["%1 · %2 · %3", _class, localize format ["STR_aio_setup_Family_%1", _family], _row select ROW_MOD];
};

[
    _display, _box, [_textX, _cursorY, _textW, UNIT * 0.85],
    [_info getOrDefault ["name", _class], _textW, _fontBold, TEXT_HEAD] call EFUNC(gui,fitText), TEXT_HEAD, _colorText, _fontBold, 0
] call EFUNC(gui,uiLabel);

// Export and Import in the corner, beside the lines under the name.
private _toolsW = [_display, _box, [_innerX + _innerW, _cursorY + UNIT * 1.05, UNIT * 1], _theme, "items", _class, _tree] call FUNC(editorTools);
private _aboutW = _textW - _toolsW - SQUARE(UNIT * 0.3);

[
    _display, _box, [_textX, _cursorY + UNIT * 0.85, _aboutW, UNIT * 0.65],
    [_about, _aboutW, _font, TEXT_SMALL] call EFUNC(gui,fitText), TEXT_SMALL, _muted, _font, 0
] call EFUNC(gui,uiLabel);

[
    _display, _box, [_textX, _cursorY + UNIT * 1.45, _aboutW, UNIT * 0.65],
    format [LLSTRING(Items_Weight), ((_info getOrDefault ["mass", 0]) * MASS_TO_KG) toFixed 2], TEXT_SMALL, _colorText2, _font, 0
] call EFUNC(gui,uiLabel);

_cursorY = _cursorY + _picH + UNIT * 0.3;

// ----- For the tree: one rule for the class and everything built on it -----

// A kit of Enhanced First Aid Kits is always edited with the instances of it that are carried
// (fnc_editScope): no class alone to go back to.
private _kitTree = _tree && {(_info getOrDefault ["kind", ""]) isEqualTo "kit"};

if (_kitTree) then {
    _cursorY = _cursorY + ([
        _display, _box, [_innerX, _cursorY, _innerW], format [LLSTRING(Scope_KitNote), _info getOrDefault ["name", _class], _below, _class],
        TEXT_SMALL, _accent, _font
    ] call FUNC(uiText)) + UNIT * 0.3;
};

if (_tree && {!_kitTree}) then {
    private _chipText = LLSTRING(Scope_OnlyThis);
    private _chipH = UNIT * 0.95;
    private _chipW = SQUARE(_chipH * 0.9) + (_chipText getTextWidth [_fontBold, _chipH * 0.52]) * TEXT_SLACK;

    [_display, _box, [_innerX + _innerW - _chipW, _cursorY, _chipW, _chipH], _chipText, false, _theme, {
        // The edit goes back to the class alone; what was drawn stays.
        GVAR(editScope) set ["items", "class"];

        [] call FUNC(drawItemEditor);
    }] call FUNC(uiChip);

    _cursorY = _cursorY + (([
        _display, _box, [_innerX, _cursorY, _innerW - _chipW - SQUARE(UNIT * 0.4)], format [LLSTRING(Scope_TreeNote), _info getOrDefault ["name", _class], _below, _class],
        TEXT_SMALL, _accent, _font
    ] call FUNC(uiText)) max _chipH) + UNIT * 0.3;
};

// ----- What the draft makes of it now -----

{
    _x params ["_field", "_show"];

    if (_show) then {
        ([_info, _field, _own] call FUNC(answerText)) params ["_words", "_from"];

        private _isOwn = ((_src getOrDefault [["footprint", _field] select (_field isEqualTo "stack"), ""]) select [0, 4]) isEqualTo "own:";

        _cursorY = _cursorY + ([
            _display, _box, [_innerX, _cursorY, _innerW], format ["%1: %2", LLSTRING(Items_Now), format [LLSTRING(Answer_Line), _words, _from]],
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

// Back to the default: the cells of the class as the draft makes them without a size of its own. One piece or
// not - cells that do not touch are no size.
private _workShape = if (count _blocks == 1) then {(_blocks select 0) call EFUNC(items,formatMask)} else {""};

if (_workShape isNotEqualTo (_default getOrDefault ["shape", "1x1"])) then {
    [
        _display, _box, [_innerX + _innerW - _rowH, _cursorY, _rowH, _rowH], _theme, {
            params ["_class", "_tree"];

            [_class, "items", ["footprint"], _tree] call FUNC(resetField);
        }, [_class, _tree]
    ] call FUNC(uiReset);
};

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
    if (_chipX + _chipW > _innerX + _innerW - _rowH - _gap) exitWith {};

    [_display, _box, [_chipX, _cursorY + (_rowH - _chipH) / 2, _chipW, _chipH], str _x, !_forced && {_workStack == _x}, _theme, {
        params ["", "_arguments"];
        _arguments params ["_class", "_canvas", "_value"];

        _canvas set ["stack", _value];
        GVAR(itemWork) set [toLowerANSI _class, _canvas];

        [] call FUNC(drawItemEditor);
    }, [_class, _canvas, _x], !_forced] call FUNC(uiChip);

    _chipX = _chipX + _chipW + _gap;
} forEach [1, 5, 10, 20, 50, 100];

if (!_forced && {_workStack != (_default getOrDefault ["stack", 1])}) then {
    [
        _display, _box, [_innerX + _innerW - _rowH, _cursorY, _rowH, _rowH], _theme, {
            params ["_class", "_tree"];

            [_class, "items", ["stack"], _tree] call FUNC(resetField);
        }, [_class, _tree]
    ] call FUNC(uiReset);
};

_cursorY = _cursorY + _rowH + UNIT * 0.3;

// ----- Weight and name -----
// Typing goes into the working copy and nothing is drawn again, or the field would lose the cursor; Return
// draws this side again. Apply reads the working copy, so it has what was typed.

private _typed = {
    params ["_text", "_submitted", "_arguments"];
    _arguments params ["_class", "_canvas", "_field"];

    _canvas set [_field, _text];
    GVAR(itemWork) set [toLowerANSI _class, _canvas];

    if (_submitted) then {
        [] call FUNC(drawItemEditor);
    };
};

private _configKg = (_info getOrDefault ["configMass", 0]) * MASS_TO_KG;
private _fieldW = SQUARE(UNIT * 5);

[_display, _box, [_innerX, _cursorY, _labelW, _rowH], LLSTRING(Items_WeightField), TEXT_SMALL, _colorText2, _fontBold, 0] call EFUNC(gui,uiLabel);

[
    _display, _box, [_innerX + _labelW, _cursorY, _fieldW, _rowH], _workWeight, [_configKg] call FUNC(weightText), _theme, _typed, [_class, _canvas, "weightText"]
] call FUNC(uiEdit);

[_display, _box, [_innerX + _labelW + _fieldW + _gap, _cursorY, SQUARE(UNIT * 1.5), _rowH], LLSTRING(Items_WeightKg), TEXT_SMALL, _colorText2, _font, 0] call EFUNC(gui,uiLabel);

private _configX = _innerX + _labelW + _fieldW + SQUARE(UNIT * 1.5) + _gap * 2;

private _configW = _innerX + _innerW - _configX - _rowH - _gap;

[
    _display, _box, [_configX, _cursorY, _configW, _rowH],
    [format [LLSTRING(Items_WeightConfig), [_configKg] call FUNC(weightText)], _configW, _font, TEXT_SMALL] call EFUNC(gui,fitText),
    TEXT_SMALL, _muted, _font, 0
] call EFUNC(gui,uiLabel);

if (_workWeight isNotEqualTo _defaultWeightText) then {
    [
        _display, _box, [_innerX + _innerW - _rowH, _cursorY, _rowH, _rowH], _theme, {
            params ["_class", "_tree"];

            [_class, "items", ["weight"], _tree] call FUNC(resetField);
        }, [_class, _tree]
    ] call FUNC(uiReset);
};

_cursorY = _cursorY + _rowH + UNIT * 0.3;

[_display, _box, [_innerX, _cursorY, _labelW, _rowH], LLSTRING(Items_NameField), TEXT_SMALL, _colorText2, _fontBold, 0] call EFUNC(gui,uiLabel);

[
    _display, _box, [_innerX + _labelW, _cursorY, _innerW - _labelW - _rowH - _gap, _rowH], _workName, _info getOrDefault ["configDisplayName", _class], _theme, _typed, [_class, _canvas, "nameText"]
] call FUNC(uiEdit);

if (_workName isNotEqualTo (_default getOrDefault ["nameOverride", ""])) then {
    [
        _display, _box, [_innerX + _innerW - _rowH, _cursorY, _rowH, _rowH], _theme, {
            params ["_class", "_tree"];

            [_class, "items", ["name"], _tree] call FUNC(resetField);
        }, [_class, _tree]
    ] call FUNC(uiReset);
};

_cursorY = _cursorY + _rowH + UNIT * 0.3;

// The picture: its path, Pick... and Reset. What is taken goes into the working copy, and this side is drawn again.
[
    _display, _box, [_innerX, _cursorY, _innerW, _rowH], _theme, _labelW, _workPicture, _configPicture, {
        params ["_path", "_arguments"];
        _arguments params ["_class", "_canvas"];

        _canvas set ["pictureText", _path];
        GVAR(itemWork) set [toLowerANSI _class, _canvas];

        [] call FUNC(drawItemEditor);
    }, [_class, _canvas], _class
] call FUNC(drawPictureRow);

_cursorY = _cursorY + _rowH + UNIT * 0.3;

// ----- Use from -----
// The containers it may be used from where the settings close them: a chip each, and what they limit now.
if (_workUse isNotEqualTo (_default getOrDefault ["use", []])) then {
    [
        _display, _box, [_innerX + _innerW - _rowH, _cursorY, _rowH, _rowH], _theme, {
            params ["_class", "_tree"];

            [_class, "items", ["use"], _tree] call FUNC(resetField);
        }, [_class, _tree]
    ] call FUNC(uiReset);
};

_cursorY = _cursorY + ([
    _display, _box, [_innerX, _cursorY, _innerW], _theme, _labelW, _workUse, {
        params ["_list", "_arguments"];
        _arguments params ["_class", "_canvas"];

        _canvas set ["useList", _list];
        GVAR(itemWork) set [toLowerANSI _class, _canvas];

        [] call FUNC(drawItemEditor);
    }, [_class, _canvas]
] call FUNC(drawUseRow)) + UNIT * 0.3;

// ----- Category -----
// The categories it is in: a chip each, more than one on when it is in several. The reset button takes back the built-in one.
if (_workCats isNotEqualTo (_default getOrDefault ["groups", ["misc"]])) then {
    [
        _display, _box, [_innerX + _innerW - _rowH, _cursorY, _rowH, _rowH], _theme, {
            params ["_class", "_tree"];

            [_class, "items", ["cats"], _tree] call FUNC(resetField);
        }, [_class, _tree]
    ] call FUNC(uiReset);
};

// In several categories: which one's colour the tile takes, or a stripe of each (tint=).
private _tintW = [0, SQUARE(UNIT * 7)] select (count _workCats > 1);

if (_tintW > 0) then {
    private _tintOptions = [[LLSTRING(Tint_First), ""]] + (_workCats apply {[format [LLSTRING(Tint_Of), ([_x, GVAR(draftRules)] call EFUNC(items,categoryInfo)) get "name"], _x]}) + [[LLSTRING(Tint_Split), "split"]];

    [_display, _box, [_innerX + _innerW - _rowH - _tintW - _gap, _cursorY, _tintW, _rowH], _tintOptions, [_workTint, ""] select !(_workTint in (_workCats + ["split"])), _theme, {
        params ["_value", "_arguments"];
        _arguments params ["_class", "_canvas"];

        _canvas set ["tintPick", _value];
        GVAR(itemWork) set [toLowerANSI _class, _canvas];

        [] call FUNC(drawItemEditor);
    }, [_class, _canvas]] call FUNC(uiDropdown);
};

_cursorY = _cursorY + ([
    _display, _box, [_innerX, _cursorY, _innerW - _rowH - ([0, _tintW + _gap * 2] select (_tintW > 0))], _theme, _labelW, _workCats, {
        params ["_list", "_arguments"];
        _arguments params ["_class", "_canvas"];

        _canvas set ["catsList", _list];
        GVAR(itemWork) set [toLowerANSI _class, _canvas];

        [] call FUNC(drawItemEditor);
    }, [_class, _canvas]
] call FUNC(drawCatRow)) + UNIT * 0.3;

// ----- The canvas, and beside it how it looks -----

private _buttonH = UNIT * 1.15;
private _buttonsY = _height - CARD_PAD_Y - _buttonH;
private _cellH = ((_buttonsY - UNIT * 0.4 - _cursorY) / SHAPE_MAX) min (UNIT * 1.1);
private _cellW = SQUARE(_cellH);
private _canvasW = SHAPE_MAX * _cellW;
private _canvasH = SHAPE_MAX * _cellH;

[_display, _box, [_innerX, _cursorY, _canvasW, _canvasH], _canvas, _theme, createHashMapFromArray [
    ["cellH", _cellH],
    ["picture", _workShown],
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
private _previewW = _sideW * 0.36;

// The tile as the inventory draws it, with the picture as it is set below (the working copy, not yet the draft's).
[
    _display, _box, [_sideX, _sideY, _previewW, _previewH], _theme, [[], _blocks] select _onePiece,
    [_workShown, _info getOrDefault ["category", CATEGORY_MISC], _class, _workIcon apply {_x / 100}]
] call FUNC(drawPreview);

// ----- Its picture: zoom and shift -----
// Beside the tile it moves: how large the picture is drawn in its tile (25 to 400 %) and how far it is shifted
// across and down (a share of the tile, -100 to 100 %). Each click draws this side again, so the tile follows.

// Beside the piece of grid as it came out, not the room it was given: a small item's preview is narrower, and the
// steppers stood far off to the right of it.
private _pictureX = _sideX + ((uiNamespace getVariable [QGVAR(previewDrawnW), _previewW]) min _previewW) + _gap * 2;
private _pictureW = _sideX + _sideW - _pictureX;
private _pictureY = _sideY + (((_previewH - ICON_BLOCK_H) / 2) max 0);

private _iconH = [
    _display, _box, [_pictureX, _pictureY, _pictureW], _theme, _workIcon, {
        params ["_icon", "_arguments"];
        _arguments params ["_class", "_canvas"];

        _canvas set ["iconPercent", _icon];
        GVAR(itemWork) set [toLowerANSI _class, _canvas];

        [] call FUNC(drawItemEditor);
    }, [_class, _canvas]
] call FUNC(drawIconBlock);

// Below the tile or below the picture's steppers, whichever ends lower: on a narrow card the shift steppers
// go one under the other and the block grows past the tile.
_sideY = (_sideY + _previewH) max (_pictureY + _iconH);
_sideY = _sideY + UNIT * 0.3;

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

// ----- Discard, Back to the default; Apply at the right end -----

// Apply is as wide as the footer's Save and ends where the editor does, so it lies above Save.
private _applyW = (ACTION_W(LLSTRING(Items_Apply),_buttonH,true,_font)) max ([[LLSTRING(Save), LLSTRING(Apply)] select (GVAR(mode) isEqualTo "menu"), _font] call FUNC(footerButtonW));
private _applyX = _innerX + _innerW - _applyW;
private _buttonX = _innerX;

[_display, _box, [_applyX, _buttonsY, _applyW, _buttonH], LLSTRING(Items_Apply), UI_TEX(icon_check_ca), _theme, {
    params ["_class", "_canvas", "_startShape", "_startStack", "_forced", "_startWeight", "_startWeightText", "_startName", "_tree", "_below", "_startIcon", "_ownIcon", "_startPicture", "_ownPicture", "_startUse", "_startGroups", "_defaultGroups"];

    private _lc = toLowerANSI _class;
    private _blocks = [_canvas] call FUNC(canvasBlocks);

    if (count _blocks != 1) exitWith {
        [LLSTRING(Items_NotConnected), "loss"] call FUNC(setHint);
    };

    // The weight as typed: nothing is config's own, a number is kg; anything else is said and kept.
    private _weight = [_canvas getOrDefault ["weightText", _startWeightText]] call FUNC(weightValue);

    if (_weight < -1) exitWith {
        [LLSTRING(Hint_BadWeight), "loss"] call FUNC(setHint);
    };

    // Only what differs from now: a size by mass or a stack from the preset stays theirs when untouched.
    // A shape is written as drawn, its edges trimmed; a full box as WxH.
    private _set = createHashMap;
    private _remove = [];
    private _shape = (_blocks select 0) call EFUNC(items,formatMask);
    private _stack = _canvas getOrDefault ["stack", _startStack];

    if (_blocks isNotEqualTo (_canvas getOrDefault ["start", []]) && {_shape isNotEqualTo _startShape}) then {
        _set set ["footprint", _shape];
    };

    if (!_forced && {_stack != _startStack}) then {
        _set set ["stack", _stack];
    };

    // Emptied, a weight or a name that was set goes; typed, one that differs is set.
    if (_weight < 0) then {
        if (_startWeight >= 0) then {
            _remove pushBack "weight";
        };
    } else {
        if (_startWeight < 0 || {(round (_weight * 1000)) != round (_startWeight * 1000)}) then {
            _set set ["weight", _weight];
        };
    };

    private _name = trim (_canvas getOrDefault ["nameText", _startName]);

    if (count _name > EDIT_NAME_MAX) then {
        _name = _name select [0, EDIT_NAME_MAX];
    };

    if (_name isEqualTo "") then {
        if (_startName isNotEqualTo "") then {
            _remove pushBack "name";
        };
    } else {
        if (_name isNotEqualTo _startName) then {
            _set set ["name", _name];
        };
    };

    // The picture (icon=), in per cent: only what differs from now. Back to the plain one takes the class's own
    // icon away when nothing below it draws the picture otherwise (the item's own config, aio_icon); else the
    // plain picture is written, to win over that.
    private _icon = _canvas getOrDefault ["iconPercent", _startIcon];

    if (_icon isNotEqualTo _startIcon) then {
        private _modIcon = ((([_class] call EFUNC(items,getFacts)) get "mod") getOrDefault ["icon", ICON_PLAIN]) isNotEqualTo ICON_PLAIN;

        if (_icon isEqualTo ICON_PERCENT_PLAIN && {_ownIcon} && {!_modIcon}) then {
            _remove pushBack "icon";
        } else {
            _set set ["icon", _icon apply {_x / 100}];
        };
    };

    // The picture (picture=): only what differs from now. Reset takes the class's own away; where the item's config
    // sets another (aio_picture) that would win again, config's own picture path is written to win over it.
    private _picture = _canvas getOrDefault ["pictureText", _startPicture];

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

    // The containers it may be used from (use=): only what differs from now. None is written as use=none, which
    // takes back what a broader rule whitelisted; Back to the default takes the class's own rule away.
    private _use = _canvas getOrDefault ["useList", _startUse];

    if (_use isNotEqualTo _startUse) then {
        _set set ["use", _use];
    };

    // The categories (cats=): only what differs from now. What is the built-in one again takes the class's own away.
    private _cats = _canvas getOrDefault ["catsList", _startGroups];

    if (_cats isNotEqualTo _startGroups) then {
        switch (true) do {
            case (_cats isEqualTo _defaultGroups): {_remove pushBack "cats"};
            // None ticked: in no category at all (cats=none).
            case (_cats isEqualTo []): {_set set ["cats", ["none"]]};
            default {_set set ["cats", _cats]};
        };
    };

    // The colour among several categories (tint=).
    private _tint = _canvas getOrDefault ["tintPick", _canvas getOrDefault ["tintStart", ""]];

    if (_tint isNotEqualTo (_canvas getOrDefault ["tintStart", ""])) then {
        if (_tint isEqualTo "") then {_remove pushBack "tint"} else {_set set ["tint", _tint]};
    };

    GVAR(itemWork) deleteAt _lc;

    if (count _set == 0 && {_remove isEqualTo []}) exitWith {
        [LLSTRING(Hint_NothingToApply), "text2"] call FUNC(setHint);
        [] call FUNC(drawItemEditor);
    };

    [
        [format [LLSTRING(Hint_SizeApplied), _class], format [LLSTRING(Hint_TreeApplied), _class, _below]] select _tree, "text2"
    ] call FUNC(setHint);
    [_class, _set, _remove, _tree] call FUNC(upsertRule);
}, [_class, _canvas, _startShape, _startStack, _forced, _startWeight, _startWeightText, _startName, _tree, _below, _startIcon, _ownIcon, _startPicture, _ownPicture, _startUse, _startGroups, _default getOrDefault ["groups", ["misc"]]], _onePiece && {_dirty}, "accent", [LLSTRING(Items_ApplyTip), LLSTRING(Items_ApplyTipTree)] select _tree] call FUNC(uiAction);

if (_dirty) then {
    private _buttonW = ACTION_W(LLSTRING(Cont_Discard),_buttonH,false,_font);

    [_display, _box, [_buttonX, _buttonsY, _buttonW, _buttonH], LLSTRING(Cont_Discard), "", _theme, {
        params ["_class"];

        GVAR(itemWork) deleteAt (toLowerANSI _class);

        [] call FUNC(drawItemEditor);
    }, [_class], true, "ghost"] call FUNC(uiAction);

    _buttonX = _buttonX + _buttonW + _gap;
};

// Something of its own to take away: its own rule, or - for the tree - the tree's.
private _ownFields = ["footprint", "stack", "weight", "name", "icon", "picture", "use", "cats", "tint"];
private _hasOwn = (_ownFields findIf {_x in _own}) >= 0;

if (_tree) then {
    _hasOwn = _hasOwn || {(_ownFields findIf {_x in (_treeRules getOrDefault [_lc, createHashMap])}) >= 0};
};

if (_hasOwn) then {
    private _resetText = LLSTRING(Groups_Reset);
    private _buttonW = ACTION_W(_resetText,_buttonH,true,_font);

    // On a narrow screen only its icon, which the tooltip explains, so it never reaches under Apply.
    if (_buttonX + _buttonW > _applyX - _gap) then {
        _resetText = "";
        _buttonW = ACTION_W(_resetText,_buttonH,true,_font);
    };

    [_display, _box, [_buttonX, _buttonsY, _buttonW, _buttonH], _resetText, UI_TEX(icon_reset_ca), _theme, {
        params ["_class", "_ownFields", "_tree", "_below"];

        GVAR(itemWork) deleteAt (toLowerANSI _class);

        [[format [LLSTRING(Hint_Reset), _class], format [LLSTRING(Hint_TreeReset), _class, _below]] select _tree, "text2"] call FUNC(setHint);
        [_class, createHashMap, _ownFields, _tree] call FUNC(upsertRule);
    }, [_class, _ownFields, _tree, _below], true, "ghost", LLSTRING(Items_ResetTip)] call FUNC(uiAction);
};
